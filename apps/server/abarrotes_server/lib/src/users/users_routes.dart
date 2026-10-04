import 'package:serverpod/serverpod.dart';

import '../auth/firebase_auth_middleware.dart';
import '../auth/firebase_token_verifier.dart';
import '../auth/role_guard.dart';
import '../common/api_route.dart';
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
  addRoutes(webServer, usersRoutes(users, verifier));
}

/// Las rutas de usuarios con sus guards de rol.
List<RouteEntry> usersRoutes(
  UsersService users,
  FirebaseTokenVerifier verifier,
) => [
  // El usuario del token; la primera vez lo crea como cliente.
  (
    '/users/me',
    ApiRoute(Method.get, (session, request) async {
      final user = await users.findOrCreate(session, request.firebaseIdentity);
      return jsonResponse(200, userJson(user));
    }),
  ),
  // Solo admin: crea una cuenta admin o staff vinculada a un firebaseUid.
  (
    '/users',
    RoleGuard(
      {UserRole.admin},
      ApiRoute(Method.post, (session, request) async {
        final input = CreateUserRequest.parse(await readJsonBody(request));
        final user = await users.createStaff(
          session,
          admin: request.currentUser,
          input: input,
        );
        return jsonResponse(201, userJson(user));
      }),
      verifier: verifier,
    ),
  ),
];

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
