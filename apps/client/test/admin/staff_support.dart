import 'package:neils/admin/staff/staff.dart';
import 'package:neils/session/staff_permission.dart';

import '../fakes.dart';

const administrator = StaffRole(
  id: 'r-admin',
  name: 'Administrador',
  permissions: {},
  isSystem: true,
);

const cashier = StaffRole(
  id: 'r-cajera',
  name: 'Cajera',
  permissions: {
    StaffPermission.productsView,
    StaffPermission.ordersView,
    StaffPermission.ordersUpdateStatus,
    StaffPermission.customersView,
  },
);

const storekeeper = StaffRole(
  id: 'r-almacen',
  name: 'Almacenero',
  permissions: {
    StaffPermission.productsView,
    StaffPermission.inventoryView,
    StaffPermission.inventoryAdjust,
    StaffPermission.statsView,
  },
);

/// Inactivo y sin nadie asignado.
const courier = StaffRole(
  id: 'r-reparto',
  name: 'Repartidor',
  permissions: {StaffPermission.ordersView},
  active: false,
);

StaffMember staffMember(
  String id,
  String email,
  StaffRole role, {
  bool active = true,
  bool hasAccount = true,
}) => StaffMember(
  id: id,
  email: email,
  active: active,
  hasAccount: hasAccount,
  createdAt: DateTime.utc(2026, 10, 1, 15),
  roleId: role.id,
  roleName: role.name,
  addedByName: 'Frank',
);

/// El equipo de los tests, visto por `admin@tienda.pe` (el admin de
/// `signedInAs`): él mismo, una Cajera activa, un Almacenero que todavía no
/// se registró y una Cajera desactivada.
FakeStaffRepository staffRepository() => FakeStaffRepository(
  roles: const [administrator, cashier, storekeeper, courier],
  members: [
    staffMember('m-1', 'admin@tienda.pe', administrator),
    staffMember('m-2', 'ana@gmail.com', cashier),
    staffMember('m-3', 'luis@hotmail.com', storekeeper, hasAccount: false),
    staffMember('m-4', 'pedro@gmail.com', cashier, active: false),
  ],
);
