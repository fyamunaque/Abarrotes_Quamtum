import 'package:serverpod/serverpod.dart';

import '../auth/firebase_auth_middleware.dart';
import '../auth/firebase_token_verifier.dart';
import '../auth/role_guard.dart';
import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/input_reader.dart';
import '../common/shopper.dart';
import '../generated/protocol.dart';
import 'create_user_request.dart';
import 'users_service.dart';

/// Registra las rutas de usuarios, todas detrás del Firebase ID token.
void addUsersRoutes(
  WebServer webServer, {
  required FirebaseTokenVerifier verifier,
  required ShopperResolver shoppers,
  UsersService users = const UsersService(),
}) {
  webServer.addMiddleware(firebaseAuthMiddleware(verifier), '/users');
  addRoutes(webServer, usersRoutes(users, verifier, shoppers: shoppers));
}

/// Las rutas de usuarios con sus guards de rol.
List<RouteEntry> usersRoutes(
  UsersService users,
  FirebaseTokenVerifier verifier, {
  required ShopperResolver shoppers,
}) => [
  // El usuario del token; la primera vez lo crea como cliente. isVip: si
  // puede usar las promociones VIP (VIP activo y correo verificado).
  (
    '/users/me',
    ApiRoute(Method.get, (session, request) async {
      final identity = request.firebaseIdentity;
      final user = await users.findOrCreate(session, identity);
      final shopper = await shoppers.resolve(session, identity);
      return jsonResponse(200, {...userJson(user), 'isVip': shopper.isVip});
    }),
  ),
  // El dispositivo donde la cuenta recibe avisos push (el token de FCM que da
  // la app). Volver a registrarlo no lo duplica.
  (
    '/users/me/devices',
    ApiRoute(Method.put, (session, request) async {
      final body = InputReader.body(
        await readJsonBody(request),
        allowed: const {'token', 'platform'},
      );
      final token = body.text('token', maxLength: maxDeviceTokenLength);
      final platform = body.oneOf(
        'platform',
        DevicePlatform.values,
        required: false,
      );
      body.check();

      final user = await users.findOrCreate(session, request.firebaseIdentity);
      await users.registerDevice(
        session,
        user,
        token: token!,
        platform: platform?.name,
      );
      return Response.noContent();
    }),
  ),
  // Al cerrar sesión: deja de recibir avisos en ese dispositivo.
  (
    '/users/me/devices',
    ApiRoute(Method.delete, (session, request) async {
      final query = InputReader.query(request, allowed: const {'token'});
      final token = query.text('token', maxLength: maxDeviceTokenLength);
      query.check();

      final user = await users.findOrCreate(session, request.firebaseIdentity);
      await users.removeDevice(session, user, token!);
      return Response.noContent();
    }),
  ),
  // Solo admin: crea una cuenta admin o staff vinculada a un firebaseUid.
  (
    '/users',
    RoleGuard(
      adminRoles,
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

/// Dónde corre la app que registra el dispositivo.
enum DevicePlatform { android, web }

/// Los tokens de FCM rondan los 160 caracteres; esto deja margen.
const maxDeviceTokenLength = 4096;

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
