import 'package:abarrotes_server/src/auth/firebase_auth_middleware.dart';
import 'package:abarrotes_server/src/auth/firebase_token_verifier.dart';
import 'package:abarrotes_server/src/auth/role_guard.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../unit/auth/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Ruta de prueba: cuenta sus llamadas y responde el rol del usuario actual.
class _EchoRoute extends Route {
  _EchoRoute() : super(methods: {Method.get, Method.post});

  int calls = 0;

  @override
  Result handleCall(Session session, Request request) {
    calls++;
    return Response.ok(body: Body.fromString(request.currentUser.role.name));
  }
}

void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  withServerpod('RoleGuard', (sessionBuilder, _) {
    late Session session;
    late RelicServer server;
    late _EchoRoute echo;

    setUp(() async {
      session = sessionBuilder.build();
      echo = _EchoRoute();
      final guarded = RoleGuard({UserRole.admin, UserRole.staff}, echo);
      final verifier = FirebaseTokenVerifier(
        projectId: testProjectId,
        keys: FakeKeys({'llave-1': google.public}),
        now: () => testNow,
      );
      final app = RelicApp()
        ..use('/gestion', firebaseAuthMiddleware(verifier))
        ..anyOf(
          guarded.methods,
          '/gestion',
          (req) => guarded.handleCall(session, req),
        );
      server = await app.serve(port: 0);
    });

    tearDown(() => server.close());

    Future<http.Response> callAs(String? uid) => http.get(
      Uri.parse('http://localhost:${server.port}/gestion'),
      headers: {
        if (uid != null)
          'authorization':
              'Bearer ${signToken(google.private, claims: validClaims(uid: uid))}',
      },
    );

    Future<void> insertUser(String uid, UserRole role) => User.db.insertRow(
      session,
      User(
        firebaseUid: uid,
        email: '$uid@tienda.pe',
        name: 'Usuario $uid',
        role: role,
      ),
    );

    for (final role in [UserRole.admin, UserRole.staff]) {
      test(
        'deja pasar a ${role.name} y entrega el usuario a la ruta',
        () async {
          await insertUser('uid-${role.name}', role);

          final response = await callAs('uid-${role.name}');

          expect((response.statusCode, response.body), (200, role.name));
          expect(echo.calls, 1);
        },
      );
    }

    test('un customer recibe 403 y la ruta no se ejecuta', () async {
      await insertUser('uid-customer', UserRole.customer);

      final response = await callAs('uid-customer');

      expect(response.statusCode, 403);
      expect(response.body, contains('Tu rol no tiene permiso'));
      expect(echo.calls, 0);
    });

    test('un token válido sin usuario en la base recibe 403', () async {
      final response = await callAs('uid-desconocido');

      expect(response.statusCode, 403);
      expect(echo.calls, 0);
    });

    test('sin token responde 401 antes de llegar al guard', () async {
      final response = await callAs(null);

      expect(response.statusCode, 401);
      expect(echo.calls, 0);
    });
  });
}
