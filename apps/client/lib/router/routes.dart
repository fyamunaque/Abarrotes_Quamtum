/// Paths de la app. Los públicos van en español, como en la web.
abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const register = '/registro';
  static const catalog = '/catalogo';
  static const cart = '/carrito';

  /// El catálogo filtrado por una categoría (`?categoria=<id>`) y lo buscado
  /// (`?q=<texto>`). Sin ninguno de los dos, el catálogo completo.
  static String catalogOf(String? categoryId, {String? search}) {
    final query = {
      'categoria': ?categoryId,
      if (search?.trim() case final text? when text.isNotEmpty) 'q': text,
    };
    return query.isEmpty
        ? catalog
        : Uri(path: catalog, queryParameters: query).toString();
  }

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
  static const adminOrders = '/admin/pedidos';
  static const adminProducts = '/admin/productos';
  static const adminInventory = '/admin/inventario';
  static const adminPromotions = '/admin/promociones';

  /// Vitrina de componentes con datos de ejemplo. Solo existe en debug.
  static const showcase = '/vitrina';

  /// Si [path] es /admin o una de sus subrutas.
  static bool isAdmin(String path) =>
      path == admin || path.startsWith('$admin/');
}
