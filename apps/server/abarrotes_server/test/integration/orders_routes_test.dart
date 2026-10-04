// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/orders/orders_routes.dart';
import 'package:abarrotes_server/src/orders/orders_service.dart';
import 'package:serverpod/serverpod.dart' hide Order;
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Un catálogo mínimo y un cliente para crear pedidos de prueba.
class _Shop {
  _Shop(this.session);

  final Session session;
  late User customer;
  late User staff;
  late Product arroz;
  late Product aceite;

  Future<void> setUp() async {
    staff = await insertUser(session, 'uid-staff', UserRole.staff);
    customer = await insertUser(session, 'uid-cliente', UserRole.customer);
    final category = await Category.db.insertRow(
      session,
      Category(name: 'Abarrotes'),
    );
    Future<Product> product(String name, int stock) => Product.db.insertRow(
      session,
      Product(
        name: name,
        sku: name.toUpperCase(),
        priceCents: 450,
        categoryId: category.id!,
        currentStock: stock,
      ),
    );
    arroz = await product('Arroz', 8);
    aceite = await product('Aceite', 3);
  }

  /// Un pedido de 2 arroces y 1 aceite (el stock ya se descontó al crearlo).
  Future<Order> order({
    OrderStatus status = OrderStatus.pendingConfirmation,
    DateTime? createdAt,
  }) async {
    final order = await Order.db.insertRow(
      session,
      Order(
        status: status,
        totalCents: 2 * 390 + 1250,
        deliveryAddress: 'Av. Arequipa 123',
        customerId: customer.id!,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
    await OrderItem.db.insert(session, [
      OrderItem(
        orderId: order.id!,
        productId: arroz.id!,
        quantity: 2,
        unitPriceCents: 390,
      ),
      OrderItem(
        orderId: order.id!,
        productId: aceite.id!,
        quantity: 1,
        unitPriceCents: 1250,
      ),
    ]);
    return order;
  }

  Future<int> stockOf(Product product) async =>
      (await Product.db.findById(session, product.id!))!.currentStock;
}

void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  withServerpod('Rutas de pedidos', (sessionBuilder, _) {
    late Session session;
    late TestClient client;
    late _Shop shop;

    setUp(() async {
      session = sessionBuilder.build();
      final server = await serveRoutes(
        () => session,
        ordersRoutes(OrdersService(now: () => testNow), testVerifier(google)),
      );
      client = TestClient(server, google);
      addTearDown(server.close);
      shop = _Shop(session);
      await shop.setUp();
    });

    Future<ApiResult> changeStatus(Order order, String status) => client.patch(
      '/orders/${order.id}/status',
      {'status': status},
      as: 'uid-staff',
    );

    group('PATCH /orders/:id/status', () {
      test('avanza según el estado actual y actualiza updatedAt', () async {
        final order = await shop.order(createdAt: DateTime.utc(2026, 9, 30));

        final (status, body) = await changeStatus(order, 'confirmed');

        expect(status, 200);
        expect(body['status'], 'confirmed');
        expect(body['updatedAt'], testNow.toIso8601String());
        expect(body['createdAt'], '2026-09-30T00:00:00.000Z');
      });

      test('recorre el flujo completo hasta entregado', () async {
        final order = await shop.order();

        for (final next in ['confirmed', 'outForDelivery', 'delivered']) {
          expect((await changeStatus(order, next)).$1, 200, reason: next);
        }
      });

      test(
        'una transición no permitida es 400 con el motivo y no guarda',
        () async {
          final delivered = await shop.order(status: OrderStatus.delivered);
          final confirmed = await shop.order(status: OrderStatus.confirmed);

          final back = await changeStatus(delivered, 'confirmed');
          final skip = await changeStatus(confirmed, 'delivered');

          expect(back.$1, 400);
          expect(
            back.$2['message'],
            'Un pedido entregado ya no puede cambiar de estado',
          );
          expect(
            skip.$2['message'],
            'Un pedido confirmado no puede pasar a entregado: '
            'solo puede pasar a en camino o cancelado',
          );
          expect(
            (await Order.db.findById(session, confirmed.id!))!.status,
            OrderStatus.confirmed,
          );
        },
      );

      test(
        'cancelar devuelve el stock con una entrada de inventario por línea',
        () async {
          final order = await shop.order(status: OrderStatus.outForDelivery);

          final (status, body) = await changeStatus(order, 'cancelled');

          expect((status, body['status']), (200, 'cancelled'));
          expect(await shop.stockOf(shop.arroz), 10);
          expect(await shop.stockOf(shop.aceite), 4);
          final movements = await InventoryMovement.db.find(
            session,
            orderBy: (m) => m.quantity,
          );
          expect(
            [for (final m in movements) (m.type, m.quantity)],
            [
              (MovementType.incoming, 1),
              (MovementType.incoming, 2),
            ],
          );
          expect(movements.first.reason, 'Cancelación del pedido ${order.id}');
          expect(movements.first.userId, shop.staff.id);
        },
      );

      test(
        'un pedido ya cancelado no se cancela otra vez ni devuelve más stock',
        () async {
          final order = await shop.order();
          await changeStatus(order, 'cancelled');

          final (status, body) = await changeStatus(order, 'cancelled');

          expect(
            (status, body['message']),
            (400, 'El pedido ya está cancelado'),
          );
          expect(await shop.stockOf(shop.arroz), 10);
        },
      );

      test('valida el estado, el id y que el pedido exista', () async {
        final order = await shop.order();

        expect((await changeStatus(order, 'shipped')).$2['message'], [
          'status debe ser pendingConfirmation, confirmed, outForDelivery, '
              'delivered o cancelled',
        ]);
        expect(
          (await client.patch('/orders/123/status', {
            'status': 'confirmed',
          }, as: 'uid-staff')).$1,
          400,
        );
        expect(
          (await client.patch(
            '/orders/0199a000-0000-7000-8000-000000000000/status',
            {'status': 'confirmed'},
            as: 'uid-staff',
          )).$1,
          404,
        );
      });
    });

    group('GET /orders', () {
      test(
        'paginado, los más recientes primero, con líneas y cliente',
        () async {
          await shop.order(createdAt: DateTime.utc(2026, 9, 28, 15));
          final latest = await shop.order(
            createdAt: DateTime.utc(2026, 9, 29, 15),
          );

          final (status, body) = await client.get(
            '/orders?limit=1',
            as: 'uid-staff',
          );

          expect(status, 200);
          expect(body['meta'], {
            'total': 2,
            'page': 1,
            'limit': 1,
            'totalPages': 2,
          });
          final order = body['data'].single;
          expect(order['id'], latest.id.toString());
          expect(order['status'], 'pendingConfirmation');
          expect(order['total'], '20.3');
          expect(order['customer'], {
            'id': shop.customer.id.toString(),
            'name': 'Usuario uid-cliente',
            'email': 'uid-cliente@tienda.pe',
            'phone': null,
          });
          expect(order['items'], hasLength(2));
          // Las líneas van por id (UUID v7), que no sigue el orden de
          // inserción dentro del mismo milisegundo: se busca por producto.
          final arroz = (order['items'] as List).singleWhere(
            (item) => item['productId'] == shop.arroz.id.toString(),
          );
          expect(arroz, {
            'id': isA<String>(),
            'quantity': 2,
            'unitPrice': '3.9',
            'orderId': latest.id.toString(),
            'productId': shop.arroz.id.toString(),
            'product': {
              'id': shop.arroz.id.toString(),
              'name': 'Arroz',
              'imageUrl': null,
            },
          });
        },
      );

      test('filtra por estado', () async {
        await shop.order();
        await shop.order(status: OrderStatus.delivered);

        final (_, body) = await client.get(
          '/orders?status=delivered',
          as: 'uid-staff',
        );

        expect([for (final o in body['data']) o['status']], ['delivered']);
      });

      test('from y to son días de Lima, ambos incluidos', () async {
        // 04:59 UTC del 1 de octubre todavía es el 30 de septiembre en Lima.
        await shop.order(createdAt: DateTime.utc(2026, 10, 1, 4, 59));
        await shop.order(createdAt: DateTime.utc(2026, 10, 1, 5));
        await shop.order(createdAt: DateTime.utc(2026, 10, 3, 4, 59));
        await shop.order(createdAt: DateTime.utc(2026, 10, 3, 5));

        Future<int> count(String query) async => (await client.get(
          '/orders?$query',
          as: 'uid-staff',
        )).$2['meta']['total'];

        expect(await count('from=2026-10-01&to=2026-10-02'), 2);
        expect(await count('from=2026-10-01'), 3);
        expect(await count('to=2026-09-30'), 1);
      });

      test(
        'valida el query: from posterior a to, días y estados inválidos',
        () async {
          final reversed = await client.get(
            '/orders?from=2026-10-05&to=2026-10-01',
            as: 'uid-staff',
          );
          final invalid = await client.get(
            '/orders?from=2026-02-30&status=otro',
            as: 'uid-staff',
          );

          expect(reversed.$2['message'], 'from no puede ser posterior a to');
          expect(invalid.$1, 400);
          expect(invalid.$2['message'], hasLength(2));
        },
      );
    });

    test('todo /orders es solo para admin y staff', () async {
      final order = await shop.order();

      expect((await client.get('/orders')).$1, 401);
      expect((await client.get('/orders', as: 'uid-cliente')).$1, 403);
      expect(
        (await client.patch('/orders/${order.id}/status', {
          'status': 'cancelled',
        }, as: 'uid-cliente')).$1,
        403,
      );
      expect(await shop.stockOf(shop.arroz), 8);
    });
  });

  // Sin rollback: cada sesión usa su propia conexión, como dos peticiones
  // reales. La base temporal del grupo se borra al terminar.
  withServerpod(
    'Cambios de estado simultáneos',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, _) {
      test(
        'dos cancelaciones a la vez devuelven el stock una sola vez',
        () async {
          final shop = _Shop(sessionBuilder.build());
          await shop.setUp();
          final order = await shop.order();

          Future<Object> cancel() => OrdersService()
              .changeStatus(
                sessionBuilder.build(),
                order.id!,
                OrderStatus.cancelled,
                by: shop.staff,
              )
              .then<Object>(
                (order) => order.status.name,
                onError: (Object e) => e is ApiException ? e.message : e,
              );

          final results = await Future.wait([cancel(), cancel()]);

          expect(
            results,
            unorderedEquals(['cancelled', 'El pedido ya está cancelado']),
          );
          expect(await shop.stockOf(shop.arroz), 10);
          expect(await InventoryMovement.db.count(shop.session), 2);
        },
      );
    },
  );
}
