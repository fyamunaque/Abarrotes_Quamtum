import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/staff_permission.dart';
import 'package:neils/store/store_providers.dart';

import '../fakes.dart';
import '../support.dart';
import 'panel_support.dart';

/// /admin/tienda: los datos de la tienda, con store.manage.
void main() {
  useBundledFonts();

  late FakeStoreRepository store;

  setUp(() => store = FakeStoreRepository());

  Future<GoRouter> pumpStore(
    WidgetTester tester, {
    Set<StaffPermission>? permissions,
    UserRole role = UserRole.admin,
    double width = 1280,
    String at = '/admin/tienda',
  }) async {
    final (_, router) = await pumpPanel(
      tester,
      at: at,
      role: role,
      permissions: permissions,
      width: width,
      overrides: [storeRepositoryProvider.overrideWithValue(store)],
    );
    return router;
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
  }

  testWidgets('el formulario con los datos actuales; guarda y avisa', (
    tester,
  ) async {
    await pumpStore(tester);

    expect(
      tester.widget<TextFormField>(field('Dirección')).controller!.text,
      'Av. Arequipa 1234, Lince',
    );
    await tester.enterText(
      field('Horario de atención (opcional)'),
      'Todos los días de 7 a 22 h',
    );
    // Vacío: se borra.
    await tester.enterText(field('Referencia (opcional)'), '  ');
    await tester.enterText(field('Teléfono (opcional)'), '987654321');
    await save(tester);

    final saved = store.saved.single;
    expect(saved.name, "Neil's Food Services");
    expect(saved.address, 'Av. Arequipa 1234, Lince');
    expect(saved.reference, isNull);
    expect(saved.phone, '987654321');
    expect(saved.openingHours, 'Todos los días de 7 a 22 h');
    expect(saved.pickupInstructions, 'Muestra tu código en caja.');
    expect(find.text('Guardaste los datos de la tienda.'), findsOneWidget);
  });

  testWidgets('nombre y dirección son obligatorios', (tester) async {
    await pumpStore(tester);

    await tester.enterText(field('Dirección'), '');
    await save(tester);

    expect(find.text('Escribe la dirección de la tienda.'), findsOneWidget);
    expect(store.saved, isEmpty);
  });

  testWidgets('si el servidor lo rechaza, el motivo', (tester) async {
    store.updateFailure = const ApiFailure(
      'Tu rol no tiene permiso para esta acción',
      status: 403,
    );
    await pumpStore(tester);

    await save(tester);

    expect(
      find.text('Tu rol no tiene permiso para esta acción'),
      findsOneWidget,
    );
  });

  testWidgets('solo con store.manage: en el menú y por la URL', (tester) async {
    final router = await pumpStore(tester, permissions: cashierPermissions);

    expect(location(router), '/admin/sin-acceso');
    expect(find.text('Tienda'), findsNothing);
  });

  testWidgets('con store.manage, Tienda está en el menú', (tester) async {
    await pumpStore(
      tester,
      at: '/admin/pedidos',
      permissions: const {
        StaffPermission.ordersView,
        StaffPermission.storeManage,
      },
    );

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(
      [for (final d in rail.destinations) (d.label as Text).data],
      ['Pedidos', 'Tienda'],
    );
  });

  testWidgets('en el teléfono, sin desbordes', (tester) async {
    await pumpStore(tester, width: 320);
    expect(tester.takeException(), isNull);
  });
}
