import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neils/admin/inventory/inventory_repository.dart';
import 'package:neils/admin/inventory/movement.dart';
import 'package:neils/admin/orders/admin_orders_repository.dart';
import 'package:neils/admin/products/admin_products_repository.dart';
import 'package:neils/admin/products/product_input.dart';
import 'package:neils/admin/promotions/promotion.dart';
import 'package:neils/admin/promotions/promotions_repository.dart';
import 'package:neils/admin/stats/stats_repository.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/orders/order_status.dart';

/// Los repositorios del panel contra el JSON que manda el servidor (los
/// `*Json` de apps/server), con un cliente HTTP simulado.
void main() {
  http.Response json(int status, Object? body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );

  /// Lo que se mandó en cada petición.
  late List<http.Request> sent;

  AuthedApi api(Object? Function(http.Request) respond, {int status = 200}) {
    sent = [];
    return AuthedApi(
      ApiClient(
        MockClient((request) async {
          sent.add(request);
          return json(status, respond(request));
        }),
        baseUrl: Uri.parse('http://api.pe'),
      ),
      () async => 'token-staff',
    );
  }

  Map<String, Object?> page(List<Object?> data, {int total = 1}) => {
    'data': data,
    'meta': {'total': total, 'page': 1, 'limit': 20},
  };

  group('estadísticas', () {
    const summary = {
      'from': '2026-10-01',
      'to': '2026-10-04',
      'total': '120.5',
      'orders': 4,
      'averageTicket': '30.13',
    };

    test('el resumen, con los pedidos por estado', () async {
      final overview = await HttpStatsRepository(
        api(
          (_) => {
            'today': {
              ...summary,
              'total': '0',
              'orders': 0,
              'averageTicket': '0',
            },
            'week': summary,
            'month': summary,
            'ordersByStatus': {'pendingConfirmation': 2, 'delivered': 7},
          },
        ),
      ).overview();

      expect(sent.single.url.path, '/stats/overview');
      expect(sent.single.headers['authorization'], 'Bearer token-staff');
      expect(overview.today.totalCents, 0);
      expect(overview.week.totalCents, 12050);
      expect(overview.month.averageTicketCents, 3013);
      expect(overview.ordersByStatus[OrderStatus.pendingConfirmation], 2);
      expect(overview.ordersByStatus[OrderStatus.delivered], 7);
      expect(overview.ordersByStatus[OrderStatus.cancelled], 0);
    });

    test('ventas por día, top, stock bajo y por vencer', () async {
      final repository = HttpStatsRepository(
        api(
          (request) => switch (request.url.path) {
            '/stats/sales' => {
              ...summary,
              'daily': [
                {'date': '2026-10-03', 'total': '0', 'orders': 0},
                {'date': '2026-10-04', 'total': '45.5', 'orders': 2},
              ],
            },
            '/stats/top-products' => {
              'data': [
                {
                  'productId': 'p-1',
                  'name': 'Arroz',
                  'sku': 'ARR',
                  'quantity': 12,
                  'revenue': '298.8',
                },
              ],
            },
            '/stats/low-stock' => {
              'data': [
                {
                  'id': 'p-2',
                  'name': 'Azúcar',
                  'sku': 'AZU',
                  'category': 'Abarrotes',
                  'currentStock': 0,
                  'minStock': 5,
                  'shortage': 5,
                },
              ],
            },
            _ => {
              'days': 7,
              'until': '2026-10-11',
              'data': [
                {
                  'id': 'p-3',
                  'name': 'Yogurt',
                  'sku': 'YOG',
                  'currentStock': 15,
                  'expirationDate': '2026-10-07',
                  'daysLeft': 3,
                },
              ],
            },
          },
        ),
      );

      final sales = await repository.sales30Days();
      expect(
        [for (final d in sales.daily) (d.date, d.totalCents, d.orders)],
        [('2026-10-03', 0, 0), ('2026-10-04', 4550, 2)],
      );
      expect(sales.summary.orders, 4);

      final top = await repository.topProducts();
      expect(sent.last.url.queryParameters, {'limit': '5'});
      expect(
        (top.single.name, top.single.quantity, top.single.revenueCents),
        ('Arroz', 12, 29880),
      );

      final low = await repository.lowStock();
      expect((low.single.name, low.single.shortage), ('Azúcar', 5));

      final expiring = await repository.expiring();
      expect(sent.last.url.queryParameters, {'days': '7'});
      expect(
        (expiring.single.expirationDate, expiring.single.daysLeft),
        ('2026-10-07', 3),
      );
    });
  });

  group('pedidos', () {
    const order = {
      'id': 'o-1',
      'status': 'confirmed',
      'total': '24.9',
      'deliveryAddress': 'Av. Arequipa 123',
      'createdAt': '2026-10-04T15:30:00.000Z',
      'updatedAt': '2026-10-04T15:30:00.000Z',
      'customerId': 'u-1',
      'items': [
        {
          'id': 'i-1',
          'quantity': 1,
          'unitPrice': '24.9',
          'orderId': 'o-1',
          'productId': 'p-1',
          'product': {'id': 'p-1', 'name': 'Arroz', 'imageUrl': null},
        },
      ],
      'customer': {
        'id': 'u-1',
        'name': 'Ana Quispe',
        'email': 'ana@tienda.pe',
        'phone': '987654321',
      },
    };

    test('lista filtrada por estado, con el cliente', () async {
      final orders = await HttpAdminOrdersRepository(
        api((_) => page([order], total: 21)),
      ).list(page: 2, status: OrderStatus.confirmed);

      expect(sent.single.url.path, '/orders');
      expect(sent.single.url.queryParameters, {
        'page': '2',
        'limit': '20',
        'status': 'confirmed',
      });
      expect(orders.total, 21);
      final first = orders.items.single;
      expect(first.order.status, OrderStatus.confirmed);
      expect(first.customerName, 'Ana Quispe');
      expect(first.customerPhone, '987654321');
    });

    test('cambiar el estado: PATCH con el estado nuevo', () async {
      final updated = await HttpAdminOrdersRepository(
        api((_) => {...order, 'status': 'outForDelivery'}),
      ).changeStatus('o-1', OrderStatus.outForDelivery);

      expect(sent.single.method, 'PATCH');
      expect(sent.single.url.path, '/orders/o-1/status');
      expect(jsonDecode(sent.single.body), {'status': 'outForDelivery'});
      expect(updated.order.status, OrderStatus.outForDelivery);
    });
  });

  group('productos', () {
    const product = {
      'id': 'p-1',
      'name': 'Yogurt de fresa 1 L',
      'description': null,
      'sku': 'YOG-1L',
      'price': '7.5',
      'imageUrl': null,
      'active': false,
      'currentStock': 15,
      'minStock': 5,
      'expirationDate': '2026-10-07T00:00:00.000Z',
      'createdAt': '2026-10-01T00:00:00.000Z',
      'categoryId': 'c-1',
      'category': {'id': 'c-1', 'name': 'Lácteos'},
      'promotion': null,
    };

    test('lista con los inactivos, la búsqueda y la categoría', () async {
      final products = await HttpAdminProductsRepository(
        api((_) => page([product])),
      ).list(search: ' yog ', categoryId: 'c-1');

      expect(sent.single.url.queryParameters, {
        'page': '1',
        'limit': '20',
        'includeInactive': 'true',
        'search': 'yog',
        'categoryId': 'c-1',
      });
      final yogurt = products.items.single;
      expect(yogurt.sku, 'YOG-1L');
      expect(yogurt.active, isFalse);
      expect(yogurt.minStock, 5);
      expect(yogurt.expirationDate, DateTime.utc(2026, 10, 7));
    });

    test('crear manda el stock inicial; editar, no', () async {
      final repository = HttpAdminProductsRepository(api((_) => product));
      final input = ProductInput(
        name: 'Yogurt de fresa 1 L',
        sku: 'YOG-1L',
        priceCents: 750,
        categoryId: 'c-1',
        minStock: 5,
        active: true,
        expirationDate: DateTime(2026, 10, 7),
        initialStock: 15,
      );

      await repository.create(input);
      expect(sent.single.method, 'POST');
      expect(jsonDecode(sent.single.body), {
        'name': 'Yogurt de fresa 1 L',
        'sku': 'YOG-1L',
        'price': 7.5,
        'categoryId': 'c-1',
        'minStock': 5,
        'active': true,
        'description': null,
        'imageUrl': null,
        'expirationDate': '2026-10-07T00:00:00.000Z',
        'currentStock': 15,
      });

      await repository.update('p-1', input);
      expect(sent.last.method, 'PATCH');
      expect(sent.last.url.path, '/products/p-1');
      expect(jsonDecode(sent.last.body), isNot(contains('currentStock')));
    });

    test('dar de baja: DELETE', () async {
      await HttpAdminProductsRepository(api((_) => product)).deactivate('p-1');

      expect(sent.single.method, 'DELETE');
      expect(sent.single.url.path, '/products/p-1');
    });

    test('un SKU repetido: el 409 llega con el mensaje del servidor', () {
      expect(
        HttpAdminProductsRepository(
          api(
            (_) => {'message': 'Ya existe un producto con ese SKU'},
            status: 409,
          ),
        ).create(
          const ProductInput(
            name: 'x',
            sku: 'x',
            priceCents: 1,
            categoryId: 'c',
            minStock: 0,
            active: true,
          ),
        ),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.message,
            'message',
            'Ya existe un producto con ese SKU',
          ),
        ),
      );
    });
  });

  group('inventario', () {
    const movement = {
      'id': 'm-1',
      'type': 'outgoing',
      'quantity': 2,
      'reason': 'Pedido o-1',
      'createdAt': '2026-10-04T15:30:00.000Z',
      'product': {'id': 'p-1', 'name': 'Arroz', 'sku': 'ARR'},
      'user': {'id': 'u-1', 'name': 'Ana Quispe'},
    };

    test('el historial y el cambio con signo', () async {
      final movements = await HttpInventoryRepository(
        api((_) => page([movement])),
      ).movements(page: 3);

      expect(sent.single.url.queryParameters, {'page': '3', 'limit': '20'});
      final first = movements.items.single;
      expect(first.type, MovementType.outgoing);
      expect(first.change, -2);
      expect(first.userName, 'Ana Quispe');
    });

    test('registrar: un ajuste con signo y motivo', () async {
      await HttpInventoryRepository(
        api((_) => {...movement, 'type': 'adjustment', 'quantity': -3}),
      ).record(
        const MovementInput(
          productId: 'p-1',
          type: MovementType.adjustment,
          quantity: -3,
          reason: ' Merma ',
        ),
      );

      expect(sent.single.method, 'POST');
      expect(jsonDecode(sent.single.body), {
        'productId': 'p-1',
        'type': 'adjustment',
        'quantity': -3,
        'reason': 'Merma',
      });
    });
  });

  group('promociones', () {
    const promotion = {
      'id': 'pr-1',
      'productId': 'p-1',
      'product': {'id': 'p-1', 'name': 'Aceite', 'sku': 'ACE', 'price': '10.9'},
      'promoPrice': '8.9',
      'startDate': '2026-10-04',
      'endDate': '2026-11-02',
      'active': true,
      'status': 'active',
    };

    test('lista filtrada por estado y el descuento', () async {
      final promotions = await HttpPromotionsRepository(
        api((_) => page([promotion])),
      ).list(status: PromotionStatus.active);

      expect(sent.single.url.queryParameters, {
        'page': '1',
        'limit': '20',
        'status': 'active',
      });
      final oil = promotions.items.single;
      expect((oil.priceCents, oil.promoPriceCents), (1090, 890));
      expect(oil.discountPercent, 18);
      expect(oil.status, PromotionStatus.active);
    });

    test('crear lleva el producto; editar, no; eliminar es DELETE', () async {
      final repository = HttpPromotionsRepository(api((_) => promotion));

      await repository.create(
        const PromotionInput(
          productId: 'p-1',
          promoPriceCents: 890,
          startDate: '2026-10-04',
          endDate: '2026-11-02',
          active: true,
        ),
      );
      expect(jsonDecode(sent.single.body), {
        'productId': 'p-1',
        'promoPrice': 8.9,
        'startDate': '2026-10-04',
        'endDate': '2026-11-02',
        'active': true,
      });

      await repository.update(
        'pr-1',
        const PromotionInput(
          promoPriceCents: 790,
          startDate: '2026-10-04',
          endDate: '2026-11-02',
          active: false,
        ),
      );
      expect(sent.last.method, 'PATCH');
      expect(jsonDecode(sent.last.body), isNot(contains('productId')));

      await repository.delete('pr-1');
      expect(sent.last.method, 'DELETE');
      expect(sent.last.url.path, '/promotions/pr-1');
    });
  });

  test('las transiciones de estado son las del servidor', () {
    expect(OrderStatus.pendingConfirmation.nextStatuses, [
      OrderStatus.confirmed,
      OrderStatus.cancelled,
    ]);
    expect(OrderStatus.confirmed.nextStatuses, [
      OrderStatus.outForDelivery,
      OrderStatus.cancelled,
    ]);
    expect(OrderStatus.outForDelivery.nextStatuses, [
      OrderStatus.delivered,
      OrderStatus.cancelled,
    ]);
    expect(OrderStatus.delivered.nextStatuses, isEmpty);
    expect(OrderStatus.cancelled.nextStatuses, isEmpty);
  });
}
