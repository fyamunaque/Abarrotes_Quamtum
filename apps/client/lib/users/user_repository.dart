import '../session/session.dart';

/// El perfil de la cuenta en el servidor, con su rol.
abstract interface class UserRepository {
  /// `GET /users/me` con el ID token de Firebase. La primera vez, el servidor
  /// crea la cuenta como cliente. Los errores salen como `AuthFailure`.
  Future<SessionUser> me(String idToken);
}
