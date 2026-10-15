import 'package:flutter_test/flutter_test.dart';
import 'package:neils/session/staff_permission.dart';

void main() {
  test('el catálogo es el del servidor', () {
    // El enum Permission de apps/server (permissionKey): si el servidor suma
    // uno, la app tiene que conocerlo, o el editor de roles se lo quitaría a
    // un rol al guardarlo. El orden es el de las áreas del editor.
    expect(
      [for (final p in StaffPermission.values) p.key],
      unorderedEquals([
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
      ]),
    );
  });

  test('cada uno en su área, con lo que permite', () {
    expect(StaffPermission.storeManage.area, PermissionArea.store);
    expect(PermissionArea.store.label, 'Tienda');
    for (final permission in StaffPermission.values) {
      expect(permission.label, isNotEmpty);
      expect(permission.description, isNotEmpty);
    }
    expect(StaffPermission.fromKeys(['store.manage', 'otro.nuevo']), {
      StaffPermission.storeManage,
    });
  });
}
