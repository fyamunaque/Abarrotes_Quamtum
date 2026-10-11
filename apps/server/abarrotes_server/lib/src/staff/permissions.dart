import '../generated/protocol.dart';

/// Cómo viaja [permission] en la API: el primer tramo es el dominio y el
/// resto la acción ("productsView" → "products.view", "ordersUpdateStatus" →
/// "orders.updateStatus"). Vale para cualquier valor nuevo del enum.
String permissionKey(Permission permission) {
  final name = permission.name;
  final split = name.indexOf(RegExp('[A-Z]'));
  return '${name.substring(0, split)}.'
      '${name[split].toLowerCase()}${name.substring(split + 1)}';
}

final _byKey = {
  for (final permission in Permission.values)
    permissionKey(permission): permission,
};

/// El permiso de [key] ("products.view"), o null si no existe.
Permission? permissionFromKey(String key) => _byKey[key];

/// Las claves de [permissions], en el orden del enum (el del catálogo).
List<String> permissionKeys(Iterable<Permission> permissions) {
  final set = permissions.toSet();
  return [
    for (final permission in Permission.values)
      if (set.contains(permission)) permissionKey(permission),
  ];
}

/// Los permisos efectivos de [role]: el de sistema (Administrador) los tiene
/// todos, también los que se agreguen al enum después.
Set<Permission> effectivePermissions(Role role) =>
    role.isSystem ? Permission.values.toSet() : role.permissions.toSet();
