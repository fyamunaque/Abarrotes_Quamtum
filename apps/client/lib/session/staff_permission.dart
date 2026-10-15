/// Las áreas del panel, para agrupar los permisos en el editor de roles.
enum PermissionArea {
  products('Productos'),
  orders('Pedidos'),
  inventory('Inventario'),
  promotions('Promociones'),
  vip('Clientes VIP'),
  stats('Estadísticas'),
  store('Tienda'),
  team('Equipo');

  const PermissionArea(this.label);

  final String label;
}

/// El catálogo de permisos del personal, como lo define el servidor (el enum
/// `Permission` de apps/server). Cada uno viaja por su [key]
/// ("orders.updateStatus") y en el panel se muestra con [label] y
/// [description].
enum StaffPermission {
  productsView(
    'products.view',
    PermissionArea.products,
    'Ver productos dados de baja',
    'Ve en el panel también los productos que ya no se venden.',
  ),
  productsManage(
    'products.manage',
    PermissionArea.products,
    'Crear y editar productos',
    'Agrega productos, cambia sus precios y datos, y los da de baja.',
  ),
  categoriesManage(
    'categories.manage',
    PermissionArea.products,
    'Administrar categorías',
    'Crea, renombra y borra categorías.',
  ),
  ordersView(
    'orders.view',
    PermissionArea.orders,
    'Ver pedidos',
    'Ve todos los pedidos de la tienda, con sus productos.',
  ),
  ordersUpdateStatus(
    'orders.updateStatus',
    PermissionArea.orders,
    'Cambiar el estado de los pedidos',
    'Confirma, envía, entrega o cancela pedidos. Cancelar devuelve el stock.',
  ),
  customersView(
    'customers.view',
    PermissionArea.orders,
    'Ver los datos de los clientes',
    'Nombre, correo y teléfono de quien hizo cada pedido, y el listado de '
        'clientes.',
  ),
  inventoryView(
    'inventory.view',
    PermissionArea.inventory,
    'Ver el inventario',
    'Ve los movimientos de stock y las alertas de stock bajo y por vencer.',
  ),
  inventoryAdjust(
    'inventory.adjust',
    PermissionArea.inventory,
    'Registrar movimientos',
    'Registra entradas, salidas y ajustes de stock.',
  ),
  promotionsManage(
    'promotions.manage',
    PermissionArea.promotions,
    'Administrar promociones',
    'Ve, crea, edita y borra promociones, también las VIP.',
  ),
  vipView(
    'vip.view',
    PermissionArea.vip,
    'Ver los clientes VIP',
    'Ve la lista de correos VIP.',
  ),
  vipManage(
    'vip.manage',
    PermissionArea.vip,
    'Agregar y quitar clientes VIP',
    'Agrega correos a la lista VIP y los da de baja.',
  ),
  statsView(
    'stats.view',
    PermissionArea.stats,
    'Ver estadísticas',
    'Ve las ventas, los más vendidos y las alertas del inicio del panel.',
  ),
  staffManage(
    'staff.manage',
    PermissionArea.team,
    'Administrar el equipo',
    'Agrega personas, les cambia el rol, las desactiva y edita los roles. '
        'Es el permiso de quien administra la tienda.',
  ),
  storeManage(
    'store.manage',
    PermissionArea.store,
    'Editar los datos de la tienda',
    'Cambia el nombre, la dirección, el horario y las instrucciones de recojo '
        'que ven los clientes.',
  );

  const StaffPermission(this.key, this.area, this.label, this.description);

  /// Como viaja en la API: "dominio.acción".
  final String key;
  final PermissionArea area;
  final String label;
  final String description;

  /// El permiso que este necesita para servir en el panel (cambiar el estado
  /// de un pedido sin poder ver los pedidos no sirve). El editor de roles
  /// los marca juntos.
  StaffPermission? get requires => switch (this) {
    ordersUpdateStatus => ordersView,
    inventoryAdjust => inventoryView,
    vipManage => vipView,
    _ => null,
  };

  /// El permiso de [key], o null si esta versión de la app no lo conoce.
  static StaffPermission? fromKey(String key) => _byKey[key];

  static final _byKey = {
    for (final permission in values) permission.key: permission,
  };

  /// Los de [keys] que la app conoce, sin repetir.
  static Set<StaffPermission> fromKeys(Iterable<Object?> keys) => {
    for (final key in keys)
      if (key is String) ?fromKey(key),
  };
}
