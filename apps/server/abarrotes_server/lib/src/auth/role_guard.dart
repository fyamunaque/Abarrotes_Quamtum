import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../common/http_json.dart';
import '../generated/protocol.dart';
import 'firebase_auth_middleware.dart';

final _currentUserProperty = ContextProperty<User>('currentUser');

extension CurrentUserRequest on Request {
  /// El usuario que dejó pasar [RoleGuard]. Solo existe en rutas protegidas
  /// por rol: si la ruta no está envuelta, falla (500) en vez de dejar pasar.
  User get currentUser => _currentUserProperty.get(this);
}

/// Protege una ruta por rol, como `@Roles(...)` en NestJS:
///
/// ```dart
/// webServer.addRoute(RoleGuard({UserRole.admin}, CreateUserRoute(users)), '/users');
/// ```
///
/// Va detrás de `firebaseAuthMiddleware`, que verifica el token. El guard busca
/// al usuario por su `firebaseUid` y responde 403 si no existe o si su rol no
/// está en [roles]. Si lo deja pasar, la ruta lo encuentra en
/// `request.currentUser`. Revisa el rol antes que la ruta lea el body, así que
/// un 403 gana a un 400.
class RoleGuard extends Route {
  RoleGuard(this.roles, this.route)
    : super(methods: route.methods, path: route.path, host: route.host);

  final Set<UserRole> roles;
  final Route route;

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    final uid = request.firebaseIdentity.uid;
    final user = await User.db.findFirstRow(
      session,
      where: (user) => user.firebaseUid.equals(uid),
    );
    if (user == null || !roles.contains(user.role)) {
      return jsonError(403, 'Tu rol no tiene permiso para esta acción');
    }
    _currentUserProperty[request] = user;
    return route.handleCall(session, request);
  }
}
