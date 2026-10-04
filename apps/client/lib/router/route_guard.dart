import '../session/session.dart';
import 'routes.dart';

/// A dónde redirigir antes de mostrar [location], o null para dejarla pasar.
///
/// El flujo público (/, /login, /registro, /catalogo) es para todos. /admin y
/// sus subrutas son solo para admin y staff, como en la web y en el servidor:
/// - sin sesión → /login, con `from` para volver ahí después de ingresar;
/// - con una cuenta de cliente → al inicio.
String? redirectFor(Session session, Uri location) {
  if (!Routes.isAdmin(location.path)) return null;
  return switch (session) {
    SignedOut() => Uri(
      path: Routes.login,
      queryParameters: {'from': location.toString()},
    ).toString(),
    SignedIn(:final user) when !user.role.isStaff => Routes.home,
    SignedIn() => null,
  };
}
