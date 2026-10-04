import 'package:serverpod/serverpod.dart';

import '../common/http_json.dart';
import 'firebase_identity.dart';
import 'firebase_token_verifier.dart';

final _identityProperty = ContextProperty<FirebaseIdentity>(
  'firebaseIdentity',
);

extension FirebaseIdentityRequest on Request {
  /// La identidad que dejó [firebaseAuthMiddleware]. Solo existe en las rutas
  /// que el middleware protege.
  FirebaseIdentity get firebaseIdentity => _identityProperty.get(this);
}

/// Exige un Firebase ID token válido en `Authorization: Bearer <token>`.
///
/// Sin token o con uno inválido responde 401; si no se pueden obtener las
/// llaves de Google, 503. El motivo va al log de la sesión, nunca el token.
Middleware firebaseAuthMiddleware(FirebaseTokenVerifier verifier) {
  return (Handler next) {
    return (Request request) async {
      final token = _bearerToken(request);
      if (token == null) {
        return jsonError(
          401,
          'Falta el token de acceso (Authorization: Bearer <token>)',
        );
      }
      try {
        _identityProperty[request] = await verifier.verify(token);
      } on InvalidFirebaseTokenException catch (e) {
        await _log(request, 'Firebase ID token rechazado: ${e.reason}');
        return jsonError(401, 'Token inválido o vencido');
      } on PublicKeysUnavailableException catch (e) {
        await _log(request, e.toString(), LogLevel.error);
        return jsonError(
          503,
          'No se pudo verificar el token, intenta de nuevo',
        );
      }
      return next(request);
    };
  };
}

String? _bearerToken(Request request) {
  final value = request.headers['authorization']?.firstOrNull?.trim();
  if (value == null) return null;
  final match = RegExp(
    r'^Bearer\s+(\S+)$',
    caseSensitive: false,
  ).firstMatch(value);
  return match?[1];
}

Future<void> _log(
  Request request,
  String message, [
  LogLevel level = LogLevel.info,
]) async {
  // En los tests unitarios no hay sesión de Serverpod.
  final session = await request.sessionOrNull;
  session?.log(message, level: level);
}
