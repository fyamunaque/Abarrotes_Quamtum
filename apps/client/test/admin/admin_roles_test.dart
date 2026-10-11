import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/admin/staff/staff.dart';
import 'package:neils/admin/staff/staff_providers.dart';
import 'package:neils/features/admin/shared/admin_table.dart';
import 'package:neils/features/admin/shared/status_badge.dart';
import 'package:neils/features/admin/team/role_form.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/staff_permission.dart';

import '../fakes.dart';
import '../support.dart';
import 'panel_support.dart';
import 'staff_support.dart';

void main() {
  useBundledFonts();

  late FakeStaffRepository repository;

  setUp(() => repository = staffRepository());

  Future<void> pumpRoles(WidgetTester tester, {double width = 1280}) =>
      pumpPanel(
        tester,
        at: '/admin/roles',
        role: UserRole.admin,
        width: width,
        overrides: [staffRepositoryProvider.overrideWithValue(repository)],
      );

  Finder inTable(String text) => find.descendant(
    of: find.byType(AdminTable<StaffRole>),
    matching: find.text(text),
  );

  Finder inForm(Finder finder) =>
      find.descendant(of: find.byType(RoleForm), matching: finder);

  Finder checkbox(String label) => find.widgetWithText(CheckboxListTile, label);

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  bool checked(WidgetTester tester, String label) =>
      tester.widget<CheckboxListTile>(checkbox(label)).value!;

  List<String> statuses(WidgetTester tester) => tester
      .widgetList<StatusBadge>(find.byType(StatusBadge))
      .map((badge) => badge.label)
      .toList();

  testWidgets('la lista: el del sistema con candado, permisos y estado', (
    tester,
  ) async {
    await pumpRoles(tester);

    expect(inTable('Administrador'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AdminTable<StaffRole>),
        matching: find.byIcon(Icons.lock_outline),
      ),
      findsOneWidget,
    );
    expect(inTable('Todos'), findsOneWidget);
    expect(inTable('4 de ${StaffPermission.values.length}'), findsNWidgets(2));
    expect(statuses(tester), ['Activo', 'Activo', 'Activo', 'Inactivo']);
  });

  testWidgets('el rol del sistema se abre bloqueado', (tester) async {
    await pumpRoles(tester);

    await tapAndSettle(tester, inTable('Administrador'));

    expect(find.textContaining('es el rol del sistema'), findsOneWidget);
    final tiles = tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(tiles, hasLength(StaffPermission.values.length));
    expect(tiles.every((tile) => tile.value! && tile.onChanged == null), true);
    final name = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Nombre del rol'),
    );
    expect(name.enabled, isFalse);
    expect(find.text('Guardar cambios'), findsNothing);
    expect(find.text('Borrar rol'), findsNothing);

    await tapAndSettle(tester, find.text('Cerrar'));
    expect(find.byType(RoleForm), findsNothing);
  });

  testWidgets('el checklist: por área, con lo que permite cada uno', (
    tester,
  ) async {
    await pumpRoles(tester);
    await tapAndSettle(tester, find.text('Nuevo rol'));

    for (final area in PermissionArea.values) {
      expect(inForm(find.text(area.label)), findsOneWidget, reason: area.label);
    }
    for (final permission in StaffPermission.values) {
      expect(checkbox(permission.label), findsOneWidget);
      expect(
        inForm(find.textContaining(permission.description)),
        findsOneWidget,
        reason: permission.key,
      );
    }
    // Lo que necesita, dicho en el mismo permiso.
    expect(
      inForm(find.textContaining('Incluye "Ver el inventario"')),
      findsOneWidget,
    );
  });

  testWidgets('crear un rol: valida y marca lo que cada permiso necesita', (
    tester,
  ) async {
    await pumpRoles(tester);
    await tapAndSettle(tester, find.text('Nuevo rol'));

    await tapAndSettle(tester, find.text('Crear rol'));
    expect(find.text('Escribe un nombre.'), findsOneWidget);
    expect(find.text('Elige al menos un permiso.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del rol'),
      'Delivery',
    );
    await tapAndSettle(tester, checkbox('Cambiar el estado de los pedidos'));
    expect(checked(tester, 'Ver pedidos'), isTrue);
    expect(find.text('Elige al menos un permiso.'), findsNothing);
    expect(
      find.text('2 de ${StaffPermission.values.length} elegidos.'),
      findsOneWidget,
    );
    // Sin ver los pedidos, cambiar su estado no sirve: se desmarcan juntos.
    await tapAndSettle(tester, checkbox('Ver pedidos'));
    expect(checked(tester, 'Cambiar el estado de los pedidos'), isFalse);
    await tapAndSettle(tester, checkbox('Cambiar el estado de los pedidos'));

    await tapAndSettle(tester, find.text('Crear rol'));

    expect(find.byType(RoleForm), findsNothing);
    expect(find.text('Creaste el rol Delivery.'), findsOneWidget);
    expect(repository.roleList.last.name, 'Delivery');
    expect(repository.roleList.last.permissions, {
      StaffPermission.ordersView,
      StaffPermission.ordersUpdateStatus,
    });
    expect(inTable('Delivery'), findsOneWidget);
  });

  testWidgets('un nombre repetido: el motivo del servidor', (tester) async {
    await pumpRoles(tester);
    await tapAndSettle(tester, find.text('Nuevo rol'));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del rol'),
      'cajera',
    );
    await tapAndSettle(tester, checkbox('Ver pedidos'));
    await tapAndSettle(tester, find.text('Crear rol'));

    expect(find.text('Ya existe un rol llamado cajera'), findsOneWidget);
    expect(find.byType(RoleForm), findsOneWidget);
  });

  testWidgets('borrar: con personal asignado, el motivo; sin, se borra', (
    tester,
  ) async {
    await pumpRoles(tester);
    Finder confirm() => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Borrar'),
    );

    await tapAndSettle(tester, inTable('Cajera'));
    await tapAndSettle(tester, find.text('Borrar rol'));
    expect(find.text('¿Borrar el rol Cajera?'), findsOneWidget);
    await tapAndSettle(tester, confirm());
    expect(
      find.text(
        'El rol Cajera tiene 2 personas asignadas (también cuentan las '
        'dadas de baja): cámbiales el rol antes',
      ),
      findsOneWidget,
    );
    expect(find.byType(RoleForm), findsOneWidget);
    await tapAndSettle(tester, find.text('Cancelar'));

    await tapAndSettle(tester, inTable('Repartidor'));
    await tapAndSettle(tester, find.text('Borrar rol'));
    await tapAndSettle(tester, confirm());

    expect(find.text('Borraste el rol Repartidor.'), findsOneWidget);
    expect(inTable('Repartidor'), findsNothing);
  });

  testWidgets('editar: desactivar el rol', (tester) async {
    await pumpRoles(tester);

    await tapAndSettle(tester, inTable('Almacenero'));
    await tapAndSettle(tester, find.text('Rol activo'));
    expect(find.text('No da permisos y no se puede asignar.'), findsOneWidget);
    await tapAndSettle(tester, find.text('Guardar cambios'));

    expect(find.text('Guardaste el rol Almacenero.'), findsOneWidget);
    expect(repository.roleList[2].active, isFalse);
    expect(statuses(tester), ['Activo', 'Activo', 'Inactivo', 'Inactivo']);
  });

  testWidgets('en el teléfono, sin desbordes', (tester) async {
    await pumpRoles(tester, width: 320);
    expect(tester.takeException(), isNull);

    await tapAndSettle(tester, inTable('Cajera'));
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
