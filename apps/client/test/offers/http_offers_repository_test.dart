import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/offers/offers_repository.dart';

void main() {
  http.Response json(int status, Object? body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );

  /// Como la manda el servidor (activePromotionJson en apps/server).
  Map<String, Object?> offer(String id, String audience, {String? title}) => {
    'id': id,
    'title': title,
    'audience': audience,
    'promoPrice': '17.9',
    'startDate': '2026-10-01',
    'endDate': '2026-10-15',
    'product': {
      'id': 'p-$id',
      'name': 'Arroz extra 5 kg',
      'price': '24.9',
      'imageUrl': null,
      'categoryId': 'c-abarrotes',
    },
  };

  test('pide /promotions/active con el token y deja solo las VIP', () async {
    late http.Request sent;
    final offers = await HttpOffersRepository(
      ApiClient(
        MockClient((request) async {
          sent = request;
          return json(200, {
            'data': [
              offer('o-1', 'vip', title: 'Precio VIP'),
              offer('o-2', 'everyone'),
            ],
            'meta': {'total': 2, 'page': 1, 'limit': 100},
          });
        }),
        baseUrl: Uri.parse('http://api.pe'),
      ),
      idToken: () async => 'token-ana',
    ).exclusive();

    expect(sent.url.path, '/promotions/active');
    expect(sent.url.queryParameters, {'limit': '100'});
    expect(sent.headers['authorization'], 'Bearer token-ana');
    final vip = offers.single;
    expect(vip.id, 'o-1');
    expect(vip.vip, isTrue);
    expect(vip.title, 'Precio VIP');
    expect(vip.productId, 'p-o-1');
    expect(vip.productName, 'Arroz extra 5 kg');
    // Para el color de su marcador si no tiene foto.
    expect(vip.categoryId, 'c-abarrotes');
    expect((vip.priceCents, vip.promoPriceCents), (2490, 1790));
    expect(vip.endDate, '2026-10-15');
  });

  test('una respuesta con otra forma: "algo inesperado"', () {
    expect(
      HttpOffersRepository(
        ApiClient(
          MockClient((_) async => json(200, {'data': 'x'})),
          baseUrl: Uri.parse('http://api.pe'),
        ),
        idToken: () async => null,
      ).exclusive(),
      throwsA(isA<ApiFailure>()),
    );
  });
}
