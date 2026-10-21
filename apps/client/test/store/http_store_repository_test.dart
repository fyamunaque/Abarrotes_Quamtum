import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/store/store_repository.dart';
import 'package:neils/store/store_settings.dart';

void main() {
  late List<http.Request> sent;

  HttpStoreRepository repository(Object? body, {int status = 200}) {
    sent = [];
    final client = ApiClient(
      MockClient((request) async {
        sent.add(request);
        return http.Response.bytes(
          utf8.encode(jsonEncode(body)),
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
      baseUrl: Uri.parse('http://api.pe'),
    );
    return HttpStoreRepository(client, AuthedApi(client, () async => 'tok'));
  }

  test('GET /store: dónde y cuándo se recoge', () async {
    final store = await repository({
      'name': "Neil's Food Services",
      'address': 'Av. Arequipa 1234, Lince',
      'reference': 'Frente al parque',
      'phone': null,
      'openingHours': 'Lun a sáb de 8 a 20 h',
      'pickupInstructions': 'Muestra tu código en caja.',
      'updatedAt': '2026-10-15T15:00:00.000Z',
    }).settings();

    expect(store.name, "Neil's Food Services");
    expect(store.address, 'Av. Arequipa 1234, Lince');
    expect(store.reference, 'Frente al parque');
    expect(store.phone, isNull);
    expect(store.openingHours, 'Lun a sáb de 8 a 20 h');
    expect(store.pickupInstructions, 'Muestra tu código en caja.');
  });

  test(
    'guardar: PATCH /store con el token y los campos vacíos en null',
    () async {
      final saved =
          await repository({
            'name': "Neil's",
            'address': 'Av. Arequipa 1234',
            'reference': null,
            'phone': '987654321',
            'openingHours': null,
            'pickupInstructions': null,
            'updatedAt': '2026-10-15T15:00:00.000Z',
          }).update(
            const StoreSettings(
              name: "Neil's",
              address: 'Av. Arequipa 1234',
              phone: '987654321',
            ),
          );

      expect(sent.single.method, 'PATCH');
      expect(sent.single.url.path, '/store');
      expect(sent.single.headers['authorization'], 'Bearer tok');
      expect(jsonDecode(sent.single.body), {
        'name': "Neil's",
        'address': 'Av. Arequipa 1234',
        'reference': null,
        'phone': '987654321',
        'openingHours': null,
        'pickupInstructions': null,
      });
      expect(saved.phone, '987654321');
    },
  );

  test('una respuesta sin esa forma es un ApiFailure', () async {
    await expectLater(
      repository({'nombre': 'x'}).settings(),
      throwsA(isA<ApiFailure>()),
    );
  });
}
