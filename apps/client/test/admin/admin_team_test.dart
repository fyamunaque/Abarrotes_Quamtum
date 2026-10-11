import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/admin/staff/staff.dart';
import 'package:neils/admin/staff/staff_providers.dart';
import 'package:neils/features/admin/admin_shell.dart';
import 'package:neils/features/admin/shared/admin_table.dart';
import 'package:neils/features/admin/shared/status_badge.dart';
import 'package:neils/features/admin/team/team_forms.dart';
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

  Future<GoRouter> pumpTeam(
    WidgetTester tester, {
    UserRole role = UserRole.admin,
    double width = 1280,
    String at = '/admin/equipo',
  }) async {
    final (_, router) = await pumpPanel(
      tester,
      at: at,
      role: role,
      width: width,
      overrides: [staffRepositoryProvider.overrideWithValue(repository)],
    );
    return router;
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  Finder inTable(String text) => find.descendant(
    of: find.byType(AdminTable<StaffMember>),
    matching: find.text(text),
  );

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Finder button(String label) => find.widgetWithText(TextButton, label);

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> chooseRole(WidgetTester tester, String name) async {
    await tapAndSettle(tester, find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  List<String> statuses(WidgetTester tester) => tester
      .widgetList<StatusBadge>(find.byType(StatusBadge))
      .map((badge) => badge.label)
      .toList();

  testWidgets('la tabla: correo, rol, estado y las acciones de cada fila', (
    tester,
  ) async {
    await pumpTeam(tester);

    expect(inTable('admin@tienda.pe (tú)'), findsOneWidget);
    expect(inTable('ana@gmail.com'), findsOneWidget);
    expect(inTable('Cajera'), findsNWidgets(2));
    expect(inTable('Almacenero'), findsOneWidget);
    expect(statuses(tester), [
      'Activo',
      'Activo',
      'Pendiente de registro',
      'Desactivado',
    ]);
    expect(find.text('1–4 de 4'), findsOneWidget);
    // La fila propia no tiene acciones; la desactivada, solo cambiar el rol.
    expect(button('Cambiar rol'), findsNWidgets(3));
    expect(button('Desactivar'), findsNWidgets(2));
  });

  testWidgets('sin staff.manage no se ve, ni entrando por la URL', (
    tester,
  ) async {
    final router = await pumpTeam(tester, role: UserRole.staff);

    expect(location(router), '/admin');
    expect(find.text('Equipo'), findsNothing);

    router.go('/admin/roles');
    await tester.pumpAndSettle();
    expect(location(router), '/admin');
  });

  testWidgets('con staff.manage, el equipo está en la navegación', (
    tester,
  ) async {
    await pumpTeam(tester, at: '/admin');

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations, hasLength(AdminSection.values.length));
    expect(find.text('Equipo'), findsOneWidget);
  });

  testWidgets('las pestañas Personas y Roles, en la misma sección', (
    tester,
  ) async {
    final router = await pumpTeam(tester);

    await tapAndSettle(tester, find.text('Roles'));
    expect(location(router), '/admin/roles');
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, AdminSection.team.index);
    expect(find.text('Nuevo rol'), findsOneWidget);

    await tapAndSettle(tester, find.text('Personas'));
    expect(location(router), '/admin/equipo');
  });

  testWidgets('agregar un correo: valida el formato y el rol, y resume', (
    tester,
  ) async {
    await pumpTeam(tester);
    await tapAndSettle(tester, find.text('Agregar personas'));
    Finder inForm(String text) => find.descendant(
      of: find.byType(TeamAddForm),
      matching: find.text(text),
    );

    await tapAndSettle(tester, inForm('Agregar'));
    expect(find.text('Escribe un correo.'), findsOneWidget);
    expect(find.text('Elige un rol.'), findsOneWidget);

    await tester.enterText(field('Correo'), 'carla@gmail');
    await tapAndSettle(tester, inForm('Agregar'));
    expect(
      find.text('Escribe un correo como nombre@gmail.com.'),
      findsOneWidget,
    );
    expect(repository.sent, isEmpty);

    // Solo los roles activos se pueden asignar.
    await tapAndSettle(tester, find.byType(DropdownButtonFormField<String>));
    expect(find.text('Repartidor'), findsNothing);
    await tester.tap(find.text('Cajera').last);
    await tester.pumpAndSettle();
    await tester.enterText(field('Correo'), ' Carla@Gmail.com ');
    await tapAndSettle(tester, inForm('Agregar'));

    expect(repository.sent.single.$1, ['Carla@Gmail.com']);
    expect(repository.sent.single.$2, 'r-cajera');
    expect(find.text('Listo: el correo ya está en el equipo.'), findsOneWidget);
    await tapAndSettle(tester, find.text('Listo'));

    expect(find.byType(TeamAddForm), findsNothing);
    expect(find.text('Agregaste 1 persona al equipo.'), findsOneWidget);
    expect(inTable('carla@gmail.com'), findsOneWidget);
    expect(statuses(tester).where((s) => s == 'Pendiente de registro'), [
      'Pendiente de registro',
      'Pendiente de registro',
    ]);
  });

  testWidgets('pegar varios con un mismo rol: el resumen y la reactivación', (
    tester,
  ) async {
    await pumpTeam(tester);
    await tapAndSettle(tester, find.text('Agregar personas'));
    await tapAndSettle(tester, find.text('Varios'));

    await tester.enterText(
      field('Correos'),
      'pedro@gmail.com, ANA@gmail.com\nno-es-correo',
    );
    await chooseRole(tester, 'Almacenero');
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(TeamAddForm),
        matching: find.text('Agregar'),
      ),
    );

    expect(repository.sent.single.$2, 'r-almacen');
    expect(find.text('Se agregaron 1 de 3.'), findsOneWidget);
    expect(find.text('Agregados (1)'), findsOneWidget);
    expect(find.text('Ya estaban (1)'), findsOneWidget);
    expect(find.textContaining('usa "Cambiar rol"'), findsOneWidget);
    expect(find.text('No son correos válidos (1)'), findsOneWidget);
    await tapAndSettle(tester, find.text('Listo'));

    // Pedro estaba desactivado: vuelve, con el rol elegido.
    expect(statuses(tester), [
      'Activo',
      'Activo',
      'Pendiente de registro',
      'Activo',
    ]);
    expect(inTable('Almacenero'), findsNWidgets(2));
  });

  testWidgets('cambiar el rol', (tester) async {
    await pumpTeam(tester);

    await tapAndSettle(tester, button('Cambiar rol').first);
    expect(find.text('Ahora: Cajera'), findsOneWidget);
    await chooseRole(tester, 'Almacenero');
    await tapAndSettle(tester, find.text('Guardar'));

    expect(find.byType(ChangeRoleForm), findsNothing);
    expect(
      find.text('Ahora ana@gmail.com tiene el rol Almacenero.'),
      findsOneWidget,
    );
    expect(inTable('Almacenero'), findsNWidgets(2));
  });

  testWidgets('desactivar pide confirmación y la fila queda desactivada', (
    tester,
  ) async {
    await pumpTeam(tester);

    await tapAndSettle(tester, button('Desactivar').first);
    expect(find.text('¿Desactivar a ana@gmail.com?'), findsOneWidget);
    await tapAndSettle(tester, find.text('Volver'));
    expect(statuses(tester)[1], 'Activo');

    await tapAndSettle(tester, button('Desactivar').first);
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Desactivar'),
      ),
    );

    expect(statuses(tester)[1], 'Desactivado');
    expect(find.text('Desactivaste a ana@gmail.com.'), findsOneWidget);
    expect(button('Desactivar'), findsOneWidget);
  });

  group('cuando el servidor lo rechaza', () {
    // Quien administra tiene un rol a medida con staff.manage, y Frank es el
    // único Administrador.
    const manager = StaffRole(
      id: 'r-gerente',
      name: 'Gerente',
      permissions: {StaffPermission.staffManage},
    );
    const lastAdmin =
        'frank@gmail.com es el último Administrador activo: agrega otro '
        'antes de quitarle el rol';

    setUp(
      () => repository = FakeStaffRepository(
        roles: const [administrator, manager, cashier],
        members: [
          staffMember('m-1', 'admin@tienda.pe', manager),
          staffMember('m-2', 'frank@gmail.com', administrator),
        ],
      ),
    );

    testWidgets('desactivar al último Administrador: el motivo, en un aviso', (
      tester,
    ) async {
      await pumpTeam(tester);

      await tapAndSettle(tester, button('Desactivar'));
      await tapAndSettle(
        tester,
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Desactivar'),
        ),
      );

      expect(
        find.text('No se pudo desactivar a frank@gmail.com'),
        findsOneWidget,
      );
      expect(find.text(lastAdmin), findsOneWidget);
      await tapAndSettle(tester, find.text('Entendido'));
      expect(statuses(tester), ['Activo', 'Activo']);
    });

    testWidgets('cambiarle el rol: el motivo queda en el formulario', (
      tester,
    ) async {
      await pumpTeam(tester);

      await tapAndSettle(tester, button('Cambiar rol'));
      await chooseRole(tester, 'Cajera');
      await tapAndSettle(tester, find.text('Guardar'));

      expect(find.byType(ChangeRoleForm), findsOneWidget);
      expect(find.text(lastAdmin), findsOneWidget);
      expect(repository.memberList[1].roleName, 'Administrador');
    });
  });

  testWidgets('en el teléfono, sin desbordes', (tester) async {
    await pumpTeam(tester, width: 320);
    expect(tester.takeException(), isNull);
    expect(button('Cambiar rol'), findsNWidgets(3));

    await tapAndSettle(tester, find.text('Agregar personas'));
    expect(find.byType(Dialog), findsNothing);
    await tapAndSettle(tester, find.text('Varios'));
    expect(tester.takeException(), isNull);
  });
}
