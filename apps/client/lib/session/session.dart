/// Roles de una cuenta, con los mismos nombres que devuelve el servidor
/// (`GET /users/me` en apps/server).
enum UserRole {
  customer,
  admin,
  staff;

  /// Admin y staff manejan la tienda: entran a /admin.
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
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;

  /// La dirección guardada en el perfil, para proponerla al hacer un pedido.
  final String? address;
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
