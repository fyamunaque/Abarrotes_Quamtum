import '../session/session.dart';

/// El perfil de la cuenta en el servidor, con su rol.
abstract interface class UserRepository {
  /// `GET /users/me` con el ID token de Firebase. La primera vez, el servidor
  /// crea la cuenta como cliente. Los errores salen como `AuthFailure`.
  Future<SessionUser> me(String idToken);

  /// `PATCH /users/me`: el celular ([phone]), el DNI ([dni]; con [clearDni],
  /// lo borra) y, con [acceptTerms], la aceptación de los términos vigentes
  /// (`termsVersion` de legal/legal_texts.dart). Lo que no viene queda igual.
  /// Devuelve la cuenta actualizada. Los errores salen como `ApiFailure`, con
  /// el mensaje del servidor (p. ej. 409 si el DNI ya está en otra cuenta).
  Future<SessionUser> updateProfile(
    String idToken, {
    String? phone,
    String? dni,
    bool clearDni = false,
    bool acceptTerms = false,
  });
}
