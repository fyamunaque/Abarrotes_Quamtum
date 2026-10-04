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
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
}

/// Quién usa la app: nadie ([SignedOut]) o una cuenta ([SignedIn]).
sealed class Session {
  const Session();
}

final class SignedOut extends Session {
  const SignedOut();
}

final class SignedIn extends Session {
  const SignedIn(this.user);

  final SessionUser user;
}
