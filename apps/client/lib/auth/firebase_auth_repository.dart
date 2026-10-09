import 'package:firebase_auth/firebase_auth.dart';

import 'auth_repository.dart';

/// [AuthRepository] con Firebase Auth (email y contraseña). El SDK guarda la
/// cuenta de forma segura en cada plataforma y renueva el ID token solo.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<String?> accountChanges() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<String> signIn({required String email, required String password}) =>
      _guard(() async {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return credential.user!.uid;
      });

  @override
  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) => _guard(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(name.trim());
    // El token de la cuenta recién creada no trae el nombre; uno nuevo sí. El
    // servidor crea el usuario con el nombre del token (GET /users/me).
    await user.getIdToken(true);
    return user.uid;
  });

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<String> idToken() => _guard(() async {
    final token = await _auth.currentUser?.getIdToken();
    if (token == null) {
      throw const AuthFailure('Tu sesión terminó. Vuelve a ingresar.');
    }
    return token;
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (error) {
      throw AuthFailure(authErrorMessage(error.code));
    }
  }
}

/// El mensaje para la persona según el código de error de Firebase Auth.
///
/// Con la protección contra enumeración de emails (activa por defecto en los
/// proyectos nuevos), un email inexistente y una contraseña incorrecta llegan
/// los dos como `invalid-credential`: el mensaje no distingue entre ellos.
String authErrorMessage(String code) => switch (code) {
  'invalid-credential' ||
  'invalid-login-credentials' ||
  'wrong-password' ||
  'user-not-found' => 'El correo o la contraseña no son correctos.',
  'invalid-email' => 'Ese correo no es válido.',
  'user-disabled' => 'Esta cuenta está deshabilitada.',
  'email-already-in-use' =>
    'Ya hay una cuenta con ese correo. Ingresa con ella.',
  'weak-password' => 'La contraseña es muy débil: usa al menos 6 caracteres.',
  'too-many-requests' =>
    'Demasiados intentos. Espera unos minutos y vuelve a intentar.',
  'network-request-failed' =>
    'No hay conexión. Revisa tu internet y vuelve a intentar.',
  'operation-not-allowed' =>
    'El ingreso con correo y contraseña no está habilitado en Firebase.',
  _ => 'No se pudo completar. Vuelve a intentar.',
};

/// Para una plataforma sin config de Firebase (ver firebase_options.dart):
/// la app funciona sin sesión y el ingreso explica que no está disponible.
class UnavailableAuthRepository implements AuthRepository {
  const UnavailableAuthRepository();

  static const _failure = AuthFailure(
    'El ingreso todavía no está disponible en esta versión de la app.',
  );

  @override
  Stream<String?> accountChanges() => Stream.value(null);

  @override
  Future<String> signIn({required String email, required String password}) =>
      Future.error(_failure);

  @override
  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) => Future.error(_failure);

  @override
  Future<void> signOut() async {}

  @override
  Future<String> idToken() => Future.error(_failure);
}
