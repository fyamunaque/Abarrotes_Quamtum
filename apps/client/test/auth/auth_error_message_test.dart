import 'package:flutter_test/flutter_test.dart';
import 'package:neils/auth/firebase_auth_repository.dart';

void main() {
  test('email inexistente y contraseña incorrecta dan el mismo mensaje', () {
    const message = 'El correo o la contraseña no son correctos.';
    for (final code in [
      'invalid-credential',
      'invalid-login-credentials',
      'wrong-password',
      'user-not-found',
    ]) {
      expect(authErrorMessage(code), message, reason: code);
    }
  });

  test('cada error del registro tiene su mensaje', () {
    expect(authErrorMessage('email-already-in-use'), contains('Ya hay una'));
    expect(authErrorMessage('weak-password'), contains('6 caracteres'));
    expect(authErrorMessage('invalid-email'), contains('no es válido'));
  });

  test('límite de intentos, red y proveedor deshabilitado', () {
    expect(authErrorMessage('too-many-requests'), contains('Demasiados'));
    expect(authErrorMessage('network-request-failed'), contains('conexión'));
    expect(authErrorMessage('operation-not-allowed'), contains('Firebase'));
  });

  test('un código desconocido da un mensaje genérico', () {
    expect(
      authErrorMessage('algo-nuevo'),
      'No se pudo completar. Vuelve a intentar.',
    );
  });
}
