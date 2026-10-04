/// Paths de la app. Los públicos van en español, como en la web.
abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const register = '/registro';
  static const catalog = '/catalogo';
  static const cart = '/carrito';

  /// El catálogo filtrado por una categoría (`?categoria=<id>`).
  static String catalogOf(String categoryId) =>
      Uri(path: catalog, queryParameters: {'categoria': categoryId}).toString();

  /// El detalle de un producto.
  static String product(String id) => '/producto/${Uri.encodeComponent(id)}';

  /// Los pedidos de la cuenta: pide haber ingresado (ver route_guard.dart).
  static const myOrders = '/mis-pedidos';

  /// "Mis pedidos" con el aviso de un pedido recién hecho.
  static String myOrdersWithNew(String orderId) =>
      Uri(path: myOrders, queryParameters: {'nuevo': orderId}).toString();

  /// Si [path] pide una cuenta (cualquier rol).
  static bool needsAccount(String path) => path == myOrders;

  /// Grupo protegido: solo admin y staff (ver route_guard.dart).
  static const admin = '/admin';

  /// Vitrina de componentes con datos de ejemplo. Solo existe en debug.
  static const showcase = '/vitrina';

  /// Si [path] es /admin o una de sus subrutas.
  static bool isAdmin(String path) =>
      path == admin || path.startsWith('$admin/');
}
