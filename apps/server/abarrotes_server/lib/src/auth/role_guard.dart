import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../common/http_json.dart';
import '../generated/protocol.dart';
import 'firebase_auth_middleware.dart';
import 'firebase_token_verifier.dart';

/// Los roles internos de la tienda: el dashboard y la gestión del catálogo.
const staffRoles = {UserRole.admin, UserRole.staff};

/// Cualquier cuenta de la tienda (p. ej. para hacer un pedido).
final anyRole = Set<UserRole>.unmodifiable(UserRole.values);

final _currentUserProperty = ContextProperty<User>('currentUser');

extension CurrentUserRequest on Request {
  /// El usuario que dejó pasar [RoleGuard]. Solo existe en rutas protegidas
  /// por rol: si la ruta no está envuelta, falla (500) en vez de dejar pasar.
  User get currentUser => _currentUserProperty.get(this);
}

/// Protege una ruta por rol (el que está guardado en `users`):
///
/// ```dart
/// RoleGuard(staffRoles, ApiRoute(Method.post, crear), verifier: verifier)
/// ```
///
/// Verifica el Firebase ID token (401 o 503, ver [requireIdentity]), busca al
/// usuario por su `firebaseUid` y responde 403 si no existe o si su rol no
/// está en [roles]. Todo eso pasa antes de que la ruta lea el body, así que un
/// 403 gana a un 400. Si lo deja pasar, la ruta tiene al usuario en
/// `request.currentUser`.
class RoleGuard extends Route {
  RoleGuard(this.roles, this.route, {required this.verifier})
    : super(methods: route.methods, path: route.path, host: route.host);

  final Set<UserRole> roles;
  final Route route;
  final FirebaseTokenVerifier verifier;

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    try {
      final identity = await requireIdentity(verifier, request);
      final user = await _findByFirebaseUid(session, identity.uid);
      if (user == null || !roles.contains(user.role)) {
        throw const ApiException.forbidden(
          'Tu rol no tiene permiso para esta acción',
        );
      }
      _currentUserProperty[request] = user;
    } on ApiException catch (e) {
      return jsonError(e.statusCode, e.message);
    }
    return route.handleCall(session, request);
  }
}

/// Para rutas públicas que muestran más a quien tiene rol (p. ej. productos
/// inactivos): el usuario del token, o null para visitantes y tokens inválidos.
Future<User?> optionalUser(
  Session session,
  Request request,
  FirebaseTokenVerifier verifier,
) async {
  final identity = await optionalIdentity(verifier, request);
  return identity == null ? null : _findByFirebaseUid(session, identity.uid);
}

/// Si [user] es admin o staff.
bool isStaff(User? user) => user != null && staffRoles.contains(user.role);

Future<User?> _findByFirebaseUid(Session session, String uid) => User.db
    .findFirstRow(session, where: (user) => user.firebaseUid.equals(uid));
