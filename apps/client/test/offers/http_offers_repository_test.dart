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

  test('un 2x1 o un % VIP también son ofertas', () async {
    final offers = await HttpOffersRepository(
      ApiClient(
        MockClient(
          (_) async => json(200, {
            'data': [
              {
                ...offer('o-1', 'vip'),
                'type': 'buyXPayY',
                'label': '2x1',
                'promoPrice': null,
                'buyQuantity': 2,
                'payQuantity': 1,
              },
              {
                ...offer('o-2', 'selected'),
                'type': 'percentOff',
                'label': '20 % menos',
                'promoPrice': null,
                'percent': 20,
              },
            ],
            'meta': {'total': 2, 'page': 1, 'limit': 100},
          }),
        ),
        baseUrl: Uri.parse('http://api.pe'),
      ),
      idToken: () async => 'token-ana',
    ).exclusive();

    final [deal, percent] = offers;
    expect(deal.promoPriceCents, isNull);
    expect(
      (deal.deal?.label, deal.deal?.description),
      ('2x1', '2x1 en este producto'),
    );
    // El % queda en el precio: 24.90 menos 20 %.
    expect(percent.promoPriceCents, 1992);
    expect(percent.deal, isNull);
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
