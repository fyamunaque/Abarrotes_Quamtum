import 'package:serverpod/serverpod.dart';

import '../auth/firebase_auth_middleware.dart';
import '../auth/firebase_token_verifier.dart';
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
  webServer.addRoute(MeRoute(users), '/users/me');
  webServer.addRoute(CreateUserRoute(users), '/users');
}

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

/// POST /users (solo admin): crea una cuenta admin o staff vinculada al
/// `firebaseUid` recibido.
class CreateUserRoute extends Route {
  CreateUserRoute(this._users) : super(methods: {Method.post});

  final UsersService _users;

  @override
  Future<Result> handleCall(Session session, Request request) =>
      withApiErrors(() async {
        // Como en NestJS: primero el rol (403) y después el body (400).
        final admin = await _users.requireAdmin(
          session,
          request.firebaseIdentity.uid,
        );
        final input = CreateUserRequest.parse(await readJsonBody(request));
        final user = await _users.createStaff(
          session,
          admin: admin,
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
