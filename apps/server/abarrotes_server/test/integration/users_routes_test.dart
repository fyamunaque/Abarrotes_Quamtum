import 'dart:convert';

import 'package:abarrotes_server/src/auth/firebase_auth_middleware.dart';
import 'package:abarrotes_server/src/common/customer_requirements.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/users/users_routes.dart';
import 'package:abarrotes_server/src/users/users_service.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/staff_setup.dart';
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
      final guards = testGuards(google);
      // Las mismas rutas (y guards) que addUsersRoutes, con la sesión del test.
      server = await serveRoutes(
        () => session,
        usersRoutes(const UsersService(), guards, shoppers: testShoppers),
        middleware: {'/users': firebaseAuthMiddleware(guards.verifier)},
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

    /// Hace del personal a [email], con el rol [roleName].
    Future<void> grantStaff(String email, String roleName) async =>
        StaffMember.db.insertRow(
          session,
          StaffMember(
            email: email,
            roleId: (await roleNamed(session, roleName)).id!,
          ),
        );

    Future<(int, dynamic)> getMe(Map<String, String> headers) async {
      final response = await http.get(url('/users/me'), headers: headers);
      return (response.statusCode, jsonDecode(response.body));
    }

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
          'dni': null,
          'termsVersion': null,
          'termsAcceptedAt': null,
          'profileComplete': false,
          'createdAt': isA<String>(),
          'isVip': false,
          'staffRole': null,
          'permissions': <String>[],
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

      group('personal', () {
        test('una Cajera: su rol, sus permisos y role staff', () async {
          await grantStaff('luis@tienda.pe', 'Cajera');

          final (status, body) = await getMe(
            authAs('uid-luis', email: 'Luis@Tienda.pe'),
          );

          expect(status, 200);
          expect(body['role'], 'staff');
          expect(body['staffRole'], {
            'id': isA<String>(),
            'name': 'Cajera',
          });
          expect(body['permissions'], [
            'products.view',
            'orders.view',
            'orders.updateStatus',
            'customers.view',
          ]);
        });

        test('el Administrador: role admin y todos los permisos', () async {
          await grantStaff('luis@tienda.pe', 'Administrador');

          final (_, body) = await getMe(
            authAs('uid-luis', email: 'luis@tienda.pe'),
          );

          expect(body['role'], 'admin');
          expect(body['staffRole']['name'], 'Administrador');
          expect(body['permissions'], hasLength(Permission.values.length));
          expect(body['permissions'], contains('staff.manage'));
        });

        test('sin verificar el correo no hay permisos de personal', () async {
          await grantStaff('luis@tienda.pe', 'Administrador');

          final (_, body) = await getMe(
            authAs('uid-luis', email: 'luis@tienda.pe', emailVerified: false),
          );

          expect(body['role'], 'customer');
          expect(body['staffRole'], isNull);
          expect(body['permissions'], isEmpty);
        });

        test('dado de baja, deja de serlo en la petición siguiente', () async {
          await grantStaff('luis@tienda.pe', 'Cajera');
          final headers = authAs('uid-luis', email: 'luis@tienda.pe');
          expect((await getMe(headers)).$2['role'], 'staff');

          await StaffMember.db.updateWhere(
            session,
            columnValues: (member) => [member.active(false)],
            where: (member) => member.email.equals('luis@tienda.pe'),
          );

          final (_, body) = await getMe(headers);
          expect(body['role'], 'customer');
          expect(body['permissions'], isEmpty);
        });
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
        await insertUser(session, 'uid-otra', email: 'ana@example.com');

        final (status, _) = await getMe(authAs('uid-ana'));

        expect(status, 409);
      });

      test('sin token responde 401', () async {
        final response = await http.get(url('/users/me'));

        expect(response.statusCode, 401);
      });

      group('isVip', () {
        setUp(() async {
          final admin = await insertUser(session, 'uid-admin');
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

    group('PATCH /users/me', () {
      Future<(int, dynamic)> patchMe(
        Object? body, {
        String uid = 'uid-ana',
        String email = 'ana@example.com',
      }) async {
        final response = await http.patch(
          url('/users/me'),
          headers: authAs(uid, email: email),
          body: jsonEncode(body),
        );
        return (response.statusCode, jsonDecode(response.body));
      }

      Future<User> stored(String uid) async => (await User.db.findFirstRow(
        session,
        where: (u) => u.firebaseUid.equals(uid),
      ))!;

      test('guarda el celular normalizado, el DNI y los términos', () async {
        final (status, body) = await patchMe({
          'phone': '+51 987-654-321',
          'dni': '45678912',
          'acceptTerms': currentTermsVersion,
        });

        expect(status, 200);
        expect(body['phone'], '987654321');
        expect(body['dni'], '45678912');
        expect(body['termsVersion'], currentTermsVersion);
        expect(body['termsAcceptedAt'], isA<String>());
        expect(body['profileComplete'], isTrue);
        // Responde la cuenta completa, como GET /users/me.
        expect(body['role'], 'customer');
        expect(body['permissions'], <String>[]);

        final user = await stored('uid-ana');
        expect(user.phone, '987654321');
        expect(user.dni, '45678912');
        expect(user.termsAcceptedAt, isNotNull);
      });

      test('lo que no viene queda igual; dni null lo borra', () async {
        await patchMe({
          'phone': '987654321',
          'dni': '45678912',
          'acceptTerms': currentTermsVersion,
        });

        final (_, kept) = await patchMe({'phone': '912345678'});
        expect(kept['dni'], '45678912');
        expect(kept['profileComplete'], isTrue);

        final (status, cleared) = await patchMe({'dni': null});
        expect(status, 200);
        expect(cleared['dni'], isNull);
        expect(cleared['phone'], '912345678');
        expect((await stored('uid-ana')).dni, isNull);
      });

      test(
        'sin celular o sin los términos, el perfil no está completo',
        () async {
          final (_, phoneOnly) = await patchMe({'phone': '987654321'});
          expect(phoneOnly['profileComplete'], isFalse);

          final (_, fresh) = await getMe(
            authAs('uid-luz', email: 'luz@tienda.pe'),
          );
          expect(fresh['profileComplete'], isFalse);
          expect(fresh['termsVersion'], isNull);
        },
      );

      test('celular, DNI o términos inválidos: 400 y no guarda nada', () async {
        final (status, body) = await patchMe({
          'phone': '812345678',
          'dni': '1234567',
          'acceptTerms': '2020-01-01',
        });

        expect(status, 400);
        expect(body['message'], [
          'El celular tiene que tener 9 dígitos y empezar con 9.',
          'El DNI tiene que tener 8 dígitos.',
          'Los términos cambiaron: actualiza la app y vuelve a aceptarlos.',
        ]);
        expect(await User.db.count(session), 0);

        final (unknown, _) = await patchMe({'role': 'admin'});
        expect(unknown, 400);
      });

      test('un DNI de otra cuenta: 409', () async {
        await patchMe({'dni': '45678912'});

        final (status, body) = await patchMe(
          {
            'dni': '45678912',
          },
          uid: 'uid-luz',
          email: 'luz@tienda.pe',
        );

        expect(status, 409);
        expect(body['message'], 'Ese DNI ya está registrado en otra cuenta.');
        expect((await stored('uid-luz')).dni, isNull);
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
