import 'dart:convert';

import 'package:abarrotes_server/src/auth/firebase_auth_middleware.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/users/users_routes.dart';
import 'package:abarrotes_server/src/users/users_service.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

/// GET /users/me y POST /users contra la base de pruebas, pasando por HTTP,
/// el middleware de Firebase y las rutas reales. Cada test se revierte al
/// terminar.
void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  withServerpod('Rutas de usuarios', (sessionBuilder, _) {
    late Session session;
    late RelicServer server;

    setUp(() async {
      session = sessionBuilder.build();
      final verifier = testVerifier(google);
      // Las mismas rutas (y guards) que addUsersRoutes, con la sesión del test.
      server = await serveRoutes(
        () => session,
        usersRoutes(const UsersService(), verifier),
        middleware: {'/users': firebaseAuthMiddleware(verifier)},
      );
    });

    tearDown(() => server.close());

    Uri url(String path) => Uri.parse('http://localhost:${server.port}$path');

    Map<String, String> authAs(
      String uid, {
      String? email = 'ana@example.com',
      String? name = 'Ana Quispe',
    }) => {
      'authorization':
          'Bearer ${signToken(
            google.private,
            claims: validClaims(uid: uid, email: email, name: name),
          )}',
      'content-type': 'application/json',
    };

    Future<User> insertUser(String uid, UserRole role, {String? email}) =>
        User.db.insertRow(
          session,
          User(
            firebaseUid: uid,
            email: email ?? '$uid@tienda.pe',
            name: 'Usuario $uid',
            role: role,
          ),
        );

    Future<(int, dynamic)> getMe(Map<String, String> headers) async {
      final response = await http.get(url('/users/me'), headers: headers);
      return (response.statusCode, jsonDecode(response.body));
    }

    Future<(int, dynamic)> postUser(
      Map<String, String> headers,
      Object body,
    ) async {
      final response = await http.post(
        url('/users'),
        headers: headers,
        body: body is String ? body : jsonEncode(body),
      );
      return (response.statusCode, jsonDecode(response.body));
    }

    final staffBody = {
      'firebaseUid': 'uid-luis',
      'email': 'Luis@Tienda.pe',
      'name': 'Luis Rojas',
      'phone': '987654321',
      'role': 'staff',
    };

    group('GET /users/me', () {
      test('la primera vez crea un cliente con los datos del token', () async {
        final (status, body) = await getMe(
          authAs('uid-ana', email: 'Ana@Example.com'),
        );

        expect(status, 200);
        expect(body, {
          'id': isA<String>(),
          'email': 'ana@example.com',
          'name': 'Ana Quispe',
          'phone': null,
          'role': 'customer',
          'address': null,
          'createdAt': isA<String>(),
        });
        final stored = await User.db.find(
          session,
          where: (u) => u.firebaseUid.equals('uid-ana'),
        );
        expect(stored, hasLength(1));
        expect(stored.single.id.toString(), body['id']);
      });

      test('las siguientes veces devuelve el mismo usuario', () async {
        final (_, first) = await getMe(authAs('uid-ana'));
        final (status, second) = await getMe(authAs('uid-ana'));

        expect(status, 200);
        expect(second['id'], first['id']);
        expect(await User.db.count(session), 1);
      });

      test('devuelve el rol guardado (staff creado por un admin)', () async {
        await insertUser('uid-luis', UserRole.staff);

        final (status, body) = await getMe(authAs('uid-luis'));

        expect(status, 200);
        expect(body['role'], 'staff');
        expect(body['email'], 'uid-luis@tienda.pe');
      });

      test('sin nombre en el token usa lo que va antes de la @', () async {
        final (_, body) = await getMe(
          authAs('uid-ana', email: 'ana.quispe@example.com', name: null),
        );

        expect(body['name'], 'ana.quispe');
      });

      test('un token sin email responde 400', () async {
        final (status, body) = await getMe(authAs('uid-tel', email: null));

        expect(status, 400);
        expect(body['message'], contains('no tiene email'));
        expect(await User.db.count(session), 0);
      });

      test('un email que ya usa otra cuenta responde 409', () async {
        await insertUser(
          'uid-otra',
          UserRole.customer,
          email: 'ana@example.com',
        );

        final (status, _) = await getMe(authAs('uid-ana'));

        expect(status, 409);
      });

      test('sin token responde 401', () async {
        final response = await http.get(url('/users/me'));

        expect(response.statusCode, 401);
      });
    });

    group('POST /users', () {
      test('un admin crea una cuenta staff vinculada al firebaseUid', () async {
        await insertUser('uid-admin', UserRole.admin);

        final (status, body) = await postUser(authAs('uid-admin'), staffBody);

        expect(status, 201);
        expect(body, {
          'id': isA<String>(),
          'email': 'luis@tienda.pe',
          'name': 'Luis Rojas',
          'phone': '987654321',
          'role': 'staff',
          'address': null,
          'createdAt': isA<String>(),
        });
        final (_, me) = await getMe(authAs('uid-luis'));
        expect(me['id'], body['id']);
        expect(me['role'], 'staff');
      });

      test('un admin también puede crear otro admin', () async {
        await insertUser('uid-admin', UserRole.admin);

        final (status, body) = await postUser(authAs('uid-admin'), {
          ...staffBody,
          'role': 'admin',
        });

        expect((status, body['role']), (201, 'admin'));
      });

      for (final role in [UserRole.staff, UserRole.customer]) {
        test('un usuario ${role.name} recibe 403', () async {
          await insertUser('uid-${role.name}', role);

          final (status, _) = await postUser(
            authAs('uid-${role.name}'),
            staffBody,
          );

          expect(status, 403);
        });
      }

      test('alguien sin cuenta en la base recibe 403', () async {
        final (status, _) = await postUser(authAs('uid-nadie'), staffBody);

        expect(status, 403);
        expect(await User.db.count(session), 0);
      });

      test('role customer responde 400', () async {
        await insertUser('uid-admin', UserRole.admin);

        final (status, body) = await postUser(authAs('uid-admin'), {
          ...staffBody,
          'role': 'customer',
        });

        expect(status, 400);
        expect(body['message'], ['role debe ser admin o staff']);
      });

      test('un body que no es JSON responde 400', () async {
        await insertUser('uid-admin', UserRole.admin);

        final (status, _) = await postUser(authAs('uid-admin'), '{roto');

        expect(status, 400);
      });

      test('un firebaseUid ya registrado responde 409', () async {
        await insertUser('uid-admin', UserRole.admin);
        await insertUser('uid-luis', UserRole.customer);

        final (status, body) = await postUser(authAs('uid-admin'), staffBody);

        expect(status, 409);
        expect(body['message'], contains('firebaseUid'));
      });

      test('un email ya registrado responde 409', () async {
        await insertUser('uid-admin', UserRole.admin);
        await insertUser(
          'uid-otro',
          UserRole.customer,
          email: 'luis@tienda.pe',
        );

        final (status, body) = await postUser(authAs('uid-admin'), staffBody);

        expect(status, 409);
        expect(body['message'], contains('email'));
      });
    });
  });
}
