import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neils/admin/categories/admin_categories_repository.dart';
import 'package:neils/admin/inventory/inventory_repository.dart';
import 'package:neils/admin/inventory/movement.dart';
import 'package:neils/admin/orders/admin_orders_repository.dart';
import 'package:neils/admin/products/admin_products_repository.dart';
import 'package:neils/admin/products/product_input.dart';
import 'package:neils/admin/promo_codes/promo_code.dart';
import 'package:neils/admin/promo_codes/promo_codes_repository.dart';
import 'package:neils/admin/promotions/promotion.dart';
import 'package:neils/admin/promotions/promotions_repository.dart';
import 'package:neils/admin/staff/staff.dart';
import 'package:neils/admin/staff/staff_repository.dart';
import 'package:neils/admin/stats/stats_repository.dart';
import 'package:neils/admin/vip/vip_repository.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/orders/order_status.dart';
import 'package:neils/session/staff_permission.dart';

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
      'number': 1024,
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
      expect(first.order.number, 1024);
      expect(first.customer!.name, 'Ana Quispe');
      expect(first.customer!.phone, '987654321');
    });

    test('buscar por número', () async {
      await HttpAdminOrdersRepository(api((_) => page([order])))
          .list(number: 1024);

      expect(sent.single.url.queryParameters, {
        'page': '1',
        'limit': '20',
        'number': '1024',
      });
    });

    test('sin customers.view, el pedido llega sin el cliente', () async {
      final orders = await HttpAdminOrdersRepository(
        api(
          (_) => page([
            {...order, 'customer': null},
          ]),
        ),
      ).list();

      final first = orders.items.single;
      expect(first.customer, isNull);
      expect(first.order.lines, hasLength(1));
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

    test('recoger en caja manda el código', () async {
      await HttpAdminOrdersRepository(
        api((_) => {...order, 'status': 'delivered'}),
      ).changeStatus('o-1', OrderStatus.delivered, pickupCode: 'K7M2XQ');

      expect(jsonDecode(sent.single.body), {
        'status': 'delivered',
        'pickupCode': 'K7M2XQ',
      });
    });

    test('entregar a domicilio manda el código o el motivo', () async {
      final repository = HttpAdminOrdersRepository(
        api((_) => {...order, 'status': 'delivered'}),
      );

      await repository.changeStatus(
        'o-1',
        OrderStatus.delivered,
        deliveryCode: 'P4R9TW',
      );
      await repository.changeStatus(
        'o-1',
        OrderStatus.delivered,
        withoutCodeReason: 'No tenía el celular',
      );

      expect(
        [for (final request in sent) jsonDecode(request.body)],
        [
          {'status': 'delivered', 'deliveryCode': 'P4R9TW'},
          {'status': 'delivered', 'withoutCodeReason': 'No tenía el celular'},
        ],
      );
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

    test('subir la foto: PUT con los bytes, su tipo y el token', () async {
      final saved = await HttpAdminProductsRepository(
        api(
          (_) => {
            ...product,
            'imageUrl': '/images/products/p-1/0123456789abcdef.jpg',
          },
        ),
      ).uploadImage('p-1', [1, 2, 3], contentType: 'image/png');

      final request = sent.single;
      expect(request.method, 'PUT');
      expect(request.url.toString(), 'http://api.pe/products/p-1/image');
      expect(request.headers['content-type'], 'image/png');
      expect(request.headers['authorization'], 'Bearer token-staff');
      expect(request.bodyBytes, [1, 2, 3]);
      expect(saved.imageUrl, '/images/products/p-1/0123456789abcdef.jpg');
    });

    test('una foto rechazada: el mensaje del servidor', () {
      expect(
        HttpAdminProductsRepository(
          api(
            (_) => {
              'message': 'La foto tiene que ser una imagen JPEG, PNG o WebP',
            },
            status: 400,
          ),
        ).uploadImage('p-1', [1], contentType: 'image/jpeg'),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.message,
            'message',
            'La foto tiene que ser una imagen JPEG, PNG o WebP',
          ),
        ),
      );
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
      // Uno de antes del vínculo con el pedido: el motivo tal cual.
      expect(first.orderNumber, isNull);
      expect(first.reasonLabel, 'Pedido o-1');
    });

    test('los filtros van en la query; el pedido, con su número', () async {
      final movements =
          await HttpInventoryRepository(
            api(
              (_) => page([
                {
                  ...movement,
                  'order': {'id': 'o-1', 'number': 1024},
                },
                {
                  ...movement,
                  'type': 'incoming',
                  'order': {'id': 'o-1', 'number': 1024},
                },
                {...movement, 'reason': 'Conteo', 'order': null},
              ]),
            ),
          ).movements(
            search: 'arroz',
            origin: MovementOrigin.orders,
            categoryId: 'c-1',
            from: DateTime(2026, 9, 28),
            to: DateTime(2026, 10, 4),
          );

      expect(sent.single.url.queryParameters, {
        'page': '1',
        'limit': '20',
        'search': 'arroz',
        'origin': 'orders',
        'categoryId': 'c-1',
        'from': '2026-09-28',
        'to': '2026-10-04',
      });
      expect(
        [for (final m in movements.items) m.reasonLabel],
        ['Pedido N.º 1024', 'Cancelación del pedido N.º 1024', 'Conteo'],
      );
      expect(movements.items.first.orderId, 'o-1');
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
      // Sin audience (un servidor anterior), es para todos.
      expect(oil.audience, PromotionAudience.everyone);
      expect(oil.title, isNull);
    });

    test('la audiencia y el título', () async {
      final promotions = await HttpPromotionsRepository(
        api(
          (_) => page([
            {...promotion, 'audience': 'vip', 'title': 'Semana VIP'},
          ]),
        ),
      ).list();

      final vip = promotions.items.single;
      expect(vip.vipOnly, isTrue);
      expect(vip.title, 'Semana VIP');
      await expectLater(
        HttpPromotionsRepository(
          api(
            (_) => page([
              {...promotion, 'audience': 'mayoristas'},
            ]),
          ),
        ).list(),
        throwsA(isA<ApiFailure>()),
      );
    });

    test(
      'clientes elegidos: llegan con su correo y se mandan sus ids',
      () async {
        final repository = HttpPromotionsRepository(
          api(
            (_) => page([
              {
                ...promotion,
                'audience': 'selected',
                'recipients': [
                  {'id': 'v-1', 'email': 'ana@tienda.pe'},
                ],
              },
            ]),
          ),
        );

        final chosen = (await repository.list()).items.single;
        expect(chosen.audience, PromotionAudience.selected);
        expect(chosen.vipOnly, isTrue);
        expect(chosen.recipients, [(id: 'v-1', email: 'ana@tienda.pe')]);

        PromotionInput input(PromotionAudience audience) => PromotionInput(
          promoPriceCents: 790,
          startDate: '2026-10-04',
          endDate: '2026-11-02',
          active: true,
          audience: audience,
          recipients: const [(id: 'v-1', email: 'ana@tienda.pe')],
        );
        expect(input(PromotionAudience.selected).toJson()['recipientIds'], [
          'v-1',
        ]);
        // Con otra audiencia no van: el servidor los quita.
        expect(
          input(PromotionAudience.vip).toJson(),
          isNot(contains('recipientIds')),
        );
      },
    );

    test('lee el tipo y sus campos', () async {
      final promotions = await HttpPromotionsRepository(
        api(
          (_) => page([
            {
              ...promotion,
              'type': 'gift',
              'promoPrice': null,
              'buyQuantity': 2,
              'giftProduct': {'id': 'p-9', 'name': 'Sal 1 kg'},
              'giftQuantity': 1,
            },
          ]),
        ),
      ).list();

      final gift = promotions.items.single;
      expect(gift.type, PromotionType.gift);
      expect((gift.giftProductId, gift.giftProductName), ('p-9', 'Sal 1 kg'));
      expect(gift.label, 'Regalo: Sal 1 kg');
      expect(gift.promoPriceCents, isNull);
    });

    test('cada tipo manda solo sus campos; el tipo, solo al crear', () async {
      final repository = HttpPromotionsRepository(api((_) => promotion));

      await repository.create(
        const PromotionInput(
          productId: 'p-1',
          type: PromotionType.buyXPayY,
          buyQuantity: 2,
          payQuantity: 1,
          startDate: '2026-10-04',
          endDate: '2026-11-02',
          active: true,
        ),
      );
      expect(jsonDecode(sent.single.body), {
        'productId': 'p-1',
        'type': 'buyXPayY',
        'buyQuantity': 2,
        'payQuantity': 1,
        'startDate': '2026-10-04',
        'endDate': '2026-11-02',
        'active': true,
        'audience': 'everyone',
        'title': null,
      });

      await repository.update(
        'pr-1',
        const PromotionInput(
          type: PromotionType.gift,
          buyQuantity: 2,
          giftProductId: 'p-9',
          giftQuantity: 1,
          startDate: '2026-10-04',
          endDate: '2026-11-02',
          active: true,
        ),
        confirmOverlap: true,
      );
      final patch = jsonDecode(sent.last.body) as Map;
      expect(patch, isNot(contains('type')));
      expect(patch, isNot(contains('promoPrice')));
      expect(patch, containsPair('giftProductId', 'p-9'));
      expect(patch, containsPair('confirmOverlap', true));
    });

    test('el cruce llega como PromotionOverlap', () async {
      final repository = HttpPromotionsRepository(
        api(
          (_) => {
            'statusCode': 409,
            'message': 'Se acumula con otras promociones del producto',
            'overlaps': [
              {
                'id': 'pr-2',
                'type': 'buyXPayY',
                'audience': 'everyone',
                'label': '2x1',
                'startDate': '2026-10-01',
                'endDate': '2026-10-07',
              },
            ],
          },
          status: 409,
        ),
      );

      await expectLater(
        repository.create(
          const PromotionInput(
            productId: 'p-1',
            promoPriceCents: 890,
            startDate: '2026-10-04',
            endDate: '2026-11-02',
            active: true,
          ),
        ),
        throwsA(
          isA<PromotionOverlap>().having((o) => o.overlaps.single, 'overlap', (
            label: '2x1',
            audience: PromotionAudience.everyone,
            startDate: '2026-10-01',
            endDate: '2026-10-07',
          )),
        ),
      );
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
        'type': 'specialPrice',
        'promoPrice': 8.9,
        'startDate': '2026-10-04',
        'endDate': '2026-11-02',
        'active': true,
        'audience': 'everyone',
        'title': null,
      });

      await repository.update(
        'pr-1',
        const PromotionInput(
          promoPriceCents: 790,
          startDate: '2026-10-04',
          endDate: '2026-11-02',
          active: false,
          audience: PromotionAudience.vip,
          title: 'Semana VIP',
        ),
      );
      expect(sent.last.method, 'PATCH');
      expect(jsonDecode(sent.last.body), isNot(contains('productId')));
      expect(jsonDecode(sent.last.body), containsPair('audience', 'vip'));
      expect(jsonDecode(sent.last.body), containsPair('title', 'Semana VIP'));

      await repository.delete('pr-1');
      expect(sent.last.method, 'DELETE');
      expect(sent.last.url.path, '/promotions/pr-1');
    });
  });

  group('códigos promocionales', () {
    const code = {
      'id': 'c-1',
      'code': 'VERANO-10',
      'active': true,
      'status': 'active',
      'startDate': '2026-11-01',
      'endDate': '2026-11-30',
      'benefitDays': 7,
      'maxRedemptions': 100,
      'usesPerCustomer': 2,
      'minPurchase': '30',
      'newCustomersOnly': false,
      'eligibility': 'listed',
      'allowedEmails': ['ana@tienda.pe'],
      'promotions': [
        {
          'id': 'pr-1',
          'productId': 'p-1',
          'product': {
            'id': 'p-1',
            'name': 'Arroz',
            'sku': 'ARR',
            'price': '4.5',
          },
          'type': 'buyXPayY',
          'label': '2x1',
          'promoPrice': null,
          'buyQuantity': 2,
          'payQuantity': 1,
          'startDate': '2026-11-01',
          'endDate': '2026-11-30',
          'active': true,
          'status': 'active',
          'audience': 'code',
          'promoCode': {'id': 'c-1', 'code': 'VERANO-10'},
          'title': null,
          'recipients': <Object?>[],
        },
      ],
      'redemptions': 47,
      'orders': 12,
    };

    test('lee el código con sus límites, condiciones y promociones', () async {
      final codes = await HttpPromoCodesRepository(api((_) => page([code])))
          .list(status: PromoCodeStatus.active, search: ' veran ');

      expect(sent.single.url.path, '/promo-codes');
      expect(sent.single.url.queryParameters, {
        'page': '1',
        'limit': '20',
        'status': 'active',
        'search': 'veran',
      });
      final verano = codes.items.single;
      expect(
        (verano.code, verano.status, verano.active),
        ('VERANO-10', PromoCodeStatus.active, true),
      );
      expect(
        (
          verano.benefitDays,
          verano.maxRedemptions,
          verano.usesPerCustomer,
          verano.minPurchaseCents,
        ),
        (7, 100, 2, 3000),
      );
      expect(verano.eligibility, PromoCodeEligibility.listed);
      expect(verano.allowedEmails, ['ana@tienda.pe']);
      expect((verano.redemptions, verano.orders), (47, 12));
      final promotion = verano.promotions.single;
      expect(promotion.audience, PromotionAudience.code);
      expect(
        (promotion.promoCodeId, promotion.promoCode),
        ('c-1', 'VERANO-10'),
      );
      expect(promotion.vipOnly, isFalse);
    });

    test('crear, editar y borrar', () async {
      final repository = HttpPromoCodesRepository(api((_) => code));
      const input = PromoCodeInput(
        code: 'VERANO-10',
        startDate: '2026-11-01',
        endDate: '2026-11-30',
        active: false,
        maxRedemptions: 100,
        minPurchaseCents: 3000,
        eligibility: PromoCodeEligibility.listed,
        allowedEmails: ['ana@tienda.pe'],
      );

      await repository.create(input);
      expect(sent.single.method, 'POST');
      expect(jsonDecode(sent.single.body), {
        'code': 'VERANO-10',
        'startDate': '2026-11-01',
        'endDate': '2026-11-30',
        'active': false,
        // Un límite vacío va en null: sin límite (y al editar, lo quita).
        'benefitDays': null,
        'maxRedemptions': 100,
        'usesPerCustomer': null,
        'minPurchase': 30.0,
        'newCustomersOnly': false,
        'eligibility': 'listed',
        'allowedEmails': ['ana@tienda.pe'],
      });

      await repository.update('c-1', input);
      expect(
        (sent.last.method, sent.last.url.path),
        ('PATCH', '/promo-codes/c-1'),
      );

      final deleting = HttpPromoCodesRepository(api((_) => null));
      await deleting.delete('c-1');
      expect(
        (sent.single.method, sent.single.url.path),
        ('DELETE', '/promo-codes/c-1'),
      );
    });

    test('una promoción de código manda su código', () async {
      final repository = HttpPromotionsRepository(
        api(
          (_) => {
            ...(code['promotions'] as List).single as Map<String, Object?>,
          },
        ),
      );

      await repository.create(
        const PromotionInput(
          productId: 'p-1',
          type: PromotionType.buyXPayY,
          buyQuantity: 2,
          payQuantity: 1,
          startDate: '2026-11-01',
          endDate: '2026-11-30',
          active: true,
          audience: PromotionAudience.code,
          promoCodeId: 'c-1',
        ),
      );

      final body = jsonDecode(sent.single.body) as Map;
      expect(body, containsPair('audience', 'code'));
      expect(body, containsPair('promoCodeId', 'c-1'));
    });
  });

  group('clientes VIP', () {
    const vip = {
      'id': 'v-1',
      'email': 'ana@gmail.com',
      'active': true,
      'createdAt': '2026-10-09T15:30:00.000Z',
      'hasAccount': true,
      'addedBy': {'id': 'u-1', 'name': 'Frank', 'email': 'frank@tienda.pe'},
    };

    test('lista con búsqueda: el estado, la fecha y quién lo agregó', () async {
      final repository = HttpVipRepository(api((_) => page([vip])));

      final list = await repository.list(page: 2, search: '  gmail ');
      expect(sent.single.url.path, '/vip-customers');
      expect(sent.single.url.queryParameters, {
        'page': '2',
        'limit': '20',
        'search': 'gmail',
      });
      expect(sent.single.headers['authorization'], 'Bearer token-staff');
      final ana = list.items.single;
      expect(ana.email, 'ana@gmail.com');
      expect(ana.hasAccount, isTrue);
      expect(ana.createdAt, DateTime.utc(2026, 10, 9, 15, 30));
      expect(ana.addedByName, 'Frank');

      await repository.list();
      expect(sent.last.url.queryParameters, isNot(contains('search')));
    });

    test('agregar manda los correos y lee el resumen', () async {
      final summary = await HttpVipRepository(
        api(
          (_) => {
            'added': ['luis@gmail.com'],
            'duplicates': ['ana@gmail.com'],
            'invalid': ['no-es-correo'],
          },
        ),
      ).add(['luis@gmail.com', 'ana@gmail.com', 'no-es-correo']);

      expect(sent.single.method, 'POST');
      expect(jsonDecode(sent.single.body), {
        'emails': ['luis@gmail.com', 'ana@gmail.com', 'no-es-correo'],
      });
      expect(summary.added, ['luis@gmail.com']);
      expect(summary.duplicates, ['ana@gmail.com']);
      expect(summary.invalid, ['no-es-correo']);
    });

    test('quitar es DELETE y devuelve el VIP dado de baja', () async {
      final removed = await HttpVipRepository(
        api((_) => {...vip, 'active': false, 'addedBy': null}),
      ).remove('v-1');

      expect(sent.single.method, 'DELETE');
      expect(sent.single.url.path, '/vip-customers/v-1');
      expect(removed.active, isFalse);
      expect(removed.addedByName, isNull);
    });

    test('un 403 (staff) llega con el mensaje del servidor', () async {
      await expectLater(
        HttpVipRepository(
          api(
            (_) => {
              'statusCode': 403,
              'message': 'Tu rol no tiene permiso para esta acción',
            },
            status: 403,
          ),
        ).add(['luis@gmail.com']),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.message,
            'message',
            'Tu rol no tiene permiso para esta acción',
          ),
        ),
      );
    });
  });

  group('equipo y roles', () {
    const member = {
      'id': 'm-1',
      'email': 'ana@gmail.com',
      'active': true,
      'createdAt': '2026-10-09T15:30:00.000Z',
      'hasAccount': false,
      'role': {'id': 'r-cajera', 'name': 'Cajera'},
      'addedBy': {'id': 'u-1', 'name': 'Frank', 'email': 'frank@tienda.pe'},
    };
    const cajera = {
      'id': 'r-cajera',
      'name': 'Cajera',
      'permissions': ['products.view', 'orders.view', 'otro.nuevo'],
      'isSystem': false,
      'active': true,
      'members': 2,
      'createdAt': '2026-10-01T10:00:00.000Z',
    };

    test('el equipo con los desactivados, su rol y su estado', () async {
      final repository = HttpStaffRepository(
        api(
          (_) => page([
            member,
            {...member, 'id': 'm-2', 'hasAccount': true},
            {...member, 'id': 'm-3', 'active': false, 'role': null},
          ], total: 3),
        ),
      );

      final list = await repository.members(page: 2, search: ' gmail ');
      expect(sent.single.url.path, '/staff/members');
      expect(sent.single.url.queryParameters, {
        'page': '2',
        'limit': '20',
        'includeInactive': 'true',
        'search': 'gmail',
      });
      final [ana, active, off] = list.items;
      expect(ana.email, 'ana@gmail.com');
      expect((ana.roleId, ana.roleName), ('r-cajera', 'Cajera'));
      expect(ana.addedByName, 'Frank');
      expect(ana.status, StaffMemberStatus.pendingSignUp);
      expect(active.status, StaffMemberStatus.active);
      expect(off.status, StaffMemberStatus.deactivated);
      expect(off.roleName, isNull);
    });

    test('agregar, cambiar el rol y desactivar', () async {
      final summary = await HttpStaffRepository(
        api(
          (_) => {
            'added': ['luis@gmail.com'],
            'duplicates': [],
            'invalid': ['no-es-correo'],
          },
        ),
      ).addMembers(['luis@gmail.com', 'no-es-correo'], 'r-cajera');
      expect(sent.single.method, 'POST');
      expect(sent.single.url.path, '/staff/members');
      expect(jsonDecode(sent.single.body), {
        'emails': ['luis@gmail.com', 'no-es-correo'],
        'roleId': 'r-cajera',
      });
      expect(summary.added, ['luis@gmail.com']);
      expect(summary.invalid, ['no-es-correo']);

      final changed = await HttpStaffRepository(
        api(
          (_) => {
            ...member,
            'role': {'id': 'r-2', 'name': 'Almacenero'},
          },
        ),
      ).changeRole('m-1', 'r-2');
      expect(sent.single.method, 'PATCH');
      expect(sent.single.url.path, '/staff/members/m-1');
      expect(jsonDecode(sent.single.body), {'roleId': 'r-2'});
      expect(changed.roleName, 'Almacenero');

      final off = await HttpStaffRepository(
        api((_) => {...member, 'active': false}),
      ).deactivate('m-1');
      expect(sent.single.method, 'DELETE');
      expect(sent.single.url.path, '/staff/members/m-1');
      expect(off.status, StaffMemberStatus.deactivated);
    });

    test('los roles: los permisos que la app conoce', () async {
      final roles = await HttpStaffRepository(
        api(
          (_) => {
            'data': [
              {
                ...cajera,
                'id': 'r-admin',
                'name': 'Administrador',
                'isSystem': true,
              },
              cajera,
            ],
          },
        ),
      ).roles();

      expect(sent.single.url.path, '/staff/roles');
      final [admin, role] = roles;
      expect(admin.isSystem, isTrue);
      expect(role.name, 'Cajera');
      expect(role.members, 2);
      // "otro.nuevo" es de un servidor más nuevo: no se muestra.
      expect(role.permissions, {
        StaffPermission.productsView,
        StaffPermission.ordersView,
      });
    });

    test('crear y editar mandan las claves en el orden del catálogo', () async {
      final repository = HttpStaffRepository(api((_) => cajera));

      await repository.createRole(
        name: 'Repartidor',
        permissions: {
          StaffPermission.ordersUpdateStatus,
          StaffPermission.ordersView,
        },
      );
      expect(sent.single.method, 'POST');
      expect(sent.single.url.path, '/staff/roles');
      expect(jsonDecode(sent.single.body), {
        'name': 'Repartidor',
        'permissions': ['orders.view', 'orders.updateStatus'],
      });

      await repository.updateRole('r-cajera', active: false);
      expect(sent.last.method, 'PATCH');
      expect(sent.last.url.path, '/staff/roles/r-cajera');
      // Solo lo que cambia.
      expect(jsonDecode(sent.last.body), {'active': false});

      await repository.deleteRole('r-cajera');
      expect(sent.last.method, 'DELETE');
      expect(sent.last.url.path, '/staff/roles/r-cajera');
    });

    test('un 409 llega con el motivo del servidor', () async {
      const reason =
          'frank@gmail.com es el último Administrador activo: agrega otro '
          'antes de quitarle el rol';
      await expectLater(
        HttpStaffRepository(
          api((_) => {'statusCode': 409, 'message': reason}, status: 409),
        ).deactivate('m-1'),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.message, 'message', reason)
              .having((f) => f.status, 'status', 409),
        ),
      );
    });
  });

  group('categorías', () {
    test(
      'la lista trae la cantidad de productos en una sola petición',
      () async {
        final list = await HttpAdminCategoriesRepository(
          api(
            (_) => [
              {
                'id': 'cat-1',
                'name': 'Embutidos',
                'description': 'Hot dogs, jamonadas y más',
                'imageUrl': null,
                'productCount': 3,
              },
              {
                'id': 'cat-2',
                'name': 'Lácteos',
                'description': null,
                'imageUrl': null,
                'productCount': 0,
              },
            ],
          ),
        ).list();

        expect(sent.single.url.path, '/categories/summary');
        expect(
          [for (final row in list) (row.category.name, row.productCount)],
          [('Embutidos', 3), ('Lácteos', 0)],
        );
        expect(list.first.category.description, 'Hot dogs, jamonadas y más');
      },
    );

    test('crear y guardar mandan la URL de la foto, o null', () async {
      final repository = HttpAdminCategoriesRepository(
        api(
          (_) => {
            'id': 'cat-1',
            'name': 'Embutidos',
            'description': null,
            'imageUrl': 'https://cdn.tienda.pe/embutidos.jpg',
          },
        ),
      );

      final created = await repository.create(
        'Embutidos',
        imageUrl: 'https://cdn.tienda.pe/embutidos.jpg',
      );
      await repository.update(
        'cat-1',
        name: 'Embutidos',
        description: '',
        imageUrl: null,
      );

      expect(created.imageUrl, 'https://cdn.tienda.pe/embutidos.jpg');
      expect(
        [for (final request in sent) (request.method, request.url.path)],
        [('POST', '/categories'), ('PATCH', '/categories/cat-1')],
      );
      expect(jsonDecode(sent[0].body), {
        'name': 'Embutidos',
        'imageUrl': 'https://cdn.tienda.pe/embutidos.jpg',
      });
      expect(jsonDecode(sent[1].body), {
        'name': 'Embutidos',
        'description': '',
        'imageUrl': null,
      });
    });
  });
}
