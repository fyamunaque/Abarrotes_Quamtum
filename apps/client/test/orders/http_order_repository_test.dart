import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/orders/fulfillment.dart';
import 'package:neils/orders/http_order_repository.dart';
import 'package:neils/orders/order.dart';
import 'package:neils/orders/order_filter.dart';
import 'package:neils/orders/order_status.dart';

void main() {
  http.Response json(int status, Object? body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );

  HttpOrderRepository repository(MockClientHandler handler) =>
      HttpOrderRepository(
        ApiClient(MockClient(handler), baseUrl: Uri.parse('http://api.pe')),
      );

  /// Un pedido como lo manda el servidor (orderJson en apps/server).
  const order = {
    'id': 'o-1',
    'status': 'outForDelivery',
    'total': '12.3',
    'deliveryAddress': 'Av. Arequipa 123',
    'createdAt': '2026-10-04T15:30:00.000Z',
    'updatedAt': '2026-10-04T16:00:00.000Z',
    'customerId': 'u-1',
    'items': [
      {
        'id': 'i-1',
        'quantity': 2,
        'unitPrice': '3.9',
        'orderId': 'o-1',
        'productId': 'p-arroz',
        'product': {'id': 'p-arroz', 'name': 'Arroz', 'imageUrl': null},
      },
      {
        'id': 'i-2',
        'quantity': 1,
        'unitPrice': '4.5',
        'orderId': 'o-1',
        'productId': 'p-aceite',
        'product': {'id': 'p-aceite', 'name': 'Aceite', 'imageUrl': null},
      },
    ],
  };

  void expectOrder(Order order) {
    expect(order.id, 'o-1');
    expect(order.status, OrderStatus.outForDelivery);
    expect(order.totalCents, 1230);
    expect(order.deliveryAddress, 'Av. Arequipa 123');
    expect(order.createdAt, DateTime.utc(2026, 10, 4, 15, 30));
    expect(
      [
        for (final line in order.lines)
          (line.productId, line.name, line.quantity, line.unitPriceCents),
      ],
      [('p-arroz', 'Arroz', 2, 390), ('p-aceite', 'Aceite', 1, 450)],
    );
    expect(order.lines.first.lineTotalCents, 780);
  }

  test('hacer un pedido: POST /orders con el token y el precio del carrito, '
      'que el servidor solo compara', () async {
    late http.Request sent;
    final placed =
        await repository((request) async {
          sent = request;
          return json(201, order);
        }).place(
          'el-token',
          deliveryAddress: 'Av. Arequipa 123',
          lines: [
            (
              productId: 'p-arroz',
              quantity: 2,
              shownUnitPriceCents: 350,
              shownLineTotalCents: 600,
            ),
            (
              productId: 'p-aceite',
              quantity: 1,
              shownUnitPriceCents: null,
              shownLineTotalCents: null,
            ),
          ],
        );

    expect(sent.method, 'POST');
    expect(sent.url.path, '/orders');
    expect(sent.headers['authorization'], 'Bearer el-token');
    expect(jsonDecode(sent.body), {
      'fulfillmentType': 'delivery',
      'deliveryAddress': 'Av. Arequipa 123',
      'items': [
        {
          'productId': 'p-arroz',
          'quantity': 2,
          'unitPrice': 3.5,
          // El total de la línea que mostraba la cotización.
          'lineTotal': 6.0,
        },
        {'productId': 'p-aceite', 'quantity': 1},
      ],
    });
    expectOrder(placed);
    expect(placed.priceChanges, isEmpty);
  });

  test('para recoger en tienda: sin dirección', () async {
    late http.Request sent;
    await repository((request) async {
      sent = request;
      return json(201, {
        ...order,
        'fulfillmentType': 'pickup',
        'deliveryAddress': null,
        'pickupCode': 'K7M2XQ',
      });
    }).place(
      't',
      fulfillmentType: FulfillmentType.pickup,
      deliveryAddress: 'no se manda',
      lines: [
        (
          productId: 'p-arroz',
          quantity: 1,
          shownUnitPriceCents: null,
          shownLineTotalCents: null,
        ),
      ],
    );

    expect(jsonDecode(sent.body), {
      'fulfillmentType': 'pickup',
      'items': [
        {'productId': 'p-arroz', 'quantity': 1},
      ],
    });
  });

  test('la respuesta trae los precios que cambiaron', () async {
    final placed = await repository(
      (_) async => json(201, {
        ...order,
        'priceChanges': [
          {
            'productId': 'p-arroz',
            'name': 'Arroz',
            'shownUnitPrice': '3.5',
            'unitPrice': '3.9',
          },
        ],
      }),
    ).place('t', deliveryAddress: 'x', lines: const []);

    final change = placed.priceChanges.single;
    expect(change.name, 'Arroz');
    expect((change.shownUnitPriceCents, change.unitPriceCents), (350, 390));
  });

  test('con lineTotal, el cambio llega por el total de la línea', () async {
    final placed = await repository(
      (_) async => json(201, {
        ...order,
        'priceChanges': [
          {
            'productId': 'p-arroz',
            'name': 'Arroz',
            'shownLineTotal': '24.9',
            'lineTotal': '49.8',
          },
        ],
      }),
    ).place('t', deliveryAddress: 'x', lines: const []);

    final change = placed.priceChanges.single;
    expect((change.shownLineTotalCents, change.lineTotalCents), (2490, 4980));
    expect(change.shownUnitPriceCents, isNull);
  });

  test('quote manda los ítems y lee la respuesta', () async {
    final sent = <http.Request>[];
    final repo = repository((request) async {
      sent.add(request);
      return json(200, {
        'lines': [
          {
            'productId': 'p-arroz',
            'product': {'id': 'p-arroz', 'name': 'Arroz', 'imageUrl': null},
            'quantity': 2,
            'listUnitPrice': '24.9',
            'unitPrice': '24.9',
            'lineTotal': '24.9',
            'isGift': false,
            'promotions': [
              {'label': '2x1', 'saved': '24.9'},
            ],
          },
          {
            'productId': 'p-sal',
            'product': {'id': 'p-sal', 'name': 'Sal 1 kg', 'imageUrl': null},
            'quantity': 1,
            'listUnitPrice': '1.5',
            'unitPrice': '0',
            'lineTotal': '0',
            'isGift': true,
            'promotions': [
              {'label': 'Regalo: Sal 1 kg', 'saved': '1.5'},
            ],
          },
        ],
        'subtotal': '49.8',
        'discount': '24.9',
        'total': '24.9',
        'notices': ['Solo quedaba 1 de Sal 1 kg para regalo'],
      });
    });

    final quote = await repo.quote([
      (productId: 'p-arroz', quantity: 2),
    ], idToken: 'el-token');
    await repo.quote([(productId: 'p-arroz', quantity: 2)]);

    expect(sent.first.url.path, '/orders/quote');
    expect(sent.first.headers['authorization'], 'Bearer el-token');
    // Sin sesión, sin token: las promociones de todos.
    expect(sent.last.headers.containsKey('authorization'), isFalse);
    expect(jsonDecode(sent.first.body), {
      'items': [
        {'productId': 'p-arroz', 'quantity': 2},
      ],
    });
    expect(
      (quote.subtotalCents, quote.discountCents, quote.totalCents),
      (4980, 2490, 2490),
    );
    expect(quote.lineOf('p-arroz')?.lineTotalCents, 2490);
    expect([for (final gift in quote.gifts) gift.name], ['Sal 1 kg']);
    expect(quote.notices, ['Solo quedaba 1 de Sal 1 kg para regalo']);
  });

  test('sin stock: el 409 llega con el mensaje del servidor', () {
    expect(
      repository(
        (_) async => json(409, {
          'statusCode': 409,
          'message': 'Stock insuficiente: Aceite tiene 1 unidad',
        }),
      ).place('t', deliveryAddress: 'x', lines: const []),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.status, 'status', 409)
            .having(
              (f) => f.message,
              'message',
              'Stock insuficiente: Aceite tiene 1 unidad',
            ),
      ),
    );
  });

  test('mis pedidos: GET /orders/mine paginado', () async {
    late http.Request sent;
    final page = await repository((request) async {
      sent = request;
      return json(200, {
        'data': [order],
        'meta': {'total': 11, 'page': 2, 'limit': 10},
      });
    }).mine('el-token', page: 2);

    expect(sent.url.path, '/orders/mine');
    expect(sent.url.queryParameters, {'page': '2', 'limit': '10'});
    expect(sent.headers['authorization'], 'Bearer el-token');
    expect(page.total, 11);
    expectOrder(page.items.single);
  });

  test('mis pedidos: la búsqueda y los filtros van en la query', () async {
    late http.Request sent;
    await repository((request) async {
      sent = request;
      return json(200, {
        'data': <Object?>[],
        'meta': {'total': 0},
      });
    }).mine(
      'el-token',
      filter: (
        search: ' arroz ',
        progress: OrderProgress.active,
        fulfillmentType: FulfillmentType.pickup,
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 15),
      ),
    );

    expect(sent.url.queryParameters, {
      'page': '1',
      'limit': '10',
      'search': 'arroz',
      'state': 'active',
      'fulfillmentType': 'pickup',
      'from': '2026-10-01',
      'to': '2026-10-15',
    });
  });

  test('un estado que la app no conoce: "algo inesperado"', () {
    expect(
      repository((_) async => json(201, {...order, 'status': 'lost'}))
          .place('t', deliveryAddress: 'x', lines: const []),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.message,
          'message',
          'El servidor respondió algo inesperado.',
        ),
      ),
    );
  });
}
