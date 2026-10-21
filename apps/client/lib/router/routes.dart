import '../session/staff_permission.dart';

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

  /// Grupo protegido: solo el personal, y cada sección con su permiso (ver
  /// route_guard.dart).
  static const admin = '/admin';
  static const adminOrders = '/admin/pedidos';

  /// Para caja: los pedidos de recojo que se preparan o esperan.
  static const adminPickup = '/admin/pedidos/recoger';
  static const adminProducts = '/admin/productos';
  static const adminInventory = '/admin/inventario';
  static const adminPromotions = '/admin/promociones';
  static const adminVip = '/admin/clientes-vip';

  /// Los datos de la tienda: solo con `store.manage`.
  static const adminStore = '/admin/tienda';

  /// El equipo y sus roles: solo con `staff.manage`.
  static const adminTeam = '/admin/equipo';
  static const adminRoles = '/admin/roles';

  /// "No tienes acceso a esta sección": adonde lleva el guard una sección
  /// del panel sin su permiso.
  static const adminNoAccess = '/admin/sin-acceso';

  /// "No tienes acceso" para la sección [path].
  static String noAccessTo(String path) =>
      Uri(path: adminNoAccess, queryParameters: {'seccion': path}).toString();

  /// Las secciones del panel, en el orden de la navegación.
  static const panelSections = [
    admin,
    adminOrders,
    adminProducts,
    adminInventory,
    adminPromotions,
    adminVip,
    adminStore,
    adminTeam,
  ];

  /// Lo que pide cada sección del panel además de ser del personal: alguno
  /// de esos permisos, los mismos que piden sus rutas en el servidor.
  static const _panelPermissions = <String, Set<StaffPermission>>{
    adminOrders: {StaffPermission.ordersView},
    adminProducts: {
      StaffPermission.productsView,
      StaffPermission.productsManage,
    },
    adminInventory: {StaffPermission.inventoryView},
    adminPromotions: {StaffPermission.promotionsManage},
    adminVip: {StaffPermission.vipView},
    adminStore: {StaffPermission.storeManage},
    adminTeam: {StaffPermission.staffManage},
    adminRoles: {StaffPermission.staffManage},
  };

  /// Los permisos que pide [path] (o una de sus subrutas): con uno alcanza.
  /// El inicio del panel son las estadísticas. Null si basta con ser del
  /// personal ("Sin acceso").
  static Set<StaffPermission>? permissionsFor(String path) {
    if (path == admin) return const {StaffPermission.statsView};
    for (final MapEntry(key: section, value: permissions)
        in _panelPermissions.entries) {
      if (path == section || path.startsWith('$section/')) return permissions;
    }
    return null;
  }

  /// Si con [permissions] se puede abrir [path] del panel (p. ej. para
  /// mostrar un enlace a otra sección).
  static bool allows(Set<StaffPermission> permissions, String path) =>
      permissionsFor(path)?.any(permissions.contains) ?? true;

  /// Vitrina de componentes con datos de ejemplo. Solo existe en debug.
  static const showcase = '/vitrina';

  /// Si [path] es /admin o una de sus subrutas.
  static bool isAdmin(String path) =>
      path == admin || path.startsWith('$admin/');
}
