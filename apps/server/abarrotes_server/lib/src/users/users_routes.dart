import 'package:serverpod/serverpod.dart';

import '../auth/authorization.dart';
import '../auth/firebase_auth_middleware.dart';
import '../auth/guards.dart';
import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/input_reader.dart';
import '../common/pagination.dart';
import '../common/shopper.dart';
import '../generated/protocol.dart';
import '../staff/permissions.dart';
import 'users_service.dart';

/// Registra las rutas de usuarios, todas detrás del Firebase ID token.
void addUsersRoutes(
  WebServer webServer, {
  required Guards guards,
  required ShopperResolver shoppers,
  UsersService users = const UsersService(),
}) {
  webServer.addMiddleware(firebaseAuthMiddleware(guards.verifier), '/users');
  addRoutes(webServer, usersRoutes(users, guards, shoppers: shoppers));
}

/// Las rutas de la cuenta propia y el listado de clientes (con
/// `customers.view`).
List<RouteEntry> usersRoutes(
  UsersService users,
  Guards guards, {
  required ShopperResolver shoppers,
}) => [
  // El usuario del token; la primera vez lo crea como cliente. Con:
  // - isVip: si puede usar las promociones VIP (VIP activo y correo
  //   verificado);
  // - staffRole y permissions: su rol de personal y sus permisos efectivos,
  //   leídos ahora (vacíos si no es personal o no verificó el correo);
  // - role: derivado de eso, para la app (admin, staff o customer).
  (
    '/users/me',
    ApiRoute(Method.get, (session, request) async {
      final identity = request.firebaseIdentity;
      final user = await users.findOrCreate(session, identity);
      final shopper = await shoppers.resolve(session, identity);
      final access = await guards.authorization.accessOf(session, identity);
      return jsonResponse(200, {
        ...userJson(user, access),
        'isVip': shopper.isVip,
        'staffRole': access.isStaff
            ? {'id': access.roleId.toString(), 'name': access.roleName}
            : null,
        'permissions': permissionKeys(access.permissions),
      });
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
  // El listado de clientes del panel: las cuentas de la tienda, con sus
  // datos de contacto.
  (
    '/customers',
    guards.require(
      Permission.customersView,
      ApiRoute(Method.get, (session, request) async {
        final query = InputReader.query(
          request,
          allowed: {...PageQuery.fields, 'search'},
        );
        final page = PageQuery.read(query);
        final search = query.text('search', maxLength: 100, required: false);
        query.check();

        final (list, total) = await users.listCustomers(
          session,
          page,
          search: search,
        );
        return jsonResponse(
          200,
          page.wrap(list.map(customerJson).toList(), total),
        );
      }),
    ),
  ),
];

/// Un cliente en el listado del panel: sus datos de contacto, nunca el
/// firebaseUid.
Map<String, Object?> customerJson(User user) => {
  'id': user.id.toString(),
  'name': user.name,
  'email': user.email,
  'phone': user.phone,
  'address': user.address,
  'emailVerified': user.emailVerified,
  'createdAt': user.createdAt.toUtc().toIso8601String(),
};

/// Dónde corre la app que registra el dispositivo.
enum DevicePlatform { android, web }

/// Los tokens de FCM rondan los 160 caracteres; esto deja margen.
const maxDeviceTokenLength = 4096;

/// Lo que las rutas muestran de un usuario: nunca el firebaseUid. `role` sale
/// de [access] (ver [derivedRole]).
Map<String, Object?> userJson(User user, StaffAccess access) => {
  'id': user.id.toString(),
  'email': user.email,
  'name': user.name,
  'phone': user.phone,
  'role': derivedRole(access),
  'address': user.address,
  'createdAt': user.createdAt.toUtc().toIso8601String(),
};

/// El rol que lee la app para el panel: `admin` con `staff.manage`, `staff`
/// con algún otro permiso de personal y `customer` sin ninguno.
String derivedRole(StaffAccess access) => access.can(Permission.staffManage)
    ? 'admin'
    : access.permissions.isNotEmpty
    ? 'staff'
    : 'customer';
