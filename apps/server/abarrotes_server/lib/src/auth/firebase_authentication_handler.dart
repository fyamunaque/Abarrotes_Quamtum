import 'package:serverpod/serverpod.dart';

import 'firebase_identity.dart';
import 'firebase_token_verifier.dart';

/// Handler de autenticación de Serverpod basado en el Firebase ID token.
///
/// Serverpod lo llama al crear la sesión de cualquier petición que traiga
/// `Authorization`. Con un token válido, la sesión queda autenticada con el uid
/// de Firebase como `userIdentifier`. Nunca lanza: si el token no sirve, la
/// sesión queda sin autenticar y quien decide el 401 es
/// `firebaseAuthMiddleware` (o el endpoint, con `requireLogin`).
AuthenticationHandler firebaseAuthenticationHandler(
  FirebaseTokenVerifier verifier,
) {
  return (Session session, String token) async {
    try {
      final identity = await verifier.verify(token);
      return AuthenticationInfo(identity.uid, const {}, authId: identity.uid);
    } on InvalidFirebaseTokenException {
      return null;
    } on PublicKeysUnavailableException {
      return null;
    }
  };
}
