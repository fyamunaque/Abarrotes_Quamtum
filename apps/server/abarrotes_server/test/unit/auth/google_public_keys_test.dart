import 'dart:convert';
import 'dart:io';

import 'package:abarrotes_server/src/auth/firebase_identity.dart';
import 'package:abarrotes_server/src/auth/google_public_keys.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Certificado autofirmado de prueba (la llave privada se descartó al crearlo).
final _certificate = File(
  'test/unit/auth/fixtures/test_certificate.pem',
).readAsStringSync();

void main() {
  late DateTime now;
  late int downloads;
  late http.Response Function() respond;

  GooglePublicKeys keysWith({Duration delay = Duration.zero}) {
    final client = MockClient((request) async {
      downloads++;
      await Future<void>.delayed(delay);
      return respond();
    });
    return GooglePublicKeys(client: client, now: () => now);
  }

  http.Response certificates(
    List<String> kids, {
    String? cacheControl = 'public, max-age=3600, must-revalidate',
  }) => http.Response(
    jsonEncode({for (final kid in kids) kid: _certificate}),
    200,
    headers: {'cache-control': ?cacheControl},
  );

  setUp(() {
    now = DateTime.utc(2026, 10, 1, 12);
    downloads = 0;
    respond = () => certificates(['a', 'b']);
  });

  test('descarga las llaves una vez y las reusa hasta el max-age', () async {
    final keys = keysWith();

    expect(await keys.keyFor('a'), isNotNull);
    expect(await keys.keyFor('b'), isNotNull);
    now = now.add(const Duration(minutes: 59));
    expect(await keys.keyFor('a'), isNotNull);
    expect(downloads, 1);

    now = now.add(const Duration(minutes: 1));
    expect(await keys.keyFor('a'), isNotNull);
    expect(downloads, 2);
  });

  test('sin max-age, las llaves duran una hora', () async {
    respond = () => certificates(['a'], cacheControl: null);
    final keys = keysWith();

    await keys.keyFor('a');
    now = now.add(const Duration(minutes: 59));
    await keys.keyFor('a');
    expect(downloads, 1);

    now = now.add(const Duration(minutes: 1));
    await keys.keyFor('a');
    expect(downloads, 2);
  });

  test('pedidos simultáneos comparten una sola descarga', () async {
    final keys = keysWith(delay: const Duration(milliseconds: 20));

    final results = await Future.wait([
      keys.keyFor('a'),
      keys.keyFor('b'),
      keys.keyFor('a'),
    ]);

    expect(results, everyElement(isNotNull));
    expect(downloads, 1);
  });

  test(
    'un kid desconocido fuerza otra descarga, como mucho una por minuto',
    () async {
      final keys = keysWith();

      expect(await keys.keyFor('nueva'), isNull);
      now = now.add(const Duration(seconds: 30));
      expect(await keys.keyFor('nueva'), isNull);
      expect(downloads, 1);

      // Google rotó las llaves antes del max-age.
      respond = () => certificates(['b', 'nueva']);
      now = now.add(const Duration(seconds: 30));
      expect(await keys.keyFor('nueva'), isNotNull);
      expect(downloads, 2);
    },
  );

  test(
    'si falla la descarga y no hay llaves vigentes, lanza el error',
    () async {
      respond = () => http.Response('error', 500);

      await expectLater(
        keysWith().keyFor('a'),
        throwsA(isA<PublicKeysUnavailableException>()),
      );
    },
  );

  test('tras una descarga fallida no reintenta antes de un minuto', () async {
    respond = () => http.Response('error', 500);
    final keys = keysWith();
    final unavailable = throwsA(isA<PublicKeysUnavailableException>());

    await expectLater(keys.keyFor('a'), unavailable);
    now = now.add(const Duration(seconds: 59));
    await expectLater(keys.keyFor('a'), unavailable);
    expect(downloads, 1);

    respond = () => certificates(['a']);
    now = now.add(const Duration(seconds: 1));
    expect(await keys.keyFor('a'), isNotNull);
    expect(downloads, 2);
  });

  test('una respuesta que no son certificados también es un error', () async {
    respond = () => http.Response('{"a": "no es un certificado"}', 200);

    await expectLater(
      keysWith().keyFor('a'),
      throwsA(isA<PublicKeysUnavailableException>()),
    );
  });

  test(
    'si falla la recarga por un kid desconocido, conserva las llaves vigentes',
    () async {
      final keys = keysWith();
      await keys.keyFor('a');

      respond = () => http.Response('error', 503);
      now = now.add(const Duration(minutes: 2));

      expect(await keys.keyFor('nueva'), isNull);
      expect(await keys.keyFor('a'), isNotNull);
      expect(downloads, 2);
    },
  );
}
