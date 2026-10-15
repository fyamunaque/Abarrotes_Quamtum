// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:abarrotes_server/src/common/shopper.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/orders/orders_routes.dart';
import 'package:abarrotes_server/src/orders/orders_service.dart';
import 'package:serverpod/serverpod.dart' hide Order;
import 'package:test/test.dart';

import '../support/fake_push.dart';
import '../support/http_harness.dart';
import '../support/staff_setup.dart';
import '../support/promotions_setup.dart';
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
    staff = await insertStaff(session, 'uid-staff');
    customer = await insertUser(session, 'uid-cliente');
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
  /// A domicilio, o de recojo con [pickupCode].
  Future<Order> order({
    OrderStatus status = OrderStatus.pendingConfirmation,
    DateTime? createdAt,
    String? pickupCode,
  }) async {
    final order = await Order.db.insertRow(
      session,
      Order(
        status: status,
        fulfillmentType: pickupCode == null
            ? FulfillmentType.delivery
            : FulfillmentType.pickup,
        totalCents: 2 * 390 + 1250,
        deliveryAddress: pickupCode == null ? 'Av. Arequipa 123' : null,
        pickupCode: pickupCode,
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
        ordersRoutes(
          OrdersService(pricing: testPromotions(), now: () => testNow),
          testGuards(google),
          shoppers: testShoppers,
        ),
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
              'delivered, cancelled, preparing o readyForPickup',
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
          expect(order['fulfillmentType'], 'delivery');
          expect(order['allowedNextStatuses'], ['confirmed', 'cancelled']);
          expect(order['pickupCode'], isNull);
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

    group('POST /orders', () {
      Map<String, Object?> body(List<(Product, int)> lines) => {
        'deliveryAddress': '  Av. Arequipa 123, Lince  ',
        'items': [
          for (final (product, quantity) in lines)
            {'productId': product.id.toString(), 'quantity': quantity},
        ],
      };

      Future<ApiResult> place(Object body, {String? as = 'uid-cliente'}) =>
          client.post('/orders', body, as: as);

      Future<List<InventoryMovement>> movements() =>
          InventoryMovement.db.find(session, orderBy: (m) => m.productId);

      test('crea el pedido a nombre de quien lo pide, cobra la promoción y '
          'descuenta el stock', () async {
        await Promotion.db.insertRow(
          session,
          Promotion(
            productId: shop.arroz.id!,
            promoPriceCents: 390,
            startDate: testNow.subtract(const Duration(days: 1)),
            endDate: testNow.add(const Duration(days: 1)),
          ),
        );

        final (status, order) = await place(
          body([(shop.arroz, 2), (shop.aceite, 1)]),
        );

        expect(status, 201);
        expect(order['status'], 'pendingConfirmation');
        expect(order['customerId'], shop.customer.id.toString());
        expect(order['deliveryAddress'], 'Av. Arequipa 123, Lince');
        expect(order['total'], '12.3'); // 2 × 3.90 + 4.50
        expect(order['priceChanges'], isEmpty);
        expect(order, isNot(contains('customer')));
        expect(
          [
            for (final item in order['items'] as List)
              (item['product']['name'], item['quantity'], item['unitPrice']),
          ],
          unorderedEquals([('Arroz', 2, '3.9'), ('Aceite', 1, '4.5')]),
        );

        expect(await shop.stockOf(shop.arroz), 6);
        expect(await shop.stockOf(shop.aceite), 2);
        expect(
          [
            for (final m in await movements())
              (m.type, m.quantity, m.userId, m.reason),
          ],
          unorderedEquals([
            for (final quantity in [2, 1])
              (
                MovementType.outgoing,
                quantity,
                shop.customer.id,
                'Pedido ${order['id']}',
              ),
          ]),
        );
      });

      group('según el cliente', () {
        setUp(() async {
          // Arroz: 3.90 para todos y 3.50 para VIPs.
          for (final (cents, audience) in [
            (390, PromotionAudience.everyone),
            (350, PromotionAudience.vip),
          ]) {
            await Promotion.db.insertRow(
              session,
              Promotion(
                productId: shop.arroz.id!,
                promoPriceCents: cents,
                startDate: testNow.subtract(const Duration(days: 1)),
                endDate: testNow.add(const Duration(days: 1)),
                audience: audience,
              ),
            );
          }
          await insertUser(session, 'uid-vip');
          await insertVips(session, shop.staff, ['vip@tienda.pe']);
        });

        Future<String> arrozPriceFor(
          String uid, {
          String? email,
          bool emailVerified = true,
        }) async {
          final (status, order) = await client.post(
            '/orders',
            body([(shop.arroz, 1)]),
            as: uid,
            email: email,
            emailVerified: emailVerified,
          );
          expect(status, 201);
          return order['items'][0]['unitPrice'] as String;
        }

        test('un VIP paga el precio VIP y los demás el de todos', () async {
          expect(await arrozPriceFor('uid-vip', email: 'vip@tienda.pe'), '3.5');
          expect(await arrozPriceFor('uid-cliente'), '3.9');
          expect(
            await arrozPriceFor(
              'uid-vip',
              email: 'vip@tienda.pe',
              emailVerified: false,
            ),
            '3.9',
          );
        });

        test(
          'el unitPrice del carrito nunca se cobra: si difiere, va en '
          'priceChanges',
          () async {
            final (status, order) = await place({
              'deliveryAddress': 'Av. Arequipa 123',
              'items': [
                // El carrito mostraba el precio VIP, pero no lo es.
                {
                  'productId': shop.arroz.id.toString(),
                  'quantity': 2,
                  'unitPrice': 3.5,
                },
                {
                  'productId': shop.aceite.id.toString(),
                  'quantity': 1,
                  'unitPrice': '4.50',
                },
              ],
            });

            expect(status, 400);
            expect(order['message'], [
              'items[1].unitPrice debe ser un número con 2 decimales como '
                  'máximo',
            ]);

            final (created, placed) = await place({
              'deliveryAddress': 'Av. Arequipa 123',
              'items': [
                {
                  'productId': shop.arroz.id.toString(),
                  'quantity': 2,
                  'unitPrice': 3.5,
                },
                {
                  'productId': shop.aceite.id.toString(),
                  'quantity': 1,
                  'unitPrice': 4.5,
                },
              ],
            });

            expect(created, 201);
            expect(placed['total'], '12.3'); // 2 × 3.90 + 4.50
            expect(placed['priceChanges'], [
              {
                'productId': shop.arroz.id.toString(),
                'name': 'Arroz',
                'shownUnitPrice': '3.5',
                'unitPrice': '3.9',
              },
            ]);
          },
        );
      });

      test('junta las líneas del mismo producto', () async {
        final (status, order) = await place(
          body([(shop.arroz, 1), (shop.arroz, 2)]),
        );

        expect(status, 201);
        expect(order['items'], hasLength(1));
        expect(order['items'][0]['quantity'], 3);
        expect(order['total'], '13.5');
        expect(await shop.stockOf(shop.arroz), 5);
        expect(await movements(), hasLength(1));
      });

      test(
        'un producto dado de baja o que no existe: 400 y no cambia nada',
        () async {
          await Product.db.updateRow(
            session,
            shop.aceite.copyWith(active: false),
          );
          final missing = '0190a1b2-0000-7000-8000-000000000000';

          final (status, error) = await place({
            'deliveryAddress': 'Av. Arequipa 123',
            'items': [
              {'productId': shop.arroz.id.toString(), 'quantity': 1},
              {'productId': shop.aceite.id.toString(), 'quantity': 1},
              {'productId': missing, 'quantity': 1},
            ],
          });

          expect(status, 400);
          expect(error['message'], contains('Ya no están disponibles:'));
          expect(error['message'], contains('Aceite'));
          expect(error['message'], contains(missing));
          expect(error['message'], isNot(contains('Arroz')));
          expect(await Order.db.count(session), 0);
          expect(await shop.stockOf(shop.arroz), 8);
        },
      );

      test('si el stock no alcanza: 409 y no queda nada del pedido', () async {
        final (status, error) = await place(
          body([(shop.arroz, 2), (shop.aceite, 4)]),
        );

        expect(status, 409);
        expect(error['message'], 'Stock insuficiente: Aceite tiene 3 unidades');
        expect(await Order.db.count(session), 0);
        expect(await OrderItem.db.count(session), 0);
        expect(await movements(), isEmpty);
        expect(await shop.stockOf(shop.arroz), 8);
        expect(await shop.stockOf(shop.aceite), 3);
      });

      test(
        'valida el body: los precios y el total los pone el servidor',
        () async {
          Future<List<String>> errors(Object body) async {
            final (status, error) = await place(body);
            expect(status, 400, reason: '$body');
            return (error['message'] as List).cast<String>();
          }

          final arroz = shop.arroz.id.toString();
          expect(await errors({'items': []}), [
            'deliveryAddress es obligatorio a domicilio',
            'items debe tener entre 1 y 100 elementos',
          ]);
          expect(
            await errors({
              'deliveryAddress': 'Av. Arequipa 123',
              'total': '0.1',
              'items': [
                {'productId': arroz, 'quantity': 0},
                {'productId': 'no-es-uuid', 'quantity': 1000},
                {'productId': arroz, 'quantity': 1, 'price': 0.1},
              ],
            }),
            [
              'La propiedad total no está permitida',
              'La propiedad items[2].price no está permitida',
              'items[0].quantity debe estar entre 1 y 999',
              'items[1].productId debe ser un UUID',
              'items[1].quantity debe estar entre 1 y 999',
            ],
          );
          expect(await Order.db.count(session), 0);
        },
      );

      test('sin token, 401', () async {
        expect((await place(body([(shop.arroz, 1)]), as: null)).$1, 401);
      });
    });

    group('GET /orders/mine', () {
      test(
        'solo los pedidos propios, los más recientes primero y paginados',
        () async {
          final older = await shop.order(createdAt: testNow);
          final newer = await shop.order(
            createdAt: testNow.add(const Duration(hours: 1)),
          );
          await Order.db.insertRow(
            session,
            Order(
              totalCents: 450,
              deliveryAddress: 'Otra dirección',
              customerId: shop.staff.id!,
            ),
          );

          final (status, page) = await client.get(
            '/orders/mine?limit=1',
            as: 'uid-cliente',
          );
          expect(status, 200);
          expect(page['meta']['total'], 2);
          expect(
            [for (final o in page['data']) o['id']],
            [newer.id.toString()],
          );
          expect(page['data'][0], isNot(contains('customer')));
          expect(page['data'][0]['items'], hasLength(2));

          final (_, second) = await client.get(
            '/orders/mine?limit=1&page=2',
            as: 'uid-cliente',
          );
          expect(
            [for (final o in second['data']) o['id']],
            [older.id.toString()],
          );
        },
      );

      test('sin token, 401; con query desconocido, 400', () async {
        expect((await client.get('/orders/mine')).$1, 401);
        expect(
          (await client.get('/orders/mine?estado=x', as: 'uid-cliente')).$1,
          400,
        );
      });
    });

    group('aviso al cliente', () {
      Future<TestClient> serve(OrdersService service) async {
        final server = await serveRoutes(
          () => session,
          ordersRoutes(service, testGuards(google), shoppers: testShoppers),
        );
        addTearDown(server.close);
        return TestClient(server, google);
      }

      test('cada cambio de estado avisa, con el pedido ya cambiado', () async {
        final notifier = RecordingOrderNotifier();
        final client = await serve(
          OrdersService(
            pricing: testPromotions(),
            notifier: notifier,
            now: () => testNow,
          ),
        );
        final order = await shop.order(pickupCode: 'K7M2XQ');

        for (final next in ['confirmed', 'preparing']) {
          await client.patch('/orders/${order.id}/status', {
            'status': next,
          }, as: 'uid-staff');
        }
        // Un cambio rechazado no avisa.
        await client.patch('/orders/${order.id}/status', {
          'status': 'outForDelivery',
        }, as: 'uid-staff');

        expect(
          [for (final o in notifier.changed) (o.id, o.status, o.pickupCode)],
          [
            (order.id, OrderStatus.confirmed, 'K7M2XQ'),
            (order.id, OrderStatus.preparing, 'K7M2XQ'),
          ],
        );
      });

      test('si el aviso falla, el cambio de estado queda igual', () async {
        final client = await serve(
          OrdersService(
            pricing: testPromotions(),
            notifier: ThrowingOrderNotifier(),
            now: () => testNow,
          ),
        );
        final order = await shop.order();

        final (status, body) = await client.patch(
          '/orders/${order.id}/status',
          {'status': 'confirmed'},
          as: 'uid-staff',
        );

        expect((status, body['status']), (200, 'confirmed'));
        expect(
          (await Order.db.findById(session, order.id!))!.status,
          OrderStatus.confirmed,
        );
      });
    });

    group('recojo en tienda', () {
      final codePattern = RegExp(r'^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{6}$');
      List<Object?> items() => [
        {'productId': shop.arroz.id.toString(), 'quantity': 1},
      ];

      test('se crea sin dirección y con su código', () async {
        final (status, order) = await client.post('/orders', {
          'fulfillmentType': 'pickup',
          'items': items(),
        }, as: 'uid-cliente');

        expect(status, 201);
        expect(order['fulfillmentType'], 'pickup');
        expect(order['deliveryAddress'], isNull);
        expect(order['pickupCode'], matches(codePattern));
        expect(order['readyForPickupAt'], isNull);
        expect(order['allowedNextStatuses'], ['confirmed', 'cancelled']);
        final saved = (await Order.db.find(session)).single;
        expect(saved.pickupCode, order['pickupCode']);
        expect(saved.deliveryAddress, isNull);
      });

      test('sin tipo, a domicilio; la dirección según el tipo', () async {
        final (status, order) = await client.post('/orders', {
          'deliveryAddress': 'Av. Arequipa 123',
          'items': items(),
        }, as: 'uid-cliente');
        expect(status, 201);
        expect(order['fulfillmentType'], 'delivery');
        expect(order['pickupCode'], isNull);

        Future<Object?> error(Map<String, Object?> body) async {
          final (status, error) = await client.post('/orders', {
            ...body,
            'items': items(),
          }, as: 'uid-cliente');
          expect(status, 400, reason: '$body');
          return error['message'];
        }

        expect(await error({'fulfillmentType': 'delivery'}), [
          'deliveryAddress es obligatorio a domicilio',
        ]);
        expect(
          await error({
            'fulfillmentType': 'pickup',
            'deliveryAddress': 'Av. Arequipa 123',
          }),
          ['deliveryAddress no va en un pedido de recojo en tienda'],
        );
        expect(
          await error({
            'fulfillmentType': 'dron',
            'deliveryAddress': 'Av. Arequipa 123',
          }),
          ['fulfillmentType debe ser delivery o pickup'],
        );
        expect(await Order.db.count(session), 1);
      });

      test('si el código sale repetido, se genera otro', () async {
        final codes = ['K7M2XQ', 'K7M2XQ', 'P4R9TW'];
        final service = OrdersService(
          pricing: testPromotions(),
          pickupCode: () => codes.removeAt(0),
          now: () => testNow,
        );
        Future<String?> place() async => (await service.create(
          session,
          customer: shop.customer,
          shopper: Shopper.anonymous,
          fulfillmentType: FulfillmentType.pickup,
          lines: [
            (productId: shop.arroz.id!, quantity: 1, shownUnitPriceCents: null),
          ],
        )).order.pickupCode;

        expect(await place(), 'K7M2XQ');
        expect(await place(), 'P4R9TW');
      });

      test(
        'recorre su flujo hasta recogido, con el código del cliente',
        () async {
          final order = await shop.order(pickupCode: 'K7M2XQ');

          for (final next in ['confirmed', 'preparing']) {
            expect((await changeStatus(order, next)).$1, 200, reason: next);
          }
          final (status, ready) = await changeStatus(order, 'readyForPickup');
          expect(status, 200);
          expect(ready['readyForPickupAt'], testNow.toIso8601String());
          expect(ready['allowedNextStatuses'], ['delivered', 'cancelled']);

          Future<ApiResult> pickUp(String? code) => client.patch(
            '/orders/${order.id}/status',
            {'status': 'delivered', 'pickupCode': ?code},
            as: 'uid-staff',
          );
          expect(
            (await pickUp(null)).$2['message'],
            'Falta el código de recojo: pídeselo al cliente',
          );
          final wrong = await pickUp('K7M2XA');
          expect(
            (wrong.$1, wrong.$2['message']),
            (400, 'El código de recojo no coincide'),
          );
          expect(
            (await Order.db.findById(session, order.id!))!.status,
            OrderStatus.readyForPickup,
          );

          final (picked, done) = await pickUp(' k7m2xq ');
          expect(picked, 200);
          expect(done['status'], 'delivered');
          expect(done['allowedNextStatuses'], isEmpty);
        },
      );

      test('cada tipo, solo sus estados: 400 con el motivo', () async {
        final pickup = await shop.order(
          status: OrderStatus.confirmed,
          pickupCode: 'K7M2XQ',
        );
        final delivery = await shop.order(status: OrderStatus.confirmed);

        final toTheStreet = await changeStatus(pickup, 'outForDelivery');
        final toTheCounter = await changeStatus(delivery, 'preparing');
        final waiting = await changeStatus(delivery, 'readyForPickup');

        expect(toTheStreet.$1, 400);
        expect(
          toTheStreet.$2['message'],
          'Un pedido de recojo en tienda no puede pasar a en camino: '
          'no sale a reparto',
        );
        expect(
          toTheCounter.$2['message'],
          'Un pedido a domicilio no puede pasar a preparando: '
          'eso es solo para recojo en tienda',
        );
        expect(waiting.$1, 400);
      });

      test(
        'se cancela antes de recogerlo, sin código, y devuelve el stock',
        () async {
          final order = await shop.order(
            status: OrderStatus.readyForPickup,
            pickupCode: 'K7M2XQ',
          );

          final (status, body) = await changeStatus(order, 'cancelled');

          expect((status, body['status']), (200, 'cancelled'));
          expect(await shop.stockOf(shop.arroz), 10);
        },
      );

      test(
        'el código: para el dueño y para el personal con orders.view',
        () async {
          await shop.order(pickupCode: 'K7M2XQ');
          final order = await shop.order(pickupCode: 'P4R9TW');
          await insertStaff(
            session,
            'uid-solo-estado',
            permissions: {Permission.ordersUpdateStatus},
          );

          final (_, mine) = await client.get('/orders/mine', as: 'uid-cliente');
          expect(
            [for (final o in mine['data']) o['pickupCode']],
            unorderedEquals(['K7M2XQ', 'P4R9TW']),
          );
          final (_, panel) = await client.get('/orders', as: 'uid-staff');
          expect(
            [for (final o in panel['data']) o['pickupCode']],
            unorderedEquals(['K7M2XQ', 'P4R9TW']),
          );
          // Cambia el estado, pero no ve los pedidos: no recibe el código.
          final (status, changed) = await client.patch(
            '/orders/${order.id}/status',
            {'status': 'confirmed'},
            as: 'uid-solo-estado',
          );
          expect(status, 200);
          expect(changed['pickupCode'], isNull);
          expect(changed['fulfillmentType'], 'pickup');
        },
      );

      test('el panel filtra por tipo de entrega', () async {
        await shop.order();
        await shop.order(pickupCode: 'K7M2XQ');

        Future<List<Object?>> types(String query) async => [
          for (final o
              in (await client.get(
                    '/orders?$query',
                    as: 'uid-staff',
                  )).$2['data']
                  as List)
            o['fulfillmentType'],
        ];

        expect(await types('fulfillmentType=pickup'), ['pickup']);
        expect(await types('fulfillmentType=delivery'), ['delivery']);
        expect(
          (await client.get('/orders?fulfillmentType=x', as: 'uid-staff')).$1,
          400,
        );
      });
    });

    test(
      'el listado y los cambios de estado son solo para admin y staff',
      () async {
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
      },
    );
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

          Future<Object> cancel() => OrdersService(pricing: testPromotions())
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

  withServerpod(
    'Pedidos simultáneos',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, _) {
      test(
        'dos pedidos a la vez por las últimas unidades: uno solo pasa',
        () async {
          final shop = _Shop(sessionBuilder.build());
          await shop.setUp();

          Future<Object> place() => OrdersService(pricing: testPromotions())
              .create(
                sessionBuilder.build(),
                customer: shop.customer,
                shopper: Shopper.anonymous,
                fulfillmentType: FulfillmentType.delivery,
                deliveryAddress: 'Av. Arequipa 123',
                lines: [
                  (
                    productId: shop.aceite.id!,
                    quantity: 2,
                    shownUnitPriceCents: null,
                  ),
                ],
              )
              .then<Object>(
                (placed) => placed.order.status.name,
                onError: (Object e) => e is ApiException ? e.message : e,
              );

          final results = await Future.wait([place(), place()]);

          expect(
            results,
            unorderedEquals([
              'pendingConfirmation',
              'Stock insuficiente: Aceite tiene 1 unidad',
            ]),
          );
          expect(await shop.stockOf(shop.aceite), 1);
          expect(await Order.db.count(shop.session), 1);
          expect(await InventoryMovement.db.count(shop.session), 1);
        },
      );
    },
  );
}
