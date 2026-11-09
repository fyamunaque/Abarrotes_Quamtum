import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/theme/palette.dart';
import 'package:neils/admin/orders/admin_order.dart';
import 'package:neils/admin/orders/admin_orders_providers.dart';
import 'package:neils/admin/stats/stats_providers.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/common/money.dart';
import 'package:neils/features/admin/orders/admin_orders_screen.dart';
import 'package:neils/features/admin/shared/admin_table.dart';
import 'package:neils/features/admin/shared/status_badge.dart';
import 'package:neils/features/orders/order_tracker.dart';
import 'package:neils/orders/fulfillment.dart';
import 'package:neils/orders/order_status.dart';
import 'package:neils/session/session.dart';

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
        number: 1024,
      ),
      adminOrder(
        'o-2',
        OrderStatus.confirmed,
        customer: 'Luis Rojas',
        day: 3,
        number: 1023,
      ),
      adminOrder(
        'o-3',
        OrderStatus.delivered,
        customer: 'Rosa Díaz',
        day: 2,
        number: 1022,
      ),
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

  Finder statusFilter() => find.byType(DropdownButtonFormField<OrderStatus?>);

  /// Elige [label] en el menú "Estado".
  Future<void> chooseStatus(WidgetTester tester, String label) async {
    await tester.tap(statusFilter());
    await tester.pumpAndSettle();
    // El del menú: va arriba de la pantalla, después de la tabla.
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

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

  testWidgets('la columna y el filtro "Entrega"', (tester) async {
    repository.orders.add(
      adminOrder(
        'o-4',
        OrderStatus.preparing,
        customer: 'Rosa Recojo',
        pickupCode: 'K7M2XQ',
      ),
    );
    await pumpOrders(tester);
    Finder inTable(Finder finder) => find.descendant(
      of: find.byType(AdminTable<AdminOrder>),
      matching: finder,
    );

    expect(inTable(find.text('Entrega')), findsOneWidget);
    expect(inTable(find.text('Domicilio')), findsNWidgets(3));
    expect(inTable(find.text('Recojo')), findsOneWidget);
    expect(inTable(find.byIcon(Icons.storefront_outlined)), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Recojo'));
    await tester.pumpAndSettle();
    expect(find.text('Rosa Recojo'), findsOneWidget);
    expect(find.text('Ana Quispe'), findsNothing);

    // Los dos filtros juntos.
    await chooseStatus(tester, 'Confirmado');
    expect(
      find.text('Ningún pedido coincide con los filtros.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Domicilio y recojo'));
    await tester.pumpAndSettle();
    expect(find.text('Luis Rojas'), findsOneWidget);
  });

  testWidgets('el estado se elige en un menú, cada uno con su color', (
    tester,
  ) async {
    await pumpOrders(tester, width: 1000);
    // "Todos" al abrir, al lado de la búsqueda por número.
    expect(
      find.descendant(of: statusFilter(), matching: find.text('Todos')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(statusFilter()).dy,
      tester.getTopLeft(find.widgetWithText(TextField, 'Buscar por N.º')).dy,
    );

    await tester.tap(statusFilter());
    await tester.pumpAndSettle();
    for (final status in OrderStatus.values) {
      final item = find.byWidgetPredicate(
        (w) =>
            w is StatusBadge &&
            w.label == status.label &&
            w.color == orderStatusColor(NeilsPalette.light, status),
      );
      expect(item, findsWidgets, reason: status.label);
    }
  });

  testWidgets('filtrar por estado', (tester) async {
    await pumpOrders(tester);

    await chooseStatus(tester, 'Confirmado');

    expect(find.text('Luis Rojas'), findsOneWidget);
    expect(find.text('Ana Quispe'), findsNothing);

    await chooseStatus(tester, 'En camino');
    expect(find.text('No hay pedidos en estado "En camino".'), findsOneWidget);
  });

  testWidgets('buscar por número', (tester) async {
    await pumpOrders(tester);
    expect(find.text('N.º'), findsOneWidget);
    expect(find.text('1024'), findsOneWidget);

    final field = find.widgetWithText(TextField, 'Buscar por N.º');
    await tester.enterText(field, '1023');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Luis Rojas'), findsOneWidget);
    expect(find.text('Ana Quispe'), findsNothing);

    // Con otro filtro que no coincide.
    await chooseStatus(tester, 'Entregado');
    expect(
      find.text('El pedido N.º 1023 no coincide con los filtros.'),
      findsOneWidget,
    );
    await chooseStatus(tester, 'Todos');

    await tester.enterText(field, '9999');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('No hay un pedido con el N.º 9999.'), findsOneWidget);

    await tester.tap(find.byTooltip('Borrar la búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Quispe'), findsOneWidget);
    expect(find.text('Luis Rojas'), findsOneWidget);
  });

  testWidgets('el detalle: el cliente, las líneas y el seguimiento', (
    tester,
  ) async {
    await pumpOrders(tester);
    await open(tester, 'Ana Quispe');

    expect(find.text('Pedido N.º 1024 de Ana Quispe'), findsOneWidget);
    expect(find.text('ana@tienda.pe'), findsOneWidget);
    expect(find.text('987654321'), findsOneWidget);
    expect(find.text('DNI 45678912'), findsOneWidget);
    expect(find.text('Av. Arequipa 123, Lince'), findsOneWidget);
    expect(find.text('1 × Arroz extra 5 kg'), findsOneWidget);
    expect(
      tester.widget<OrderTracker>(find.byType(OrderTracker)).status,
      OrderStatus.pendingConfirmation,
    );
    expect(find.widgetWithText(FilledButton, 'Confirmar'), findsOneWidget);
    expect(find.text('Cancelar pedido'), findsOneWidget);
  });

  testWidgets('el detalle del panel muestra el regalo y los descuentos', (
    tester,
  ) async {
    repository.orders[0] = adminOrder(
      'o-1',
      OrderStatus.pendingConfirmation,
      customer: 'Ana Quispe',
      number: 1024,
      lines: promotionOrderLines,
      discountCents: 2490,
    );
    await pumpOrders(tester);
    await open(tester, 'Ana Quispe');

    expect(find.text('2 × Arroz extra 5 kg'), findsOneWidget);
    expect(find.text('2x1 −${formatSoles(2490)}'), findsOneWidget);
    expect(find.text('1 × Sal 1 kg'), findsOneWidget);
    expect(find.text('Regalo'), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text(formatSoles(4980)), findsOneWidget);
    expect(find.text('Descuentos'), findsOneWidget);
    expect(find.text('−${formatSoles(2490)}'), findsOneWidget);
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

  group('recojo en tienda', () {
    setUp(() {
      repository = FakeAdminOrdersRepository([
        adminOrder(
          'o-1',
          OrderStatus.confirmed,
          customer: 'Ana Quispe',
          pickupCode: 'K7M2XQ',
        ),
      ]);
    });

    testWidgets('los botones salen de lo que manda el servidor', (
      tester,
    ) async {
      await pumpOrders(tester);
      await open(tester, 'Ana Quispe');

      expect(find.text('Recojo en tienda'), findsOneWidget);
      expect(find.text('Código K7M2XQ'), findsOneWidget);
      expect(
        tester.widget<OrderTracker>(find.byType(OrderTracker)).fulfillmentType,
        FulfillmentType.pickup,
      );
      // De confirmado a preparando: nunca "en camino".
      expect(find.text('Marcar en camino'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Empezar a preparar'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Marcar listo para recoger'),
      );
      await tester.pumpAndSettle();

      expect(repository.changes, [
        ('o-1', OrderStatus.preparing),
        ('o-1', OrderStatus.readyForPickup),
      ]);
      expect(badgeText(tester, 'Ana Quispe'), 'En espera de recojo');
      expect(
        find.widgetWithText(FilledButton, 'Marcar recogido'),
        findsOneWidget,
      );
    });

    testWidgets('recogerlo pide el código del cliente', (tester) async {
      repository.orders[0] = adminOrder(
        'o-1',
        OrderStatus.readyForPickup,
        customer: 'Ana Quispe',
        pickupCode: 'K7M2XQ',
      );
      await pumpOrders(tester);
      await open(tester, 'Ana Quispe');
      Finder confirmButton() => find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Marcar recogido'),
      );

      // Volver atrás no cambia nada.
      await tester.tap(find.widgetWithText(FilledButton, 'Marcar recogido'));
      await tester.pumpAndSettle();
      expect(find.text('Código de recojo'), findsOneWidget);
      expect(tester.widget<FilledButton>(confirmButton()).onPressed, isNull);
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(repository.pickupCodes, isEmpty);

      // Un código que no coincide: el motivo del servidor, en el mismo
      // diálogo, para volver a escribirlo.
      await tester.tap(find.widgetWithText(FilledButton, 'Marcar recogido'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'K7M2XA');
      await tester.pump();
      await tester.tap(confirmButton());
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('El código de recojo no coincide'),
        ),
        findsOneWidget,
      );
      expect(repository.changes, isEmpty);

      await tester.enterText(find.byType(TextField).last, 'k7m2xq');
      await tester.pump();
      expect(find.text('El código de recojo no coincide'), findsNothing);
      await tester.tap(confirmButton());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.pickupCodes.last, 'k7m2xq');
      expect(repository.changes, [('o-1', OrderStatus.delivered)]);
      expect(badgeText(tester, 'Ana Quispe'), 'Recogido');
      expect(find.text('Este pedido ya no cambia de estado.'), findsOneWidget);
    });
  });

  group('código de entrega', () {
    setUp(() {
      repository = FakeAdminOrdersRepository([
        adminOrder(
          'o-1',
          OrderStatus.outForDelivery,
          customer: 'Ana Quispe',
          hasDeliveryCode: true,
        ),
      ]);
    });

    Finder inDialog(Finder finder) =>
        find.descendant(of: find.byType(AlertDialog), matching: finder);

    testWidgets('entregarlo pide el código que da el cliente', (tester) async {
      await pumpOrders(tester);
      await open(tester, 'Ana Quispe');

      await tester.tap(find.widgetWithText(FilledButton, 'Marcar entregado'));
      await tester.pumpAndSettle();
      expect(find.text('Código de entrega'), findsOneWidget);
      expect(find.text('El que te da el cliente.'), findsOneWidget);
      // El staff (sin staff.manage) no entrega sin código.
      expect(find.text('El cliente no tiene su código'), findsNothing);

      await tester.enterText(find.byType(TextField).last, 'P4R9TA');
      await tester.pump();
      await tester.tap(
        inDialog(find.widgetWithText(FilledButton, 'Marcar entregado')),
      );
      await tester.pumpAndSettle();
      expect(
        inDialog(find.text('El código de entrega no coincide')),
        findsOneWidget,
      );
      expect(repository.changes, isEmpty);

      await tester.enterText(find.byType(TextField).last, 'p4r9tw');
      await tester.pump();
      await tester.tap(
        inDialog(find.widgetWithText(FilledButton, 'Marcar entregado')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.deliveryCodes.last, 'p4r9tw');
      expect(repository.pickupCodes.last, isNull);
      expect(repository.changes, [('o-1', OrderStatus.delivered)]);
      expect(badgeText(tester, 'Ana Quispe'), 'Entregado');
    });

    testWidgets('un pedido de antes, sin código, se entrega directo', (
      tester,
    ) async {
      repository.orders[0] = adminOrder(
        'o-1',
        OrderStatus.outForDelivery,
        customer: 'Ana Quispe',
      );
      await pumpOrders(tester);
      await open(tester, 'Ana Quispe');

      await tester.tap(find.widgetWithText(FilledButton, 'Marcar entregado'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.changes, [('o-1', OrderStatus.delivered)]);
      expect(repository.deliveryCodes.single, isNull);
    });

    testWidgets('sin código, quien administra la tienda, con el motivo', (
      tester,
    ) async {
      await pumpPanel(
        tester,
        at: '/admin/pedidos',
        role: UserRole.admin,
        overrides: [
          adminOrdersRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await open(tester, 'Ana Quispe');
      Finder submit() =>
          inDialog(find.widgetWithText(FilledButton, 'Entregar sin código'));

      await tester.tap(find.widgetWithText(FilledButton, 'Marcar entregado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('El cliente no tiene su código'));
      await tester.pumpAndSettle();
      expect(find.text('Motivo'), findsOneWidget);
      expect(find.text('Código de entrega'), findsNothing);

      // "Volver" regresa al código, sin cerrar.
      await tester.tap(inDialog(find.text('Volver')));
      await tester.pumpAndSettle();
      expect(find.text('Código de entrega'), findsOneWidget);
      await tester.tap(find.text('El cliente no tiene su código'));
      await tester.pumpAndSettle();

      // Hace falta un motivo de verdad.
      await tester.enterText(find.byType(TextField).last, 'no');
      await tester.pump();
      expect(tester.widget<FilledButton>(submit()).onPressed, isNull);
      await tester.enterText(
        find.byType(TextField).last,
        'No tenía el celular a la mano',
      );
      await tester.pump();
      await tester.tap(submit());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(
        repository.withoutCodeReasons.last,
        'No tenía el celular a la mano',
      );
      expect(repository.deliveryCodes.last, isNull);
      expect(repository.changes, [('o-1', OrderStatus.delivered)]);
      expect(
        find.text('Entregado sin código: No tenía el celular a la mano'),
        findsOneWidget,
      );
    });
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
    // El menú de estado entra en la pantalla, y los chips de entrega van en
    // una fila que se desliza.
    expect(tester.getRect(statusFilter()).right, lessThanOrEqualTo(375));
    expect(
      tester.getTopLeft(find.widgetWithText(ChoiceChip, 'Recojo')).dy,
      tester
          .getTopLeft(find.widgetWithText(ChoiceChip, 'Domicilio y recojo'))
          .dy,
    );

    await open(tester, 'Ana Quispe');
    expect(find.byType(Dialog), findsNothing);
    expect(
      find.widgetWithText(AppBar, 'Pedido N.º 1024 de Ana Quispe'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

String _idOf(String customer) => switch (customer) {
  'Ana Quispe' => 'o-1',
  'Luis Rojas' => 'o-2',
  _ => 'o-3',
};
