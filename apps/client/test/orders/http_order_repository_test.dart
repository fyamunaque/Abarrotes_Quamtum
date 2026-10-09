import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/orders/http_order_repository.dart';
import 'package:neils/orders/order.dart';
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
    expect(order.lines.first.totalCents, 780);
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
            (productId: 'p-arroz', quantity: 2, shownUnitPriceCents: 350),
            (productId: 'p-aceite', quantity: 1, shownUnitPriceCents: null),
          ],
        );

    expect(sent.method, 'POST');
    expect(sent.url.path, '/orders');
    expect(sent.headers['authorization'], 'Bearer el-token');
    expect(jsonDecode(sent.body), {
      'deliveryAddress': 'Av. Arequipa 123',
      'items': [
        {'productId': 'p-arroz', 'quantity': 2, 'unitPrice': 3.5},
        {'productId': 'p-aceite', 'quantity': 1},
      ],
    });
    expectOrder(placed);
    expect(placed.priceChanges, isEmpty);
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
