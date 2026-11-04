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

  /// Admin y staff son del personal: entran a /admin, cada uno a las
  /// secciones de sus permisos.
  bool get isStaff => this == admin || this == staff;
}

/// La cuenta con la que se inició sesión.
class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.address,
    this.phone,
    this.dni,
    this.termsVersion,
    this.termsAcceptedAt,
    this.profileComplete = true,
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

  /// El celular (9 dígitos), que hace falta para pedir.
  final String? phone;

  /// El DNI (8 dígitos), opcional: la tienda lo usa para confirmar quién
  /// recibe o recoge un pedido.
  final String? dni;

  /// La versión de los términos y la política de privacidad que aceptó, y
  /// cuándo (ver legal/legal_texts.dart).
  final String? termsVersion;
  final DateTime? termsAcceptedAt;

  /// Si tiene lo que pide un pedido además del correo confirmado: el celular
  /// y los términos vigentes. Lo calcula el servidor.
  final bool profileComplete;

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
    phone: phone,
    dni: dni,
    termsVersion: termsVersion,
    termsAcceptedAt: termsAcceptedAt,
    profileComplete: profileComplete,
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
      other.phone == phone &&
      other.dni == dni &&
      other.termsVersion == termsVersion &&
      other.termsAcceptedAt == termsAcceptedAt &&
      other.profileComplete == profileComplete &&
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
    phone,
    dni,
    termsVersion,
    termsAcceptedAt,
    profileComplete,
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
