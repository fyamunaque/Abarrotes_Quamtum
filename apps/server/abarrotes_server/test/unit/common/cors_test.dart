import 'package:abarrotes_server/src/auth/firebase_auth_middleware.dart';
import 'package:abarrotes_server/src/common/api_route.dart';
import 'package:abarrotes_server/src/common/cors.dart';
import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../../support/http_harness.dart';
import '../../support/test_tokens.dart';

void main() {
  group('allowedOrigins', () {
    test('en desarrollo acepta cualquier http://localhost:<puerto>', () {
      final isAllowed = allowedOrigins(development: true);

      expect(isAllowed('http://localhost:5006'), isTrue);
      expect(isAllowed('http://localhost'), isTrue);
      expect(isAllowed('https://localhost:5006'), isFalse);
      expect(isAllowed('http://localhost.evil.com'), isFalse);
      expect(isAllowed('http://tienda.pe'), isFalse);
    });

    test('fuera de desarrollo solo acepta los orígenes de la lista', () {
      final isAllowed = allowedOrigins(
        development: false,
        extra: ' https://tienda.pe ,,https://admin.tienda.pe'.split(','),
      );

      expect(isAllowed('https://tienda.pe'), isTrue);
      expect(isAllowed('https://admin.tienda.pe'), isTrue);
      expect(isAllowed('http://localhost:5006'), isFalse);
      expect(isAllowed(''), isFalse);
    });
  });

  group('corsMiddleware', () {
    const web = 'http://localhost:5006';
    late RelicServer server;

    setUp(() async {
      final verifier = testVerifier(generateRsaKeyPair());
      server = await serveRoutes(
        () => _NoSession(),
        [
          ('/items', ApiRoute(Method.get, (_, _) => jsonResponse(200, 'ok'))),
          (
            '/users/me',
            ApiRoute(Method.get, (_, _) => jsonResponse(200, 'yo')),
          ),
        ],
        // Igual que en server.dart: CORS en `/` y Firebase en `/users`.
        middleware: {
          '/users': firebaseAuthMiddleware(verifier),
          '/': corsMiddleware(allowedOrigins(development: true)),
        },
      );
    });

    tearDown(() => server.close());

    Future<http.Response> send(
      String method,
      String path, {
      Map<String, String> headers = const {},
    }) async {
      final request = http.Request(
        method,
        Uri.parse('http://localhost:${server.port}$path'),
      )..headers.addAll(headers);
      return http.Response.fromStream(await request.send());
    }

    test('responde el preflight de un origen permitido', () async {
      final response = await send(
        'OPTIONS',
        '/items',
        headers: {
          'origin': web,
          'access-control-request-method': 'GET',
          'access-control-request-headers': 'authorization',
        },
      );

      expect(response.statusCode, 204);
      expect(response.headers['access-control-allow-origin'], web);
      expect(response.headers['access-control-allow-methods'], contains('GET'));
      expect(
        response.headers['access-control-allow-headers'],
        contains('Authorization'),
      );
      expect(response.headers['access-control-max-age'], '600');
      expect(response.headers['vary'], 'Origin');
    });

    test('el preflight a /users/me no pasa por el token de Firebase', () async {
      final response = await send(
        'OPTIONS',
        '/users/me',
        headers: {'origin': web, 'access-control-request-method': 'GET'},
      );

      expect(response.statusCode, 204);
      expect(response.headers['access-control-allow-origin'], web);
    });

    test('agrega el origen a las respuestas, también a los errores', () async {
      final ok = await send('GET', '/items', headers: {'origin': web});
      expect(ok.statusCode, 200);
      expect(ok.body, '"ok"');
      expect(ok.headers['access-control-allow-origin'], web);
      expect(ok.headers['vary'], 'Origin');

      // Sin token: el 401 también lleva el header, para que la app lo lea.
      final unauthorized = await send(
        'GET',
        '/users/me',
        headers: {'origin': web},
      );
      expect(unauthorized.statusCode, 401);
      expect(unauthorized.headers['access-control-allow-origin'], web);
    });

    test('a un origen ajeno no le agrega nada', () async {
      const other = 'http://tienda-falsa.com';

      final preflight = await send(
        'OPTIONS',
        '/items',
        headers: {'origin': other, 'access-control-request-method': 'GET'},
      );
      expect(preflight.statusCode, 204);
      expect(preflight.headers, isNot(contains('access-control-allow-origin')));

      final get = await send('GET', '/items', headers: {'origin': other});
      expect(get.statusCode, 200);
      expect(get.headers, isNot(contains('access-control-allow-origin')));
    });

    test(
      'sin Origin (curl, la app Android) responde igual que antes',
      () async {
        final get = await send('GET', '/items');
        expect(get.statusCode, 200);
        expect(get.headers, isNot(contains('access-control-allow-origin')));

        expect((await send('PUT', '/items')).statusCode, 405);
      },
    );
  });
}

/// Las rutas de estos tests no usan la sesión.
class _NoSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('La ruta no debería usar la sesión');
}
