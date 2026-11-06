import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/session/staff_permission.dart';

/// Las fuentes salen de assets/google_fonts, como en la app: sin red.
void useBundledFonts() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
}

/// Una ventana de escritorio (1280 × 900): la barra completa, sin el menú de
/// la cuenta. El tamaño por defecto de los tests (800 × 600) ya es compacto.
void useWideScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Los permisos de los tests para una cuenta de [role]: admin los tiene
/// todos; staff, todos menos `staff.manage`; un cliente, ninguno.
Set<StaffPermission> permissionsOf(UserRole role) => switch (role) {
  UserRole.admin => StaffPermission.values.toSet(),
  UserRole.staff => {
    for (final permission in StaffPermission.values)
      if (permission != StaffPermission.staffManage) permission,
  },
  UserRole.customer => const {},
};

/// El rol que el servidor deriva de [permissions] (`GET /users/me`).
UserRole roleOf(Set<StaffPermission> permissions) =>
    permissions.contains(StaffPermission.staffManage)
    ? UserRole.admin
    : permissions.isEmpty
    ? UserRole.customer
    : UserRole.staff;

/// Las plantillas del servidor (`staff_bootstrap.dart`).
const storekeeperPermissions = {
  StaffPermission.productsView,
  StaffPermission.inventoryView,
  StaffPermission.inventoryAdjust,
  StaffPermission.statsView,
};
const cashierPermissions = {
  StaffPermission.productsView,
  StaffPermission.ordersView,
  StaffPermission.ordersUpdateStatus,
  StaffPermission.customersView,
};

/// Una cuenta de [role], con los permisos de [permissionsOf].
SignedIn signedInAs(UserRole role) => SignedIn(
  SessionUser(
    id: 'u-${role.name}',
    name: 'Ana ${role.name}',
    email: '${role.name}@tienda.pe',
    role: role,
    permissions: permissionsOf(role),
  ),
);

/// Una cuenta del personal con justo [permissions] (p. ej. las de la Cajera)
/// y el rol [roleName].
SignedIn signedInWith(Set<StaffPermission> permissions, {String? roleName}) =>
    SignedIn(
      SessionUser(
        id: 'u-personal',
        name: 'Ana Personal',
        email: 'personal@tienda.pe',
        role: roleOf(permissions),
        staffRoleName: roleName,
        permissions: permissions,
      ),
    );

/// Sesión controlable desde el test (en la app la maneja Firebase Auth).
class TestSession extends SessionNotifier {
  TestSession(this.initial);

  final Session initial;

  @override
  Session build() => initial;

  void set(Session session) => state = session;

  /// Si se llamó a [signOut] (que aquí no toca Firebase).
  bool signedOut = false;

  /// Cuántas veces se pidió refrescar el perfil (aquí no hace nada).
  int refreshes = 0;

  @override
  Future<void> refreshProfile() async => refreshes++;

  @override
  Future<void> signOut() async {
    signedOut = true;
    state = const SignedOut();
  }
}
