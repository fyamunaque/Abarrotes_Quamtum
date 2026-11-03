import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/promo_codes/my_promo_codes_repository.dart';

void main() {
  http.Response json(int status, Object? body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );

  /// Un código activado, como lo manda el servidor (`redeemedCodeJson`).
  const code = {
    'code': 'VERANO-10',
    'expiresAt': '2026-12-01T05:00:00.000Z',
    'usesLeft': 2,
    'minPurchase': '30',
    'promotions': [
      {
        'label': '2x1',
        'product': {'id': 'p-1', 'name': 'Arroz extra 5 kg'},
      },
    ],
  };

  test('mine y redeem van con el token', () async {
    final sent = <http.Request>[];
    final repository = HttpMyPromoCodesRepository(
      ApiClient(
        MockClient((request) async {
          sent.add(request);
          return json(200, request.method == 'GET' ? [code] : code);
        }),
        baseUrl: Uri.parse('http://api.pe'),
      ),
    );

    final mine = await repository.mine('token-ana');
    final redeemed = await repository.redeem('token-ana', '  verano-10 ');

    expect(sent.first.url.path, '/promo-codes/mine');
    expect(sent.first.headers['authorization'], 'Bearer token-ana');
    expect(sent.last.url.path, '/promo-codes/redeem');
    expect(sent.last.headers['authorization'], 'Bearer token-ana');
    expect(jsonDecode(sent.last.body), {'code': 'verano-10'});
    final verano = mine.single;
    expect(verano.code, 'VERANO-10');
    expect(verano.expiresAt, DateTime.utc(2026, 12, 1, 5));
    // El último día en que sirve, en la tienda.
    expect(verano.lastDay, DateTime(2026, 11, 30));
    expect((verano.usesLeft, verano.minPurchaseCents), (2, 3000));
    expect(verano.promotions, ['2x1 en Arroz extra 5 kg']);
    expect(redeemed.code, 'VERANO-10');
  });

  test('el error del servidor llega con su mensaje', () {
    final repository = HttpMyPromoCodesRepository(
      ApiClient(
        MockClient(
          (_) async => json(404, {
            'statusCode': 404,
            'message': 'El código no existe o ya no está vigente',
          }),
        ),
        baseUrl: Uri.parse('http://api.pe'),
      ),
    );

    expect(
      repository.redeem('t', 'NADA'),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.message,
          'message',
          'El código no existe o ya no está vigente',
        ),
      ),
    );
  });
}
