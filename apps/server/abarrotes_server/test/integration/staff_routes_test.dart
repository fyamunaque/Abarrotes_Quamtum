import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:abarrotes_server/src/generated/protocol.dart'
    hide AuditLogRepository;
import 'package:abarrotes_server/src/staff/audit_log_repository.dart';
import 'package:abarrotes_server/src/staff/roles_service.dart';
import 'package:abarrotes_server/src/staff/staff_bootstrap.dart';
import 'package:abarrotes_server/src/staff/staff_routes.dart';
import 'package:abarrotes_server/src/staff/staff_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/staff_setup.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  withServerpod('Rutas de roles y personal', (sessionBuilder, _) {
    late Session session;
    late TestClient client;
    late User admin;
    late Role cajera;

    setUp(() async {
      session = sessionBuilder.build();
      final server = await serveRoutes(
        () => session,
        staffRoutes(
          roles: const RolesService(),
          staff: const StaffService(),
          audit: const DbAuditLogRepository(),
          guards: testGuards(google),
        ),
      );
      client = TestClient(server, google);
      addTearDown(server.close);
      admin = await insertStaff(session, 'uid-admin');
      await insertStaff(session, 'uid-cajera', roleName: 'Cajera');
      cajera = await roleNamed(session, 'Cajera');
    });

    Future<StaffMember> member(String email) async => (await StaffMember.db
        .findFirstRow(session, where: (m) => m.email.equals(email)))!;

    Future<List<(String, String?)>> audit() async => [
      for (final entry in await AuditLog.db.find(
        session,
        orderByList: (log) => [log.createdAt.asc(), log.id.asc()],
      ))
        (entry.action.name, entry.targetEmail),
    ];

    group('roles', () {
      test(
        'GET lista el de sistema primero, con permisos y personas',
        () async {
          final (status, body) = await client.get(
            '/staff/roles',
            as: 'uid-admin',
          );

          expect(status, 200);
          final roles = body['data'] as List;
          expect(roles.first, {
            'id': isA<String>(),
            'name': administratorRoleName,
            'permissions': hasLength(Permission.values.length),
            'isSystem': true,
            'active': true,
            'members': 1,
            'createdAt': isA<String>(),
          });
          final byName = {for (final role in roles) role['name']: role};
          expect(byName['Cajera']['permissions'], [
            'products.view',
            'orders.view',
            'orders.updateStatus',
            'customers.view',
          ]);
          expect(byName['Cajera']['members'], 1);
          expect(byName['Almacenero']['isSystem'], isFalse);
        },
      );

      test('POST crea un rol y lo anota en la bitácora', () async {
        final (status, body) = await client.post('/staff/roles', {
          'name': '  Repartidor  ',
          'permissions': ['orders.updateStatus', 'orders.view'],
        }, as: 'uid-admin');

        expect(status, 201);
        expect(body['name'], 'Repartidor');
        // En el orden del catálogo.
        expect(body['permissions'], ['orders.view', 'orders.updateStatus']);
        expect(body['members'], 0);
        final entry = (await AuditLog.db.find(session)).single;
        expect(entry.action, AuditAction.roleCreated);
        expect(entry.actorUserId, admin.id);
        expect(entry.details, contains('Repartidor'));
      });

      test('valida el nombre y los permisos', () async {
        Future<ApiResult> create(Map<String, Object?> body) =>
            client.post('/staff/roles', body, as: 'uid-admin');

        final repeated = await create({
          'name': 'cajera',
          'permissions': ['orders.view'],
        });
        expect(repeated.$1, 409);
        expect(repeated.$2['message'], 'Ya existe un rol llamado cajera');

        final (status, body) = await create({
          'name': 'Raro',
          'permissions': ['orders.view', 'orders.delete'],
          'isSystem': true,
        });
        expect(status, 400);
        expect(body['message'], [
          'La propiedad isSystem no está permitida',
          'permissions[1]: "orders.delete" no es un permiso',
        ]);

        final empty = await create({'name': 'Vacío', 'permissions': []});
        expect(empty.$1, 400);
        expect(await AuditLog.db.count(session), 0);
      });

      test('PATCH edita nombre, permisos y si está activo', () async {
        final (status, body) = await client.patch('/staff/roles/${cajera.id}', {
          'name': 'Caja',
          'permissions': ['orders.view'],
          'active': false,
        }, as: 'uid-admin');

        expect(status, 200);
        expect(body['name'], 'Caja');
        expect(body['permissions'], ['orders.view']);
        expect(body['active'], isFalse);
        final entry = (await AuditLog.db.find(session)).single;
        expect(entry.action, AuditAction.roleUpdated);
        expect(entry.details, contains('"from":"Cajera"'));

        // Con el rol inactivo, la cajera ya no tiene permisos.
        final (forbidden, _) = await client.get(
          '/staff/roles',
          as: 'uid-cajera',
        );
        expect(forbidden, 403);
      });

      test('el rol de sistema no se edita ni se borra', () async {
        final system = await roleNamed(session, administratorRoleName);

        final edit = await client.patch('/staff/roles/${system.id}', {
          'permissions': ['orders.view'],
        }, as: 'uid-admin');
        final delete = await client.delete(
          '/staff/roles/${system.id}',
          as: 'uid-admin',
        );

        expect(edit.$1, 409);
        expect(edit.$2['message'], contains('es del sistema'));
        expect(delete.$1, 409);
        expect(await AuditLog.db.count(session), 0);
      });

      test('DELETE solo un rol sin personal (ni dado de baja)', () async {
        final withStaff = await client.delete(
          '/staff/roles/${cajera.id}',
          as: 'uid-admin',
        );
        expect(withStaff.$1, 409);
        expect(withStaff.$2['message'], contains('1 persona asignada'));

        await StaffMember.db.updateWhere(
          session,
          columnValues: (m) => [m.active(false)],
          where: (m) => m.email.equals('uid-cajera@tienda.pe'),
        );
        expect(
          (await client.delete(
            '/staff/roles/${cajera.id}',
            as: 'uid-admin',
          )).$1,
          409,
        );

        final (_, created) = await client.post('/staff/roles', {
          'name': 'Temporal',
          'permissions': ['stats.view'],
        }, as: 'uid-admin');
        expect(
          await client.delete(
            '/staff/roles/${created['id']}',
            as: 'uid-admin',
          ),
          (204, null),
        );
        expect(
          (await client.get(
            '/staff/roles/${created['id']}',
            as: 'uid-admin',
          )).$1,
          404,
        );
        expect((await audit()).map((e) => e.$1), [
          'roleCreated',
          'roleDeleted',
        ]);
      });
    });

    group('personal', () {
      Future<ApiResult> add(List<Object?> emails, Role role) => client.post(
        '/staff/members',
        {'emails': emails, 'roleId': role.id.toString()},
        as: 'uid-admin',
      );

      test('agrega varios correos con un rol y responde el resumen', () async {
        final (status, body) = await add([
          ' Luis@Tienda.PE ',
          'luis@tienda.pe',
          'uid-cajera@tienda.pe',
          'no-es-correo',
          'maria@tienda.pe',
        ], cajera);

        expect(status, 200);
        expect(body, {
          'added': ['luis@tienda.pe', 'maria@tienda.pe'],
          'duplicates': ['luis@tienda.pe', 'uid-cajera@tienda.pe'],
          'invalid': ['no-es-correo'],
        });
        final luis = await member('luis@tienda.pe');
        expect(luis.roleId, cajera.id);
        expect(luis.addedByUserId, admin.id);
        expect(await audit(), [
          ('staffAdded', 'luis@tienda.pe'),
          ('staffAdded', 'maria@tienda.pe'),
        ]);
      });

      test('un correo dado de baja vuelve con el rol nuevo', () async {
        final almacenero = await roleNamed(session, 'Almacenero');
        await StaffMember.db.updateWhere(
          session,
          columnValues: (m) => [m.active(false)],
          where: (m) => m.email.equals('uid-cajera@tienda.pe'),
        );

        final (_, body) = await add(['uid-cajera@tienda.pe'], almacenero);

        expect(body['added'], ['uid-cajera@tienda.pe']);
        final again = await member('uid-cajera@tienda.pe');
        expect((again.active, again.roleId), (true, almacenero.id));
        expect(await audit(), [('staffReactivated', 'uid-cajera@tienda.pe')]);
      });

      test('no se asigna un rol inactivo ni uno que no existe', () async {
        await Role.db.updateRow(session, cajera.copyWith(active: false));

        final inactive = await add(['luis@tienda.pe'], cajera);
        final (missing, _) = await client.post('/staff/members', {
          'emails': ['luis@tienda.pe'],
          'roleId': '0199a000-0000-7000-8000-000000000000',
        }, as: 'uid-admin');

        expect(inactive.$1, 409);
        expect(inactive.$2['message'], contains('está inactivo'));
        expect(missing, 400);
      });

      test('GET busca, pagina y dice si el correo ya tiene cuenta', () async {
        await add(['zoe@tienda.pe'], cajera);

        final (status, body) = await client.get(
          '/staff/members?search=TIENDA.PE&limit=2',
          as: 'uid-admin',
        );

        expect(status, 200);
        expect(body['meta']['total'], 3);
        final [first, second] = body['data'] as List;
        expect(first, {
          'id': isA<String>(),
          'email': 'uid-admin@tienda.pe',
          'active': true,
          'createdAt': isA<String>(),
          'hasAccount': true,
          'role': {'id': isA<String>(), 'name': administratorRoleName},
          'addedBy': null,
        });
        expect(second['email'], 'uid-cajera@tienda.pe');
        final (_, page2) = await client.get(
          '/staff/members?search=tienda&limit=2&page=2',
          as: 'uid-admin',
        );
        final zoe = (page2['data'] as List).single;
        expect(zoe['email'], 'zoe@tienda.pe');
        expect(zoe['hasAccount'], isFalse);
        expect(zoe['addedBy']['id'], admin.id.toString());
      });

      test('PATCH cambia el rol y lo anota con el de antes', () async {
        final cajeraMember = await member('uid-cajera@tienda.pe');
        final almacenero = await roleNamed(session, 'Almacenero');

        final (status, body) = await client.patch(
          '/staff/members/${cajeraMember.id}',
          {'roleId': almacenero.id.toString()},
          as: 'uid-admin',
        );

        expect(status, 200);
        expect(body['role']['name'], 'Almacenero');
        final entry = (await AuditLog.db.find(session)).single;
        expect(entry.action, AuditAction.staffRoleChanged);
        expect(entry.details, '{"from":"Cajera","to":"Almacenero"}');
      });

      test('nadie se cambia el rol ni se da de baja a sí mismo', () async {
        final self = await member('uid-admin@tienda.pe');

        final change = await client.patch('/staff/members/${self.id}', {
          'roleId': cajera.id.toString(),
        }, as: 'uid-admin');
        final leave = await client.delete(
          '/staff/members/${self.id}',
          as: 'uid-admin',
        );

        expect(change.$1, 409);
        expect(change.$2['message'], 'No puedes cambiar tu propio rol');
        expect(leave.$1, 409);
        expect(leave.$2['message'], 'No puedes darte de baja a ti mismo');
      });

      test(
        'no se quita ni se degrada al último Administrador activo',
        () async {
          // Una gerente con staff.manage, pero sin el rol de sistema.
          await insertStaff(
            session,
            'uid-gerente',
            permissions: {Permission.staffManage},
          );
          final onlyAdmin = await member('uid-admin@tienda.pe');

          final demote = await client.patch('/staff/members/${onlyAdmin.id}', {
            'roleId': cajera.id.toString(),
          }, as: 'uid-gerente');
          final remove = await client.delete(
            '/staff/members/${onlyAdmin.id}',
            as: 'uid-gerente',
          );

          expect(demote.$1, 409);
          expect(demote.$2['message'], contains('es el último Administrador'));
          expect(remove.$1, 409);
          expect((await member('uid-admin@tienda.pe')).active, isTrue);

          // Con otro Administrador, sí.
          await insertStaff(session, 'uid-admin2');
          final (status, body) = await client.delete(
            '/staff/members/${onlyAdmin.id}',
            as: 'uid-gerente',
          );
          expect(status, 200);
          expect(body['active'], isFalse);
        },
      );

      test(
        'DELETE da de baja: pierde el acceso en la petición siguiente',
        () async {
          await insertStaff(
            session,
            'uid-gerente',
            permissions: {Permission.staffManage},
          );
          expect(
            (await client.get('/staff/roles', as: 'uid-gerente')).$1,
            200,
          );
          final gerente = await member('uid-gerente@tienda.pe');

          final (status, body) = await client.delete(
            '/staff/members/${gerente.id}',
            as: 'uid-admin',
          );

          expect(status, 200);
          expect(body['active'], isFalse);
          expect(
            (await client.get('/staff/roles', as: 'uid-gerente')).$1,
            403,
          );
          expect(await audit(), [
            ('staffDeactivated', 'uid-gerente@tienda.pe'),
          ]);
          // Otra vez no es error ni se anota de nuevo.
          expect(
            (await client.delete(
              '/staff/members/${gerente.id}',
              as: 'uid-admin',
            )).$1,
            200,
          );
          expect(await AuditLog.db.count(session), 1);
        },
      );
    });

    test('la bitácora: lo más reciente primero, con quién lo hizo', () async {
      await client.post('/staff/members', {
        'emails': ['luis@tienda.pe'],
        'roleId': cajera.id.toString(),
      }, as: 'uid-admin');
      final luis = await member('luis@tienda.pe');
      await client.delete('/staff/members/${luis.id}', as: 'uid-admin');

      final (status, body) = await client.get('/staff/audit', as: 'uid-admin');

      expect(status, 200);
      final [latest, first] = body['data'] as List;
      expect(latest, {
        'id': isA<String>(),
        'action': 'staffDeactivated',
        'targetEmail': 'luis@tienda.pe',
        'details': {'role': 'Cajera'},
        'createdAt': isA<String>(),
        'actor': {
          'id': admin.id.toString(),
          'name': 'Usuario uid-admin',
          'email': 'uid-admin@tienda.pe',
        },
      });
      expect(first['action'], 'staffAdded');
    });

    test('todo /staff pide staff.manage', () async {
      final cajeraMember = await member('uid-cajera@tienda.pe');
      await insertUser(session, 'uid-cliente');

      for (final as in ['uid-cajera', 'uid-cliente']) {
        expect((await client.get('/staff/roles', as: as)).$1, 403);
        expect((await client.get('/staff/members', as: as)).$1, 403);
        expect((await client.get('/staff/audit', as: as)).$1, 403);
        expect(
          (await client.delete(
            '/staff/members/${cajeraMember.id}',
            as: as,
          )).$1,
          403,
        );
      }
      expect((await client.get('/staff/roles')).$1, 401);
      // Un Administrador sin el correo verificado tampoco.
      expect(
        (await client.get(
          '/staff/roles',
          as: 'uid-admin',
          emailVerified: false,
        )).$1,
        403,
      );
    });
  });

  // Sin rollback: cada sesión usa su propia conexión, como dos peticiones
  // reales. La base temporal del grupo se borra al terminar.
  withServerpod(
    'Dos bajas de Administradores a la vez',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, _) {
      test('no dejan la tienda sin ninguno: una sola pasa', () async {
        final setup = sessionBuilder.build();
        final ana = await insertStaff(setup, 'uid-ana');
        final luis = await insertStaff(setup, 'uid-luis');
        Future<StaffMember> memberOf(User user) async =>
            (await StaffMember.db.findFirstRow(
              setup,
              where: (m) => m.email.equals(user.email),
            ))!;
        final anaMember = await memberOf(ana);
        final luisMember = await memberOf(luis);

        Future<Object> deactivate(StaffMember target, User actor) =>
            const StaffService()
                .deactivate(
                  sessionBuilder.build(),
                  target.id!,
                  actor: (user: actor, email: actor.email),
                )
                .then<Object>(
                  (item) => item.member.active,
                  onError: (Object e) => e is ApiException ? e.statusCode : e,
                );

        final results = await Future.wait([
          deactivate(luisMember, ana),
          deactivate(anaMember, luis),
        ]);

        expect(results, unorderedEquals([false, 409]));
        final active = await StaffMember.db.count(
          setup,
          where: (m) => m.active.equals(true),
        );
        expect(active, 1);
      });
    },
  );
}
