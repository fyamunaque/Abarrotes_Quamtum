import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../common/http_json.dart';
import '../generated/protocol.dart';
import 'authorization.dart';
import 'firebase_auth_middleware.dart';
import 'firebase_token_verifier.dart';

final _currentUserProperty = ContextProperty<User>('currentUser');
final _staffAccessProperty = ContextProperty<StaffAccess>('staffAccess');

extension GuardedRequest on Request {
  /// El usuario que dejó pasar [RequirePermission] o [RequireAccount]. Solo
  /// existe en rutas protegidas: si la ruta no está envuelta, falla (500) en
  /// vez de dejar pasar.
  User get currentUser => _currentUserProperty.get(this);

  /// Los permisos con que [RequirePermission] dejó pasar (p. ej. para mostrar
  /// más según otro permiso). Sin guard de personal, [StaffAccess.none].
  StaffAccess get staffAccess => _staffAccessProperty[this] ?? StaffAccess.none;
}

/// Lo que necesitan los guards: verificar el token y saber qué puede hacer
/// cada persona. Cada dominio lo recibe y protege sus rutas con [require]
/// (un permiso) o [signedIn] (cualquier cuenta):
///
/// ```dart
/// guards.require(Permission.categoriesManage, ApiRoute(Method.post, crear))
/// ```
class Guards {
  const Guards({required this.verifier, required this.authorization});

  final FirebaseTokenVerifier verifier;
  final AuthorizationService authorization;

  Route require(Permission permission, Route route) =>
      RequirePermission(permission, route, this);

  Route signedIn(Route route) => RequireAccount(route, this);

  /// Para rutas públicas que muestran más al personal (p. ej. productos
  /// inactivos): el acceso del token, o [StaffAccess.none] para visitantes y
  /// tokens inválidos.
  Future<StaffAccess> optionalAccess(Session session, Request request) async {
    final identity = await optionalIdentity(verifier, request);
    return identity == null
        ? StaffAccess.none
        : authorization.accessOf(session, identity);
  }
}

/// Protege una ruta con un permiso:
///
/// - Verifica el Firebase ID token (401 o 503, ver [requireIdentity]).
/// - Busca al usuario por su `firebaseUid` (403 si no existe).
/// - Pregunta a [AuthorizationService] si tiene [permission] (403 si no).
///
/// Todo eso pasa antes de que la ruta lea el body, así que un 403 gana a un
/// 400. Si deja pasar, la ruta tiene `request.currentUser` y
/// `request.staffAccess`. No sabe de roles ni de la base: un permiso nuevo no
/// lo toca.
class RequirePermission extends Route {
  RequirePermission(this.permission, this.route, this._guards)
    : super(methods: route.methods, path: route.path, host: route.host);

  final Permission permission;
  final Route route;
  final Guards _guards;

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    try {
      final identity = await requireIdentity(_guards.verifier, request);
      final user = await _findByFirebaseUid(session, identity.uid);
      final access = user == null
          ? StaffAccess.none
          : await _guards.authorization.accessOf(session, identity);
      if (user == null || !access.can(permission)) {
        throw const ApiException.forbidden(
          'Tu rol no tiene permiso para esta acción',
        );
      }
      _currentUserProperty[request] = user;
      _staffAccessProperty[request] = access;
    } on ApiException catch (e) {
      return jsonError(e.statusCode, e.message);
    }
    return route.handleCall(session, request);
  }
}

/// Protege una ruta para cualquier cuenta de la tienda (p. ej. hacer un
/// pedido): 401 sin token, 403 si la cuenta todavía no existe en la base
/// (se crea con `GET /users/me`).
class RequireAccount extends Route {
  RequireAccount(this.route, this._guards)
    : super(methods: route.methods, path: route.path, host: route.host);

  final Route route;
  final Guards _guards;

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    try {
      final identity = await requireIdentity(_guards.verifier, request);
      final user = await _findByFirebaseUid(session, identity.uid);
      if (user == null) {
        throw const ApiException.forbidden(
          'Tu cuenta todavía no está lista: vuelve a ingresar',
        );
      }
      _currentUserProperty[request] = user;
    } on ApiException catch (e) {
      return jsonError(e.statusCode, e.message);
    }
    return route.handleCall(session, request);
  }
}

Future<User?> _findByFirebaseUid(Session session, String uid) => User.db
    .findFirstRow(session, where: (user) => user.firebaseUid.equals(uid));
