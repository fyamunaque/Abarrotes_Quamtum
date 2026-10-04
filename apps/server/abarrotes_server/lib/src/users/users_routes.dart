import 'package:serverpod/serverpod.dart';

import '../auth/firebase_auth_middleware.dart';
import '../auth/firebase_token_verifier.dart';
import '../auth/role_guard.dart';
import '../common/http_json.dart';
import '../generated/protocol.dart';
import 'create_user_request.dart';
import 'users_service.dart';

/// Registra las rutas de usuarios, todas detrás del Firebase ID token.
void addUsersRoutes(
  WebServer webServer, {
  required FirebaseTokenVerifier verifier,
  UsersService users = const UsersService(),
}) {
  webServer.addMiddleware(firebaseAuthMiddleware(verifier), '/users');
  usersRoutes(users).forEach((path, route) => webServer.addRoute(route, path));
}

/// Las rutas de usuarios por path, con sus guards de rol.
Map<String, Route> usersRoutes(UsersService users) => {
  '/users/me': MeRoute(users),
  '/users': RoleGuard({UserRole.admin}, CreateUserRoute(users)),
};

/// GET /users/me: el usuario del token; la primera vez lo crea como cliente.
class MeRoute extends Route {
  MeRoute(this._users) : super(methods: {Method.get});

  final UsersService _users;

  @override
  Future<Result> handleCall(Session session, Request request) =>
      withApiErrors(() async {
        final user = await _users.findOrCreate(
          session,
          request.firebaseIdentity,
        );
        return jsonResponse(200, userJson(user));
      });
}

/// POST /users: crea una cuenta admin o staff vinculada al `firebaseUid`
/// recibido. Se registra detrás de `RoleGuard({UserRole.admin})`.
class CreateUserRoute extends Route {
  CreateUserRoute(this._users) : super(methods: {Method.post});

  final UsersService _users;

  @override
  Future<Result> handleCall(Session session, Request request) =>
      withApiErrors(() async {
        final input = CreateUserRequest.parse(await readJsonBody(request));
        final user = await _users.createStaff(
          session,
          admin: request.currentUser,
          input: input,
        );
        return jsonResponse(201, userJson(user));
      });
}

/// Lo que las rutas muestran de un usuario: nunca el firebaseUid.
Map<String, Object?> userJson(User user) => {
  'id': user.id.toString(),
  'email': user.email,
  'name': user.name,
  'phone': user.phone,
  'role': user.role.name,
  'address': user.address,
  'createdAt': user.createdAt.toUtc().toIso8601String(),
};
