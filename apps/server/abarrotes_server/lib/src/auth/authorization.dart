import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'firebase_identity.dart';

/// Los permisos de personal de quien hace la petición: su rol y lo que puede
/// hacer. Sin acceso de personal, [none].
class StaffAccess {
  const StaffAccess({
    this.roleId,
    this.roleName,
    this.permissions = const {},
  });

  static const none = StaffAccess();

  final UuidValue? roleId;
  final String? roleName;
  final Set<Permission> permissions;

  bool get isStaff => roleId != null;

  bool can(Permission permission) => permissions.contains(permission);
}

/// Qué puede hacer una persona del personal. Las rutas dependen de esta
/// interfaz (a través de `RequirePermission`), no de dónde se guarda.
abstract interface class AuthorizationService {
  /// El acceso de [identity] (un Firebase ID token ya verificado), leído en
  /// el momento: quitar un permiso rige en la petición siguiente.
  Future<StaffAccess> accessOf(Session session, FirebaseIdentity identity);

  Future<bool> hasPermission(
    Session session,
    FirebaseIdentity identity,
    Permission permission,
  );
}
