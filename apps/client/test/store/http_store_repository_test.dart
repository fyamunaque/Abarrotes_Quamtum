import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/store/store_repository.dart';

void main() {
  HttpStoreRepository repository(Object? body, {int status = 200}) =>
      HttpStoreRepository(
        ApiClient(
          MockClient(
            (request) async => http.Response.bytes(
              utf8.encode(jsonEncode(body)),
              status,
              headers: {'content-type': 'application/json'},
            ),
          ),
          baseUrl: Uri.parse('http://api.pe'),
        ),
      );

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

  test('una respuesta sin esa forma es un ApiFailure', () async {
    await expectLater(
      repository({'nombre': 'x'}).settings(),
      throwsA(isA<ApiFailure>()),
    );
  });
}
