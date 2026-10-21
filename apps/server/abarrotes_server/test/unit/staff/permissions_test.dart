import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/staff/permissions.dart';
import 'package:test/test.dart';

void main() {
  test('el catálogo: cada permiso con su clave "dominio.acción"', () {
    expect(Permission.values.map(permissionKey), [
      'products.view',
      'products.manage',
      'categories.manage',
      'orders.view',
      'orders.updateStatus',
      'inventory.view',
      'inventory.adjust',
      'promotions.manage',
      'vip.view',
      'vip.manage',
      'stats.view',
      'customers.view',
      'staff.manage',
      'store.manage',
    ]);
  });

  test('cualquier clave va y vuelve; una desconocida es null', () {
    for (final permission in Permission.values) {
      expect(permissionFromKey(permissionKey(permission)), permission);
    }
    expect(permissionFromKey('products.delete'), isNull);
    expect(permissionFromKey('productsView'), isNull);
  });

  test('permissionKeys sigue el orden del catálogo, sin repetir', () {
    expect(
      permissionKeys([
        Permission.staffManage,
        Permission.productsView,
        Permission.productsView,
      ]),
      ['products.view', 'staff.manage'],
    );
  });

  test('un rol de sistema tiene todos los permisos, aunque guarde menos', () {
    final admin = Role(
      name: 'Administrador',
      permissions: [Permission.productsView],
      isSystem: true,
    );
    final cajera = Role(
      name: 'Cajera',
      permissions: [Permission.ordersView, Permission.ordersUpdateStatus],
    );

    expect(effectivePermissions(admin), Permission.values.toSet());
    expect(effectivePermissions(cajera), {
      Permission.ordersView,
      Permission.ordersUpdateStatus,
    });
  });
}
