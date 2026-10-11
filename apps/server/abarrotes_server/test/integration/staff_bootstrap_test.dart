import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/staff/staff_bootstrap.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Arranque del personal', (sessionBuilder, _) {
    late Session session;
    const bootstrap = StaffBootstrap();

    setUp(() => session = sessionBuilder.build());

    Future<StaffMember?> member(String email) => StaffMember.db.findFirstRow(
      session,
      where: (m) => m.email.equals(email),
      include: StaffMember.include(role: Role.include()),
    );

    test(
      'en una base sin roles crea el Administrador y las plantillas',
      () async {
        // Como una base nueva (dentro de la transacción del test).
        await StaffMember.db.deleteWhere(
          session,
          where: (_) => Constant.bool(true),
        );
        await Role.db.deleteWhere(session, where: (_) => Constant.bool(true));

        final system = await bootstrap.ensureRoles(session);

        expect(system.name, administratorRoleName);
        expect(system.isSystem, isTrue);
        final names = {
          for (final role in await Role.db.find(session)) role.name,
        };
        expect(names, {administratorRoleName, 'Almacenero', 'Cajera'});
      },
    );

    test(
      'el primer administrador: normalizado, una sola vez y anotado',
      () async {
        expect(
          await bootstrap.seedFirstAdmin(session, '  Frank@Gmail.COM '),
          isTrue,
        );
        expect(
          await bootstrap.seedFirstAdmin(session, 'frank@gmail.com'),
          isFalse,
        );

        final frank = (await member('frank@gmail.com'))!;
        expect(frank.active, isTrue);
        expect(frank.role!.isSystem, isTrue);
        expect(frank.addedByUserId, isNull);
        final entry = (await AuditLog.db.find(session)).single;
        expect(entry.action, AuditAction.staffSeeded);
        expect(entry.actorUserId, isNull);
        expect(entry.targetEmail, 'frank@gmail.com');
      },
    );

    test(
      'no revive a uno que un admin dio de baja ni le cambia el rol',
      () async {
        await bootstrap.ensureRoles(session);
        final cajera = (await Role.db.findFirstRow(
          session,
          where: (role) => role.name.equals('Cajera'),
        ))!;
        await StaffMember.db.insertRow(
          session,
          StaffMember(
            email: 'frank@gmail.com',
            roleId: cajera.id!,
            active: false,
          ),
        );

        expect(
          await bootstrap.seedFirstAdmin(session, 'frank@gmail.com'),
          isFalse,
        );

        final frank = (await member('frank@gmail.com'))!;
        expect((frank.active, frank.role!.name), (false, 'Cajera'));
        expect(await AuditLog.db.count(session), 0);
      },
    );

    test('un correo inválido no agrega a nadie', () async {
      await expectLater(
        bootstrap.seedFirstAdmin(session, 'no-es-correo'),
        throwsArgumentError,
      );
      expect(await member('no-es-correo'), isNull);
    });
  });
}
