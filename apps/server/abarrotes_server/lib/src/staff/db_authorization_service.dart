import 'package:serverpod/serverpod.dart';

import '../auth/authorization.dart';
import '../auth/firebase_identity.dart';
import '../common/emails.dart';
import '../generated/protocol.dart';
import 'permissions.dart';
import 'staff_repository.dart';

/// [AuthorizationService] con la base: el correo del token en el personal
/// activo, con su rol activo, y el correo verificado (`email_verified`). Si
/// algo no se cumple, no hay permisos de personal. Se lee en cada petición,
/// sin caché.
class DbAuthorizationService implements AuthorizationService {
  const DbAuthorizationService({this._staff = const DbStaffRepository()});

  final StaffRepository _staff;

  @override
  Future<StaffAccess> accessOf(
    Session session,
    FirebaseIdentity identity,
  ) async {
    final email = identity.email;
    // Sin verificar, cualquiera podría crear una cuenta con el correo de
    // alguien del personal.
    if (email == null || !identity.emailVerified) return StaffAccess.none;
    final member = await _staff.findActiveByEmail(
      session,
      normalizeEmail(email),
    );
    final role = member?.role;
    if (role == null || !role.active) return StaffAccess.none;
    return StaffAccess(
      roleId: role.id,
      roleName: role.name,
      permissions: effectivePermissions(role),
    );
  }

  @override
  Future<bool> hasPermission(
    Session session,
    FirebaseIdentity identity,
    Permission permission,
  ) async => (await accessOf(session, identity)).can(permission);
}
