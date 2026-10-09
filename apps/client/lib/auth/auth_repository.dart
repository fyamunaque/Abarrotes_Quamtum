/// Las cuentas de Firebase: registrarse, ingresar y el ID token que el
/// servidor pide en `Authorization: Bearer`. El rol no está aquí: lo da el
/// servidor (ver `UserRepository`).
abstract interface class AuthRepository {
  /// El uid de la cuenta cada vez que cambia (null: sin cuenta). Al
  /// suscribirse emite el estado actual, p. ej. la cuenta que quedó abierta.
  Stream<String?> accountChanges();

  /// Ingresa y devuelve el uid.
  Future<String> signIn({required String email, required String password});

  /// Crea la cuenta con su nombre, queda ingresada y devuelve el uid. Al
  /// volver, el ID token ya trae el nombre.
  Future<String> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// El ID token de la cuenta actual. Firebase lo renueva antes de que venza.
  Future<String> idToken();

  /// Si la cuenta actual confirmó su correo (false sin cuenta). Con [reload],
  /// lo vuelve a preguntar a Firebase y, si se acaba de confirmar, renueva el
  /// ID token: el servidor lo lee de ahí (`email_verified`).
  Future<bool> emailVerified({bool reload = false});

  /// Manda el correo para confirmar la cuenta actual.
  Future<void> sendEmailVerification();
}

/// Un error que se le muestra a la persona, ya en español.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}
