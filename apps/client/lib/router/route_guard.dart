import '../session/session.dart';
import 'routes.dart';

/// A dónde redirigir antes de mostrar [location], o null para dejarla pasar.
///
/// El flujo público (/, /login, /registro, /catalogo) es para todos. /admin y
/// sus subrutas son solo para admin y staff, como en la web y en el servidor:
/// - sin sesión → /login, con `from` para volver ahí después de ingresar;
/// - con una cuenta de cliente → al inicio;
/// - mientras la sesión carga, no redirige: el panel muestra que está
///   cargando, y el router vuelve a evaluar la ruta cuando se resuelve.
String? redirectFor(Session session, Uri location) {
  if (!Routes.isAdmin(location.path)) return null;
  return switch (session) {
    SessionLoading() => null,
    SignedOut() => Uri(
      path: Routes.login,
      queryParameters: {'from': location.toString()},
    ).toString(),
    SignedIn(:final user) when !user.role.isStaff => Routes.home,
    SignedIn() => null,
  };
}

/// A dónde ir después de ingresar o registrarse: admin y staff al panel, y un
/// cliente al catálogo.
///
/// [from] es la ruta que pidió el ingreso (`/login?from=...`). Solo se vuelve
/// a ella si es del panel y la cuenta puede verlo: viene en la URL, así que no
/// se sigue a cualquier lado.
String routeAfterSignIn(SessionUser user, String? from) {
  if (!user.role.isStaff) return Routes.catalog;
  final fromUri = from == null ? null : Uri.tryParse(from);
  final isPanelRoute =
      fromUri != null &&
      !fromUri.hasScheme &&
      !fromUri.hasAuthority &&
      Routes.isAdmin(fromUri.path);
  return isPanelRoute ? from! : Routes.admin;
}
