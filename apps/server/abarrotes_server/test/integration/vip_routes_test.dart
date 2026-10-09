import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/vip/vip_routes.dart';
import 'package:abarrotes_server/src/vip/vip_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  withServerpod('Rutas de clientes VIP', (sessionBuilder, _) {
    late Session session;
    late TestClient client;
    late User admin;

    setUp(() async {
      session = sessionBuilder.build();
      final server = await serveRoutes(
        () => session,
        vipRoutes(const VipService(), testVerifier(google)),
      );
      client = TestClient(server, google);
      addTearDown(server.close);
      admin = await insertUser(session, 'uid-admin', UserRole.admin);
      await insertUser(session, 'uid-staff', UserRole.staff);
      await insertUser(session, 'uid-cliente', UserRole.customer);
    });

    Future<ApiResult> add(List<Object?> emails, {String as = 'uid-admin'}) =>
        client.post('/vip-customers', {'emails': emails}, as: as);

    Future<VipCustomer> vip(String email) async => (await VipCustomer.db
        .findFirstRow(session, where: (vip) => vip.email.equals(email)))!;

    group('POST /vip-customers', () {
      test(
        'agrega varios correos normalizados y responde el resumen',
        () async {
          final (status, body) = await add([
            ' Ana@Gmail.COM ',
            'ana@gmail.com',
            'luis @tienda.pe',
            'no-es-correo',
            '  ',
            'uid-cliente@tienda.pe',
          ]);

          expect(status, 200);
          expect(body, {
            'added': [
              'ana@gmail.com',
              'luis@tienda.pe',
              'uid-cliente@tienda.pe',
            ],
            'duplicates': ['ana@gmail.com'],
            'invalid': ['no-es-correo', ''],
          });
          final saved = await VipCustomer.db.find(
            session,
            orderBy: (vip) => vip.email,
          );
          expect(saved.map((vip) => vip.email), [
            'ana@gmail.com',
            'luis@tienda.pe',
            'uid-cliente@tienda.pe',
          ]);
          expect(saved.every((vip) => vip.active), isTrue);
          expect(saved.every((vip) => vip.addedByUserId == admin.id), isTrue);
        },
      );

      test('los que ya son VIP activos son duplicados y no se tocan', () async {
        await add(['ana@gmail.com']);
        final before = await vip('ana@gmail.com');

        final (status, body) = await add(['ANA@gmail.com', 'luis@tienda.pe']);

        expect(status, 200);
        expect(body, {
          'added': ['luis@tienda.pe'],
          'duplicates': ['ana@gmail.com'],
          'invalid': <String>[],
        });
        expect((await vip('ana@gmail.com')).toJson(), before.toJson());
      });

      test(
        'un correo dado de baja que vuelve se reactiva y cuenta como agregado',
        () async {
          await add(['ana@gmail.com']);
          final ana = await vip('ana@gmail.com');
          await client.delete('/vip-customers/${ana.id}', as: 'uid-admin');
          final otroAdmin = await insertUser(
            session,
            'uid-admin2',
            UserRole.admin,
          );

          final (status, body) = await add(['ana@gmail.com'], as: 'uid-admin2');

          expect(status, 200);
          expect(body['added'], ['ana@gmail.com']);
          final again = await vip('ana@gmail.com');
          expect(again.id, ana.id);
          expect(again.active, isTrue);
          expect(again.addedByUserId, otroAdmin.id);
          expect(await VipCustomer.db.count(session), 1);
        },
      );

      test(
        'solo inválidos o repetidos: responde el resumen sin guardar nada',
        () async {
          final (status, body) = await add(['x', 'x', '@tienda.pe']);

          expect(status, 200);
          expect(body, {
            'added': <String>[],
            'duplicates': <String>[],
            'invalid': ['x', 'x', '@tienda.pe'],
          });
          expect(await VipCustomer.db.count(session), 0);
        },
      );

      test('valida el body', () async {
        Future<Object?> errorsOf(Object? body) async {
          final (status, response) = await client.post(
            '/vip-customers',
            body,
            as: 'uid-admin',
          );
          expect(status, 400);
          return response['message'];
        }

        expect(await errorsOf(<String, Object?>{}), ['emails es obligatorio']);
        expect(await errorsOf({'emails': <String>[]}), [
          'emails debe tener entre 1 y 500 elementos',
        ]);
        expect(
          await errorsOf({'emails': List.filled(501, 'ana@gmail.com')}),
          ['emails debe tener entre 1 y 500 elementos'],
        );
        expect(
          await errorsOf({
            'emails': ['ana@gmail.com', 7],
            'active': true,
          }),
          [
            'La propiedad active no está permitida',
            'emails[1] debe ser un texto',
          ],
        );
        expect(await VipCustomer.db.count(session), 0);
      });
    });

    group('GET /vip-customers', () {
      setUp(() async {
        await add([
          'carla@tienda.pe',
          'uid-cliente@tienda.pe',
          'ana@gmail.com',
          'beto@gmail.com',
        ]);
        final beto = await vip('beto@gmail.com');
        await client.delete('/vip-customers/${beto.id}', as: 'uid-admin');
      });

      test(
        'lista los activos por correo, con quién los agregó y si tienen cuenta',
        () async {
          final (status, body) = await client.get(
            '/vip-customers',
            as: 'uid-staff',
          );

          expect(status, 200);
          expect(body['meta'], {
            'total': 3,
            'page': 1,
            'limit': 20,
            'totalPages': 1,
          });
          final data = body['data'] as List<Object?>;
          expect(data.map((vip) => (vip as Map)['email']), [
            'ana@gmail.com',
            'carla@tienda.pe',
            'uid-cliente@tienda.pe',
          ]);
          expect(data.map((vip) => (vip as Map)['hasAccount']), [
            false,
            false,
            true,
          ]);
          expect(data.first, {
            'id': isA<String>(),
            'email': 'ana@gmail.com',
            'active': true,
            'createdAt': isA<String>(),
            'hasAccount': false,
            'addedBy': {
              'id': admin.id.toString(),
              'name': 'Usuario uid-admin',
              'email': 'uid-admin@tienda.pe',
            },
          });
        },
      );

      test('busca por correo (sin importar mayúsculas) y pagina', () async {
        final (_, found) = await client.get(
          '/vip-customers?search=%20TIENDA.pe',
          as: 'uid-admin',
        );
        expect((found['data'] as List).map((vip) => vip['email']), [
          'carla@tienda.pe',
          'uid-cliente@tienda.pe',
        ]);

        final (_, page2) = await client.get(
          '/vip-customers?limit=2&page=2',
          as: 'uid-admin',
        );
        expect((page2['data'] as List).map((vip) => vip['email']), [
          'uid-cliente@tienda.pe',
        ]);
        expect(page2['meta']['totalPages'], 2);
      });

      test('includeInactive suma a los dados de baja', () async {
        final (status, body) = await client.get(
          '/vip-customers?includeInactive=true',
          as: 'uid-admin',
        );

        expect(status, 200);
        expect(body['meta']['total'], 4);
        expect(
          (body['data'] as List).map((vip) => [vip['email'], vip['active']]),
          [
            ['ana@gmail.com', true],
            ['beto@gmail.com', false],
            ['carla@tienda.pe', true],
            ['uid-cliente@tienda.pe', true],
          ],
        );
      });

      test('valida el query', () async {
        final (status, body) = await client.get(
          '/vip-customers?includeInactive=si&limit=0&orden=email',
          as: 'uid-admin',
        );

        expect(status, 400);
        expect(body['message'], [
          'La propiedad orden no está permitida',
          'limit debe estar entre 1 y 100',
          'includeInactive debe ser true o false',
        ]);
      });
    });

    group('DELETE /vip-customers/:id', () {
      test('lo da de baja sin borrarlo', () async {
        await add(['uid-cliente@tienda.pe']);
        final cliente = await vip('uid-cliente@tienda.pe');

        final (status, body) = await client.delete(
          '/vip-customers/${cliente.id}',
          as: 'uid-admin',
        );

        expect(status, 200);
        expect(body, containsPair('active', false));
        expect(body, containsPair('hasAccount', true));
        expect(body['addedBy']['id'], admin.id.toString());
        expect((await vip('uid-cliente@tienda.pe')).active, isFalse);

        // Darlo de baja otra vez no es error.
        final (again, _) = await client.delete(
          '/vip-customers/${cliente.id}',
          as: 'uid-admin',
        );
        expect(again, 200);
      });

      test('404 si no existe y 400 si el id no es un UUID', () async {
        final (missing, _) = await client.delete(
          '/vip-customers/${const Uuid().v7()}',
          as: 'uid-admin',
        );
        final (invalid, _) = await client.delete(
          '/vip-customers/123',
          as: 'uid-admin',
        );

        expect(missing, 404);
        expect(invalid, 400);
      });
    });

    group('permisos', () {
      test('staff solo lee: 403 al agregar o dar de baja', () async {
        await add(['ana@gmail.com']);
        final ana = await vip('ana@gmail.com');

        final (list, _) = await client.get('/vip-customers', as: 'uid-staff');
        final (post, _) = await add(['luis@tienda.pe'], as: 'uid-staff');
        final (delete, _) = await client.delete(
          '/vip-customers/${ana.id}',
          as: 'uid-staff',
        );

        expect(list, 200);
        expect(post, 403);
        expect(delete, 403);
        expect((await vip('ana@gmail.com')).active, isTrue);
        expect(await VipCustomer.db.count(session), 1);
      });

      test('un cliente recibe 403 y sin token es 401', () async {
        final (customer, _) = await client.get(
          '/vip-customers',
          as: 'uid-cliente',
        );
        final (anonymous, _) = await client.get('/vip-customers');
        final (anonymousPost, _) = await client.post('/vip-customers', {
          'emails': ['ana@gmail.com'],
        });

        expect(customer, 403);
        expect(anonymous, 401);
        expect(anonymousPost, 401);
      });
    });
  });
}
