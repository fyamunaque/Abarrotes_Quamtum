/// Paths de la app. Los públicos van en español, como en la web.
abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const register = '/registro';
  static const catalog = '/catalogo';

  /// Grupo protegido: solo admin y staff (ver route_guard.dart).
  static const admin = '/admin';

  /// Si [path] es /admin o una de sus subrutas.
  static bool isAdmin(String path) =>
      path == admin || path.startsWith('$admin/');
}
