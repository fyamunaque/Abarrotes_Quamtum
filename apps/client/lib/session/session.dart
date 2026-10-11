import 'package:flutter/foundation.dart';

import 'staff_permission.dart';

/// Roles de una cuenta, con los mismos nombres que devuelve el servidor
/// (`GET /users/me` en apps/server, derivado de los permisos: admin con
/// `staff.manage`, staff con algún otro). Lo fino va en
/// [SessionUser.permissions].
enum UserRole {
  customer,
  admin,
  staff;

  /// Admin y staff manejan la tienda: entran a /admin.
  bool get isStaff => this == admin || this == staff;

  /// Solo admin cambia quién accede a qué (p. ej. los clientes VIP); staff
  /// lo ve en modo lectura.
  bool get isAdmin => this == admin;
}

/// La cuenta con la que se inició sesión.
class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.address,
    this.isVip = false,
    this.emailVerified = true,
    this.staffRoleName,
    this.permissions = const {},
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;

  /// La dirección guardada en el perfil, para proponerla al hacer un pedido.
  final String? address;

  /// Si puede usar las promociones VIP. Lo decide el servidor (VIP activo y
  /// correo verificado): la app solo lo lee.
  final bool isVip;

  /// Si la persona confirmó su correo en Firebase.
  final bool emailVerified;

  /// El nombre de su rol en el equipo ("Cajera"), o null si no es del
  /// personal.
  final String? staffRoleName;

  /// Lo que puede hacer en el panel. Lo decide el servidor (vacío si no es
  /// del personal o no verificó el correo): la app solo muestra u oculta, y
  /// el servidor vuelve a revisar cada acción.
  final Set<StaffPermission> permissions;

  bool can(StaffPermission permission) => permissions.contains(permission);

  SessionUser copyWith({bool? isVip, bool? emailVerified}) => SessionUser(
    id: id,
    name: name,
    email: email,
    role: role,
    address: address,
    isVip: isVip ?? this.isVip,
    emailVerified: emailVerified ?? this.emailVerified,
    staffRoleName: staffRoleName,
    permissions: permissions,
  );

  @override
  bool operator ==(Object other) =>
      other is SessionUser &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.role == role &&
      other.address == address &&
      other.isVip == isVip &&
      other.emailVerified == emailVerified &&
      other.staffRoleName == staffRoleName &&
      setEquals(other.permissions, permissions);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    email,
    role,
    address,
    isVip,
    emailVerified,
    staffRoleName,
    Object.hashAllUnordered(permissions),
  );
}

/// Quién usa la app: nadie ([SignedOut]) o una cuenta ([SignedIn]). Al
/// arrancar es [SessionLoading] hasta saber si quedó una cuenta abierta.
sealed class Session {
  const Session();
}

final class SessionLoading extends Session {
  const SessionLoading();
}

final class SignedOut extends Session {
  const SignedOut();
}

final class SignedIn extends Session {
  const SignedIn(this.user);

  final SessionUser user;
}
