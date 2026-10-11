import '../session/session.dart';
import 'routes.dart';

/// A dónde redirigir antes de mostrar [location], o null para dejarla pasar.
///
/// El flujo público (/, /login, /registro, /catalogo, /producto, /carrito) es
/// para todos. /mis-pedidos pide una cuenta, cualquiera. /admin y sus subrutas
/// son solo para admin y staff, como en el servidor:
/// - sin sesión → /login, con `from` para volver ahí después de ingresar;
/// - con una cuenta de cliente, /admin → al inicio;
/// - una sección que pide un permiso (el equipo y los roles), sin ese
///   permiso → al inicio del panel;
/// - mientras la sesión carga, no redirige: la pantalla muestra que está
///   cargando, y el router vuelve a evaluar la ruta cuando se resuelve.
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
    SignedIn(:final user) when admin && !canOpenPanel(user, location.path) =>
      Routes.admin,
    SignedIn() => null,
  };
}

/// Si [user] puede ver [path] del panel: es del personal y, si la sección
/// pide un permiso (ver `Routes.permissionFor`), lo tiene.
bool canOpenPanel(SessionUser user, String path) =>
    user.role.isStaff &&
    switch (Routes.permissionFor(path)) {
      final permission? => user.can(permission),
      null => true,
    };

/// A dónde ir después de ingresar o registrarse: admin y staff al panel, y un
/// cliente al catálogo.
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
  return user.role.isStaff ? Routes.admin : Routes.catalog;
}
