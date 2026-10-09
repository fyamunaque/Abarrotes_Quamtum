import 'dart:convert';

import 'package:abarrotes_server/src/auth/firebase_auth_middleware.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/users/users_routes.dart';
import 'package:abarrotes_server/src/users/users_service.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/promotions_setup.dart';
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
        usersRoutes(const UsersService(), verifier, shoppers: testShoppers),
        middleware: {'/users': firebaseAuthMiddleware(verifier)},
      );
    });

    tearDown(() => server.close());

    Uri url(String path) => Uri.parse('http://localhost:${server.port}$path');

    Map<String, String> authAs(
      String uid, {
      String? email = 'ana@example.com',
      String? name = 'Ana Quispe',
      bool emailVerified = true,
    }) => {
      'authorization':
          'Bearer ${signToken(
            google.private,
            claims: validClaims(
              uid: uid,
              email: email,
              emailVerified: emailVerified,
              name: name,
            ),
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
          'isVip': false,
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

      group('isVip', () {
        setUp(() async {
          final admin = await insertUser('uid-admin', UserRole.admin);
          await insertVips(session, admin, ['ana@example.com']);
        });

        test(
          'true si el correo es de un VIP activo y está verificado',
          () async {
            final (status, body) = await getMe(
              authAs('uid-ana', email: 'Ana@Example.com'),
            );

            expect(status, 200);
            expect(body['isVip'], isTrue);
          },
        );

        test('false si el correo no está verificado', () async {
          final (_, body) = await getMe(
            authAs('uid-ana', emailVerified: false),
          );

          expect(body['isVip'], isFalse);
        });

        test('false si el VIP se dio de baja o es otro correo', () async {
          final (_, other) = await getMe(
            authAs('uid-luis', email: 'luis@example.com'),
          );
          await VipCustomer.db.updateWhere(
            session,
            columnValues: (vip) => [vip.active(false)],
            where: (vip) => vip.email.equals('ana@example.com'),
          );
          final (_, inactive) = await getMe(authAs('uid-ana'));

          expect(other['isVip'], isFalse);
          expect(inactive['isVip'], isFalse);
        });
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

    group('dispositivos', () {
      Future<int> send(
        String method,
        Map<String, String> headers, {
        Object? body,
        String query = '',
      }) async {
        final request = http.Request(method, url('/users/me/devices$query'))
          ..headers.addAll(headers);
        if (body != null) {
          request.body = body is String ? body : jsonEncode(body);
        }
        final response = await http.Response.fromStream(await request.send());
        return response.statusCode;
      }

      Future<List<(String, String, String?)>> devices() async => [
        for (final device in await DeviceToken.db.find(
          session,
          orderBy: (d) => d.token,
          include: DeviceToken.include(user: User.include()),
        ))
          (device.token, device.user!.firebaseUid, device.platform),
      ];

      test('PUT registra el dispositivo; repetirlo no lo duplica', () async {
        final ana = authAs('uid-ana');

        expect(
          await send('PUT', ana, body: {'token': 'fcm-1', 'platform': 'web'}),
          204,
        );
        expect(await send('PUT', ana, body: {'token': 'fcm-1'}), 204);
        expect(
          await send(
            'PUT',
            ana,
            body: {'token': 'fcm-2', 'platform': 'android'},
          ),
          204,
        );

        expect(await devices(), [
          ('fcm-1', 'uid-ana', 'web'),
          ('fcm-2', 'uid-ana', 'android'),
        ]);
      });

      test(
        'si el token era de otra cuenta, pasa a la que lo registra',
        () async {
          await send('PUT', authAs('uid-ana'), body: {'token': 'fcm-1'});
          await send(
            'PUT',
            authAs('uid-luis', email: 'luis@example.com'),
            body: {'token': 'fcm-1'},
          );

          expect(await devices(), [('fcm-1', 'uid-luis', null)]);
        },
      );

      test('DELETE quita solo los tokens propios', () async {
        await send('PUT', authAs('uid-ana'), body: {'token': 'fcm-ana'});
        await send(
          'PUT',
          authAs('uid-luis', email: 'luis@example.com'),
          body: {'token': 'fcm-luis'},
        );

        expect(
          await send('DELETE', authAs('uid-ana'), query: '?token=fcm-luis'),
          204,
        );
        expect(
          await send('DELETE', authAs('uid-ana'), query: '?token=fcm-ana'),
          204,
        );

        expect(await devices(), [('fcm-luis', 'uid-luis', null)]);
      });

      test('valida el body y el query, y sin token es 401', () async {
        final ana = authAs('uid-ana');

        expect(await send('PUT', ana, body: {'platform': 'web'}), 400);
        expect(
          await send('PUT', ana, body: {'token': 'x', 'platform': 'ios'}),
          400,
        );
        expect(await send('PUT', ana, body: {'token': 'x', 'otro': 1}), 400);
        expect(await send('DELETE', ana), 400);
        expect(
          await send(
            'PUT',
            {'content-type': 'application/json'},
            body: {'token': 'x'},
          ),
          401,
        );
        expect(await devices(), isEmpty);
      });

      test('GET /users/me guarda si el correo está verificado', () async {
        Future<bool> stored() async => (await User.db.findFirstRow(
          session,
          where: (u) => u.firebaseUid.equals('uid-ana'),
        ))!.emailVerified;

        await getMe(authAs('uid-ana', emailVerified: false));
        expect(await stored(), isFalse);
        await getMe(authAs('uid-ana'));
        expect(await stored(), isTrue);
      });
    });
  });
}
