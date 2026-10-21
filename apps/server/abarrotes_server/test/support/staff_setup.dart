import 'package:abarrotes_server/src/auth/guards.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/staff/db_authorization_service.dart';
import 'package:abarrotes_server/src/staff/staff_bootstrap.dart';
import 'package:serverpod/serverpod.dart';

import 'http_harness.dart';
import 'test_tokens.dart';

/// Los guards de los tests: tokens firmados con [google] y los permisos de
/// la base, como en `server.dart`.
Guards testGuards(RsaKeyPair google) => Guards(
  verifier: testVerifier(google),
  authorization: const DbAuthorizationService(),
);

/// El rol llamado [name] (los de la siembra: Administrador, Almacenero,
/// Cajera). En una base nueva los crea antes.
Future<Role> roleNamed(Session session, String name) async {
  await const StaffBootstrap().ensureRoles(session);
  return (await Role.db.findFirstRow(
    session,
    where: (role) => role.name.equals(name),
  ))!;
}

/// Un usuario con [uid] (correo `$uid@tienda.pe`, como manda `TestClient`)
/// que además es del personal: con el rol [roleName] (Administrador si no se
/// dice) o con uno armado para el test con [permissions].
Future<User> insertStaff(
  Session session,
  String uid, {
  String roleName = administratorRoleName,
  Set<Permission>? permissions,
}) async {
  final user = await insertUser(session, uid);
  final role = permissions == null
      ? await roleNamed(session, roleName)
      : await Role.db.insertRow(
          session,
          Role(name: 'Rol de $uid', permissions: permissions.toList()),
        );
  await StaffMember.db.insertRow(
    session,
    StaffMember(email: user.email, roleId: role.id!),
  );
  return user;
}
