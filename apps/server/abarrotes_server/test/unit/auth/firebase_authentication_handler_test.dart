import 'package:abarrotes_server/src/auth/firebase_authentication_handler.dart';
import 'package:abarrotes_server/src/auth/firebase_identity.dart';
import 'package:abarrotes_server/src/auth/firebase_token_verifier.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../../support/test_tokens.dart';

void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  AuthenticationHandler handler({PublicKeysUnavailableException? keysError}) =>
      firebaseAuthenticationHandler(
        FirebaseTokenVerifier(
          projectId: testProjectId,
          keys: FakeKeys({'llave-1': google.public}, error: keysError),
          now: () => testNow,
        ),
      );

  // El handler no usa la sesión: la recibe porque así lo define Serverpod.
  final noSession = _NoSession();

  test('con un token válido autentica la sesión con el uid', () async {
    final info = await handler()(noSession, signToken(google.private));

    expect(info?.userIdentifier, 'uid-ana');
    expect(info?.scopes, isEmpty);
  });

  test('con un token inválido deja la sesión sin autenticar', () async {
    expect(await handler()(noSession, 'basura'), isNull);
    expect(
      await handler()(noSession, unsignedToken(validClaims())),
      isNull,
    );
  });

  test('sin llaves de Google tampoco lanza', () async {
    final info = await handler(
      keysError: const PublicKeysUnavailableException('sin red'),
    )(noSession, signToken(google.private));

    expect(info, isNull);
  });
}

class _NoSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('El handler no debería usar la sesión');
}
