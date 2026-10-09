import 'package:abarrotes_server/src/auth/firebase_identity.dart';
import 'package:abarrotes_server/src/auth/firebase_token_verifier.dart';
import 'package:abarrotes_server/src/auth/role_guard.dart';
import 'package:abarrotes_server/src/common/api_route.dart';
import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  withServerpod('RoleGuard', (sessionBuilder, _) {
    late Session session;
    late TestClient client;
    late int calls;

    /// Ruta protegida que cuenta sus llamadas y responde el rol del usuario.
    RouteEntry guarded(String path, FirebaseTokenVerifier verifier) => (
      path,
      RoleGuard(
        staffRoles,
        ApiRoute(Method.get, (session, request) {
          calls++;
          return jsonResponse(200, request.currentUser.role.name);
        }),
        verifier: verifier,
      ),
    );

    setUp(() async {
      session = sessionBuilder.build();
      calls = 0;
      final server = await serveRoutes(() => session, [
        guarded('/gestion', testVerifier(google)),
        guarded(
          '/sin-llaves',
          FirebaseTokenVerifier(
            projectId: testProjectId,
            keys: FakeKeys(
              {},
              error: const PublicKeysUnavailableException('sin red'),
            ),
            now: () => testNow,
          ),
        ),
      ]);
      client = TestClient(server, google);
      addTearDown(server.close);
    });

    for (final role in staffRoles) {
      test(
        'deja pasar a ${role.name} y entrega el usuario a la ruta',
        () async {
          await insertUser(session, 'uid-${role.name}', role);

          expect(
            await client.get('/gestion', as: 'uid-${role.name}'),
            (200, role.name),
          );
          expect(calls, 1);
        },
      );
    }

    test('un customer recibe 403 y la ruta no se ejecuta', () async {
      await insertUser(session, 'uid-customer', UserRole.customer);

      final (status, body) = await client.get('/gestion', as: 'uid-customer');

      expect(status, 403);
      expect(body['message'], 'Tu rol no tiene permiso para esta acción');
      expect(calls, 0);
    });

    test('un token válido sin usuario en la base recibe 403', () async {
      expect((await client.get('/gestion', as: 'uid-desconocido')).$1, 403);
      expect(calls, 0);
    });

    test('sin token responde 401 (el guard verifica por su cuenta)', () async {
      final (status, body) = await client.get('/gestion');

      expect(status, 401);
      expect(body['message'], contains('Falta el token'));
      expect(calls, 0);
    });

    test('si no hay llaves de Google responde 503', () async {
      expect((await client.get('/sin-llaves', as: 'uid-staff')).$1, 503);
    });
  });
}
