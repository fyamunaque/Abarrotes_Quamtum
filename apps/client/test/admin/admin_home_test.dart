import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/admin/stats/stats.dart';
import 'package:neils/admin/stats/stats_providers.dart';
import 'package:neils/common/days.dart';
import 'package:neils/features/admin/home/home_cards.dart';
import 'package:neils/features/admin/home/sales_chart.dart';
import 'package:neils/orders/fulfillment.dart';
import 'package:neils/orders/order_status.dart';

import '../fakes.dart';
import '../support.dart';
import 'panel_support.dart';

void main() {
  useBundledFonts();

  SalesSummary summary(int cents, int orders) => SalesSummary(
    totalCents: cents,
    orders: orders,
    averageTicketCents: orders == 0 ? 0 : (cents / orders).round(),
  );

  final days = [
    for (var i = 29; i >= 0; i--)
      DailySales(
        date: formatDay(DateTime(2026, 10, 4).subtract(Duration(days: i))),
        totalCents: i.isEven ? 4550 : 0,
        orders: i.isEven ? 2 : 0,
      ),
  ];

  late FakeStatsRepository stats;

  setUp(() {
    stats = FakeStatsRepository(
      overviewData: StatsOverview(
        today: summary(4550, 2),
        week: summary(32000, 9),
        month: summary(125040, 30),
        ordersByStatus: const {
          OrderStatus.pendingConfirmation: 3,
          OrderStatus.confirmed: 2,
          OrderStatus.outForDelivery: 1,
          OrderStatus.delivered: 20,
          OrderStatus.cancelled: 4,
          OrderStatus.preparing: 2,
          OrderStatus.readyForPickup: 1,
        },
        ordersByFulfillment: const {
          FulfillmentType.delivery: 27,
          FulfillmentType.pickup: 6,
        },
      ),
      sales: SalesReport(summary: summary(68250, 30), daily: days),
      top: [
        for (final (i, name) in [
          'Arroz extra 5 kg',
          'Aceite vegetal 1 L',
          'Leche evaporada 400 g',
          'Agua sin gas 2.5 L',
          'Fideos spaghetti 500 g',
          'Lejía 1 L',
        ].indexed)
          TopProduct(
            productId: 'p$i',
            name: name,
            quantity: 12 - i * 2,
            revenueCents: (12 - i * 2) * 1000,
          ),
      ],
      low: const [
        LowStockItem(
          id: 'azucar',
          name: 'Azúcar rubia 1 kg',
          currentStock: 0,
          minStock: 5,
          shortage: 5,
        ),
        LowStockItem(
          id: 'lejia',
          name: 'Lejía 1 L',
          currentStock: 18,
          minStock: 20,
          shortage: 2,
        ),
      ],
      expiringItems: const [
        ExpiringItem(
          id: 'yogurt',
          name: 'Yogurt de fresa 1 L',
          currentStock: 15,
          expirationDate: '2026-10-07',
          daysLeft: 3,
        ),
      ],
    );
  });

  Future<void> pumpHome(WidgetTester tester, {double width = 1280}) =>
      pumpPanel(
        tester,
        at: '/admin',
        width: width,
        overrides: [statsRepositoryProvider.overrideWithValue(stats)],
      );

  testWidgets('las ventas de hoy, la semana y el mes, y el ticket promedio', (
    tester,
  ) async {
    await pumpHome(tester);

    for (final (label, value, detail) in [
      ('Ventas de hoy', 'S/ 45.50', '2 pedidos'),
      ('Ventas de la semana', 'S/ 320.00', '9 pedidos'),
      ('Ventas del mes', 'S/ 1250.40', '30 pedidos'),
      ('Ticket promedio del mes', 'S/ 41.68', 'en 30 pedidos'),
    ]) {
      final tile = find.ancestor(
        of: find.text(label),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: tile, matching: find.text(value)),
        findsOneWidget,
        reason: label,
      );
      expect(
        find.descendant(of: tile, matching: find.text(detail)),
        findsOneWidget,
        reason: label,
      );
    }
  });

  testWidgets('los pedidos por estado, cada uno con su nombre', (tester) async {
    await pumpHome(tester);

    for (final (status, count) in [
      ('Pendiente de confirmación', '3'),
      ('En camino', '1'),
      ('Entregado', '20'),
      ('Cancelado', '4'),
      ('Preparando', '2'),
      ('En espera de recojo', '1'),
    ]) {
      final row = find.ancestor(
        of: find.text(status),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: row.first, matching: find.text(count)),
        findsOneWidget,
        reason: status,
      );
    }
  });

  testWidgets('los pedidos por tipo de entrega, con su parte', (tester) async {
    await pumpHome(tester);

    expect(find.text('Pedidos por tipo de entrega'), findsOneWidget);
    expect(find.text('A domicilio'), findsOneWidget);
    expect(find.text('27 (82 %)'), findsOneWidget);
    expect(find.text('Recojo en tienda'), findsOneWidget);
    expect(find.text('6 (18 %)'), findsOneWidget);
  });

  testWidgets('el gráfico de 30 días, con su resumen para el lector', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final spots = chart.data.lineBarsData.single.spots;
    expect(spots, hasLength(30));
    expect(spots.last.y, 45.5);
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Ventas de los últimos 30 días: S/ 682\.50 en 30 pedidos'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('"Ver los datos" muestra la tabla de cada día', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Ver los datos'));
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsNothing);
    expect(find.text('Pedidos'), findsWidgets);
    expect(find.text('S/ 45.50'), findsWidgets);
    await tester.tap(find.text('Ver el gráfico'));
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('stock bajo, por vencer y los 5 más vendidos', (tester) async {
    await pumpHome(tester);

    expect(find.text('Azúcar rubia 1 kg'), findsOneWidget);
    expect(find.text('Agotado (mínimo 5)'), findsOneWidget);
    expect(find.text('18 de 20 como mínimo'), findsOneWidget);
    expect(find.textContaining('vence en 3 días'), findsOneWidget);

    final top = find.ancestor(
      of: find.text('Más vendidos'),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(of: top, matching: find.text('Arroz extra 5 kg')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: top, matching: find.text('12 u.')),
      findsOneWidget,
    );
    // Solo 5, aunque el reporte trajera más.
    expect(
      find.descendant(of: top, matching: find.text('Lejía 1 L')),
      findsNothing,
    );
  });

  testWidgets('si un reporte falla, solo su tarjeta lo dice', (tester) async {
    stats.failing.add('sales');
    await pumpHome(tester);

    expect(find.byType(LineChart), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('S/ 45.50'), findsWidgets);

    stats.failing.clear();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('"Actualizar" vuelve a pedir todo', (tester) async {
    await pumpHome(tester);
    final before = stats.calls;

    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();

    expect(stats.calls, before + 5);
  });

  for (final width in [320.0, 375.0, 840.0]) {
    testWidgets('a $width px entra sin desbordarse', (tester) async {
      await pumpHome(tester, width: width);
      expect(tester.takeException(), isNull);
    });
  }

  group('escala y textos', () {
    test('el eje Y usa números redondos y unas 4 líneas', () {
      expect(niceScale(0), (max: 100.0, step: 25.0));
      expect(niceScale(45.5), (max: 60.0, step: 20.0));
      expect(niceScale(1250), (max: 1500.0, step: 500.0));
      expect(niceScale(7), (max: 8.0, step: 2.0));
    });

    test('cuánto falta para vencer', () {
      expect(expiresIn(0), 'vence hoy');
      expect(expiresIn(1), 'vence mañana');
      expect(expiresIn(3), 'vence en 3 días');
      expect(expiresIn(-1), 'venció ayer');
      expect(expiresIn(-4), 'venció hace 4 días');
    });
  });
}
