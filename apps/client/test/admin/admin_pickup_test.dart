import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/admin/orders/admin_orders_providers.dart';
import 'package:neils/orders/order_status.dart';
import 'package:neils/session/staff_permission.dart';

import '../fakes.dart';
import '../support.dart';
import 'panel_support.dart';

/// "Para recoger": la vista de caja con los pedidos de recojo.
void main() {
  useBundledFonts();

  late FakeAdminOrdersRepository repository;

  setUp(() {
    final now = DateTime.now();
    repository = FakeAdminOrdersRepository([
      // Listo hace 12 min y hace 3 min: el que espera hace más, arriba.
      adminOrder(
        'o-1',
        OrderStatus.readyForPickup,
        customer: 'Ana Quispe',
        pickupCode: 'K7M2XQ',
        readyForPickupAt: now.subtract(const Duration(minutes: 3, seconds: 20)),
      ),
      adminOrder(
        'o-2',
        OrderStatus.readyForPickup,
        customer: 'Luis Ñahui',
        pickupCode: 'P4R9TW',
        readyForPickupAt: now.subtract(
          const Duration(minutes: 12, seconds: 20),
        ),
      ),
      adminOrder(
        'o-3',
        OrderStatus.preparing,
        customer: 'Rosa Díaz',
        pickupCode: 'H3J8NB',
      ),
      // No van: otro estado y otro tipo de entrega.
      adminOrder(
        'o-4',
        OrderStatus.confirmed,
        customer: 'Pedro Recojo',
        pickupCode: 'M5V2CA',
      ),
      adminOrder('o-5', OrderStatus.outForDelivery, customer: 'Eva Domicilio'),
    ]);
  });

  Future<GoRouter> pumpPickup(
    WidgetTester tester, {
    Set<StaffPermission>? permissions,
    double width = 1280,
  }) async {
    final (_, router) = await pumpPanel(
      tester,
      at: '/admin/pedidos/recoger',
      permissions: permissions,
      width: width,
      overrides: [adminOrdersRepositoryProvider.overrideWithValue(repository)],
    );
    return router;
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  List<String> codes(WidgetTester tester) =>
      [
        for (final code in ['K7M2XQ', 'P4R9TW', 'H3J8NB', 'M5V2CA'])
          if (find.text(code).evaluate().isNotEmpty) code,
      ]..sort(
        (a, b) => tester
            .getTopLeft(find.text(a))
            .dy
            .compareTo(tester.getTopLeft(find.text(b)).dy),
      );

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar por código o nombre'),
      text,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('los que esperan primero, con cuánto hace que están listos', (
    tester,
  ) async {
    await pumpPickup(tester);

    expect(codes(tester), ['P4R9TW', 'K7M2XQ', 'H3J8NB']);
    expect(find.text('Listo hace 12 min'), findsOneWidget);
    expect(find.text('Listo hace 3 min'), findsOneWidget);
    expect(find.text('En espera de recojo'), findsNWidgets(2));
    expect(find.text('Preparando'), findsOneWidget);
    expect(find.text('Eva Domicilio'), findsNothing);
  });

  testWidgets('busca por código o por nombre, sin tildes ni mayúsculas', (
    tester,
  ) async {
    await pumpPickup(tester);

    await search(tester, 'k7m 2xq');
    expect(codes(tester), ['K7M2XQ']);

    await search(tester, 'nahui');
    expect(codes(tester), ['P4R9TW']);

    await search(tester, 'zzz');
    expect(
      find.text('Ningún pedido coincide con la búsqueda.'),
      findsOneWidget,
    );
  });

  testWidgets('marcar listo y entregar con el código del cliente', (
    tester,
  ) async {
    await pumpPickup(tester);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Marcar listo para recoger'),
    );
    await tester.pumpAndSettle();
    expect(repository.changes, [('o-3', OrderStatus.readyForPickup)]);
    expect(find.text('Preparando'), findsNothing);

    await search(tester, 'K7M2XQ');
    await tester.tap(find.widgetWithText(FilledButton, 'Marcar recogido'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'P4R9TW');
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Marcar recogido'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('El código de recojo no coincide'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'K7M2XQ');
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Marcar recogido'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.changes.last, ('o-1', OrderStatus.delivered));
    expect(find.text('Entregaste el pedido K7M2XQ.'), findsOneWidget);
    // Ya recogido, sale de la lista.
    expect(
      find.text('Ningún pedido coincide con la búsqueda.'),
      findsOneWidget,
    );
  });

  testWidgets('con orders.view se ve; sin orders.updateStatus, sin botones', (
    tester,
  ) async {
    await pumpPickup(tester, permissions: const {StaffPermission.ordersView});

    expect(codes(tester), hasLength(3));
    expect(find.widgetWithText(FilledButton, 'Marcar recogido'), findsNothing);
    expect(
      find.widgetWithText(FilledButton, 'Marcar listo para recoger'),
      findsNothing,
    );
  });

  testWidgets('sin orders.view, "No tienes acceso"', (tester) async {
    final router = await pumpPickup(
      tester,
      permissions: storekeeperPermissions,
    );

    expect(location(router), '/admin/sin-acceso');
  });

  testWidgets('las pestañas de Pedidos llevan de una vista a la otra', (
    tester,
  ) async {
    final router = await pumpPickup(tester);

    await tester.tap(find.text('Todos los pedidos'));
    await tester.pumpAndSettle();
    expect(location(router), '/admin/pedidos');
    await tester.tap(find.text('Para recoger'));
    await tester.pumpAndSettle();
    expect(location(router), '/admin/pedidos/recoger');
  });

  testWidgets('en el teléfono, sin desbordes', (tester) async {
    await pumpPickup(tester, width: 320);
    expect(tester.takeException(), isNull);
    expect(codes(tester), hasLength(3));
  });
}
