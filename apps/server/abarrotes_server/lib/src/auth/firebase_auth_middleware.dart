import 'package:serverpod/serverpod.dart';

import '../common/http_json.dart';
import 'firebase_identity.dart';
import 'firebase_token_verifier.dart';

final _identityProperty = ContextProperty<FirebaseIdentity>(
  'firebaseIdentity',
);

extension FirebaseIdentityRequest on Request {
  /// La identidad que dejó [firebaseAuthMiddleware] (o [requireIdentity]).
  /// Solo existe en las rutas protegidas.
  FirebaseIdentity get firebaseIdentity => _identityProperty.get(this);
}

/// Exige un Firebase ID token válido en `Authorization: Bearer <token>` para
/// todas las rutas bajo un path (ver [requireIdentity]).
Middleware firebaseAuthMiddleware(FirebaseTokenVerifier verifier) {
  return (Handler next) {
    return (Request request) async {
      try {
        await requireIdentity(verifier, request);
      } on ApiException catch (e) {
        return jsonError(e.statusCode, e.message);
      }
      return next(request);
    };
  };
}

/// La identidad del token de la petición: la que ya verificó
/// [firebaseAuthMiddleware] o, si la ruta no pasa por él, verificando el header
/// aquí mismo. Sin token o con uno inválido lanza [ApiException] 401; si no se
/// pueden obtener las llaves de Google, 503. El motivo va al log de la sesión,
/// nunca el token.
Future<FirebaseIdentity> requireIdentity(
  FirebaseTokenVerifier verifier,
  Request request,
) async {
  final verified = _identityProperty[request];
  if (verified != null) return verified;

  final token = _bearerToken(request);
  if (token == null) {
    throw const ApiException(
      401,
      'Falta el token de acceso (Authorization: Bearer <token>)',
    );
  }
  try {
    return _identityProperty[request] = await verifier.verify(token);
  } on InvalidFirebaseTokenException catch (e) {
    await _log(request, 'Firebase ID token rechazado: ${e.reason}');
    throw const ApiException(401, 'Token inválido o vencido');
  } on PublicKeysUnavailableException catch (e) {
    await _log(request, e.toString(), LogLevel.error);
    throw const ApiException(
      503,
      'No se pudo verificar el token, intenta de nuevo',
    );
  }
}

/// Para rutas públicas: la identidad si la petición trae un token válido; si
/// no trae o no sirve, null (se atiende como visitante anónimo).
Future<FirebaseIdentity?> optionalIdentity(
  FirebaseTokenVerifier verifier,
  Request request,
) async {
  if (_identityProperty[request] == null && _bearerToken(request) == null) {
    return null;
  }
  try {
    return await requireIdentity(verifier, request);
  } on ApiException {
    return null;
  }
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
  // En los tests no siempre hay sesión de Serverpod.
  final session = await request.sessionOrNull;
  session?.log(message, level: level);
}
