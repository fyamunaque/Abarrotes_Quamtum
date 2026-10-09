import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/admin/orders/admin_order.dart';
import 'package:neils/admin/orders/admin_orders_providers.dart';
import 'package:neils/admin/stats/stats_providers.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/features/admin/orders/admin_orders_screen.dart';
import 'package:neils/features/admin/shared/admin_table.dart';
import 'package:neils/features/admin/shared/status_badge.dart';
import 'package:neils/features/orders/order_tracker.dart';
import 'package:neils/orders/order_status.dart';

import '../fakes.dart';
import '../support.dart';
import 'panel_support.dart';

void main() {
  useBundledFonts();

  late FakeAdminOrdersRepository repository;

  setUp(() {
    repository = FakeAdminOrdersRepository([
      adminOrder(
        'o-1',
        OrderStatus.pendingConfirmation,
        customer: 'Ana Quispe',
      ),
      adminOrder('o-2', OrderStatus.confirmed, customer: 'Luis Rojas', day: 3),
      adminOrder('o-3', OrderStatus.delivered, customer: 'Rosa Díaz', day: 2),
    ]);
  });

  Future<void> pumpOrders(WidgetTester tester, {double width = 1280}) =>
      pumpPanel(
        tester,
        at: '/admin/pedidos',
        width: width,
        overrides: [
          adminOrdersRepositoryProvider.overrideWithValue(repository),
        ],
      );

  Finder badgeOf(String customer) => find.descendant(
    of: find.ancestor(
      of: find.text(customer),
      matching: find.byWidgetPredicate(
        (w) => switch (w.key) {
          ValueKey(:final value) => value == _idOf(customer),
          _ => false,
        },
      ),
    ),
    matching: find.byType(StatusBadge),
  );

  String badgeText(WidgetTester tester, String customer) =>
      tester.widget<StatusBadge>(badgeOf(customer)).label;

  Future<void> open(WidgetTester tester, String customer) async {
    await tester.tap(find.text(customer));
    await tester.pumpAndSettle();
  }

  testWidgets('la tabla con fecha, cliente, productos, total y estado', (
    tester,
  ) async {
    await pumpOrders(tester);

    for (final header in ['Fecha', 'Cliente', 'Productos', 'Total', 'Estado']) {
      expect(
        find.descendant(
          of: find.byType(AdminTable<AdminOrder>),
          matching: find.text(header),
        ),
        findsOneWidget,
        reason: header,
      );
    }
    expect(find.text('Ana Quispe'), findsOneWidget);
    expect(find.text('S/ 33.80'), findsNWidgets(3));
    expect(badgeText(tester, 'Ana Quispe'), 'Pendiente de confirmación');
    expect(find.text('1–3 de 3'), findsOneWidget);
  });

  testWidgets('filtrar por estado', (tester) async {
    await pumpOrders(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Confirmado'));
    await tester.pumpAndSettle();

    expect(find.text('Luis Rojas'), findsOneWidget);
    expect(find.text('Ana Quispe'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'En camino'));
    await tester.pumpAndSettle();
    expect(find.text('No hay pedidos en estado "En camino".'), findsOneWidget);
  });

  testWidgets('el detalle: el cliente, las líneas y el seguimiento', (
    tester,
  ) async {
    await pumpOrders(tester);
    await open(tester, 'Ana Quispe');

    expect(find.text('Pedido de Ana Quispe'), findsOneWidget);
    expect(find.text('ana@tienda.pe'), findsOneWidget);
    expect(find.text('987654321'), findsOneWidget);
    expect(find.text('Av. Arequipa 123, Lince'), findsOneWidget);
    expect(find.text('1 × Arroz extra 5 kg'), findsOneWidget);
    expect(
      tester.widget<OrderTracker>(find.byType(OrderTracker)).status,
      OrderStatus.pendingConfirmation,
    );
    expect(find.widgetWithText(FilledButton, 'Confirmar'), findsOneWidget);
    expect(find.text('Cancelar pedido'), findsOneWidget);
  });

  testWidgets('el stepper avanza el pedido paso a paso', (tester) async {
    await pumpOrders(tester);
    await open(tester, 'Ana Quispe');

    for (final (action, status) in [
      ('Confirmar', OrderStatus.confirmed),
      ('Marcar en camino', OrderStatus.outForDelivery),
      ('Marcar entregado', OrderStatus.delivered),
    ]) {
      await tester.tap(find.widgetWithText(FilledButton, action));
      await tester.pumpAndSettle();
      expect(
        tester.widget<OrderTracker>(find.byType(OrderTracker)).status,
        status,
        reason: action,
      );
    }

    expect(find.text('Este pedido ya no cambia de estado.'), findsOneWidget);
    expect(find.text('Cancelar pedido'), findsNothing);
    expect(repository.changes.map((c) => c.$2), [
      OrderStatus.confirmed,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ]);

    // La tabla de atrás también se actualizó.
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(badgeText(tester, 'Ana Quispe'), 'Entregado');
  });

  testWidgets('cancelar pide confirmación', (tester) async {
    await pumpOrders(tester);
    await open(tester, 'Luis Rojas');

    await tester.tap(find.text('Cancelar pedido'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cancelar este pedido?'), findsOneWidget);
    expect(find.textContaining('vuelve al inventario'), findsOneWidget);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(repository.changes, isEmpty);

    await tester.tap(find.text('Cancelar pedido'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Cancelar pedido'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.changes, [('o-2', OrderStatus.cancelled)]);
    expect(
      tester.widget<OrderTracker>(find.byType(OrderTracker)).status,
      OrderStatus.cancelled,
    );
  });

  testWidgets('si otra persona ya lo cambió, lo dice y lo trae como está', (
    tester,
  ) async {
    await pumpOrders(tester);
    await open(tester, 'Ana Quispe');
    // Mientras tanto, desde otro lado, alguien lo confirmó.
    repository.orders[0] = FakeAdminOrdersRepository.withStatus(
      repository.orders[0],
      OrderStatus.confirmed,
    );
    repository.failNext = const ApiFailure(
      'El pedido ya está confirmado',
      status: 400,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('El pedido ya está confirmado'), findsOneWidget);
    expect(
      tester.widget<OrderTracker>(find.byType(OrderTracker)).status,
      OrderStatus.confirmed,
    );
    expect(
      find.widgetWithText(FilledButton, 'Marcar en camino'),
      findsOneWidget,
    );
  });

  testWidgets('"Actualizar" trae los pedidos nuevos', (tester) async {
    await pumpOrders(tester);
    repository.orders.add(
      adminOrder('o-4', OrderStatus.pendingConfirmation, customer: 'Nuevo'),
    );

    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo'), findsOneWidget);
    expect(find.text('1–4 de 4'), findsOneWidget);
  });

  testWidgets('si "Actualizar" falla, lo avisa y la tabla queda', (
    tester,
  ) async {
    await pumpOrders(tester);
    repository.failList = const ApiFailure('Sin conexión');

    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo actualizar.'), findsOneWidget);
    expect(find.text('Ana Quispe'), findsOneWidget);
  });

  testWidgets('se actualiza solo, y deja de hacerlo al salir', (tester) async {
    final (_, router) = await pumpPanel(
      tester,
      at: '/admin/pedidos',
      overrides: [
        adminOrdersRepositoryProvider.overrideWithValue(repository),
        statsRepositoryProvider.overrideWithValue(FakeStatsRepository()),
      ],
    );
    repository.orders.add(
      adminOrder('o-4', OrderStatus.pendingConfirmation, customer: 'Nuevo'),
    );

    await tester.pump(AdminOrdersScreen.autoRefreshEvery);
    await tester.pumpAndSettle();
    expect(find.text('Nuevo'), findsOneWidget);

    // Fuera de Pedidos, ya no pide nada.
    router.go('/admin');
    await tester.pumpAndSettle();
    final calls = repository.listCalls;
    await tester.pump(AdminOrdersScreen.autoRefreshEvery * 3);
    expect(repository.listCalls, calls);
  });

  testWidgets('si la vuelta automática falla, la tabla queda igual', (
    tester,
  ) async {
    await pumpOrders(tester);
    repository.failList = const ApiFailure('Sin conexión');

    await tester.pump(AdminOrdersScreen.autoRefreshEvery);
    await tester.pumpAndSettle();

    expect(find.text('Ana Quispe'), findsOneWidget);
    expect(find.text('No se pudo actualizar.'), findsNothing);
  });

  testWidgets('en el teléfono, el detalle ocupa la pantalla', (tester) async {
    await pumpOrders(tester, width: 375);
    expect(tester.takeException(), isNull);
    // Los chips de estado van en una fila que se desliza, no en cuatro.
    expect(
      tester.getTopLeft(find.widgetWithText(ChoiceChip, 'Cancelado')).dy,
      tester.getTopLeft(find.widgetWithText(ChoiceChip, 'Todos')).dy,
    );

    await open(tester, 'Ana Quispe');
    expect(find.byType(Dialog), findsNothing);
    expect(find.widgetWithText(AppBar, 'Pedido de Ana Quispe'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

String _idOf(String customer) => switch (customer) {
  'Ana Quispe' => 'o-1',
  'Luis Rojas' => 'o-2',
  _ => 'o-3',
};
