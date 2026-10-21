import '../session/session.dart';
import '../session/staff_permission.dart';
import 'routes.dart';

/// A dónde redirigir antes de mostrar [location], o null para dejarla pasar.
///
/// El flujo público (/, /login, /registro, /catalogo, /producto, /carrito) es
/// para todos. /mis-pedidos pide una cuenta, cualquiera. /admin y sus subrutas
/// son solo para el personal, y cada sección pide su permiso
/// (`Routes.permissionsFor`):
/// - sin sesión → /login, con `from` para volver ahí después de ingresar;
/// - con una cuenta de cliente, /admin → al inicio;
/// - /admin sin el permiso del inicio (las estadísticas) → la sección
///   principal de la persona ([panelHomeFor]);
/// - otra sección sin su permiso → "No tienes acceso a esta sección";
/// - mientras la sesión carga, no redirige: la pantalla muestra que está
///   cargando, y el router vuelve a evaluar la ruta cuando se resuelve.
///
/// Es solo para la experiencia: el servidor revisa el permiso en cada ruta.
/// Si la sesión cambia (p. ej. al volver a pedir el perfil, con un rol
/// nuevo), el router vuelve a pasar por aquí con la ruta actual.
String? redirectFor(Session session, Uri location) {
  final admin = Routes.isAdmin(location.path);
  if (!admin && !Routes.needsAccount(location.path)) return null;
  return switch (session) {
    SessionLoading() => null,
    SignedOut() => Uri(
      path: Routes.login,
      queryParameters: {'from': location.toString()},
    ).toString(),
    SignedIn(:final user) when admin && !user.role.isStaff => Routes.home,
    SignedIn(:final user)
        when location.path == Routes.admin &&
            !canOpenPanel(user, Routes.admin) =>
      panelHomeFor(user),
    SignedIn(:final user) when admin && !canOpenPanel(user, location.path) =>
      Routes.noAccessTo(location.path),
    SignedIn() => null,
  };
}

/// Si [user] puede ver [path] del panel: es del personal y tiene alguno de
/// los permisos de esa sección (`Routes.permissionsFor`).
bool canOpenPanel(SessionUser user, String path) =>
    user.role.isStaff && Routes.allows(user.permissions, path);

/// Lo primero que [user] puede cambiar, en este orden, y su sección.
const _tasks = [
  (StaffPermission.ordersUpdateStatus, Routes.adminOrders),
  (StaffPermission.inventoryAdjust, Routes.adminInventory),
  (StaffPermission.productsManage, Routes.adminProducts),
  (StaffPermission.promotionsManage, Routes.adminPromotions),
  (StaffPermission.vipManage, Routes.adminVip),
];

/// La sección principal de [user] en el panel, adonde llega al ingresar:
/// - quien administra la tienda (`staff.manage`), el inicio con las
///   estadísticas;
/// - los demás, la sección de su tarea: lo primero que puede cambiar, en el
///   orden de [_tasks]. Así la Cajera llega a Pedidos y el Almacenero a
///   Inventario;
/// - si no puede cambiar nada, la primera sección que puede ver, y sin
///   ninguna, "No tienes acceso".
String panelHomeFor(SessionUser user) {
  if (user.can(StaffPermission.staffManage) &&
      canOpenPanel(user, Routes.admin)) {
    return Routes.admin;
  }
  for (final (permission, path) in _tasks) {
    if (user.can(permission) && canOpenPanel(user, path)) return path;
  }
  return Routes.panelSections.firstWhere(
    (path) => canOpenPanel(user, path),
    orElse: () => Routes.adminNoAccess,
  );
}

/// A dónde ir después de ingresar o registrarse: el personal a su sección
/// principal del panel ([panelHomeFor]), y un cliente al catálogo.
///
/// [from] es la ruta que pidió el ingreso (`/login?from=...`). Se vuelve a
/// ella si es el carrito o "Mis pedidos" (cualquier cuenta), o una ruta del
/// panel y la cuenta puede verlo. Viene en la URL, así que no se sigue a
/// cualquier lado.
String routeAfterSignIn(SessionUser user, String? from) {
  final fromUri = from == null ? null : Uri.tryParse(from);
  if (fromUri != null && !fromUri.hasScheme && !fromUri.hasAuthority) {
    final path = fromUri.path;
    if (path == Routes.cart || Routes.needsAccount(path)) return from!;
    if (Routes.isAdmin(path) && canOpenPanel(user, path)) return from!;
  }
  return user.role.isStaff ? panelHomeFor(user) : Routes.catalog;
}
