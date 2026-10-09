import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/features/orders/order_tracker.dart';
import 'package:neils/orders/order_status.dart';
import 'package:neils/theme/motion.dart';
import 'package:neils/theme/neils_theme.dart';

import '../support.dart';

void main() {
  useBundledFonts();

  Future<void> pumpTracker(
    WidgetTester tester,
    OrderStatus status, {
    bool reduceMotion = false,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: neilsTheme(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Center(
            child: SizedBox(width: 360, child: OrderTracker(status: status)),
          ),
        ),
      ),
    ),
  );

  final halves = find.descendant(
    of: find.byType(OrderTracker),
    matching: find.byType(FractionallySizedBox),
  );

  /// Cuánto está lleno cada medio tramo, de izquierda a derecha: la mitad
  /// derecha del paso 1, la izquierda del 2, la derecha del 2… (seis en total).
  List<double> fills(WidgetTester tester) => [
    for (final half in tester.widgetList<FractionallySizedBox>(halves))
      half.widthFactor!,
  ];

  Color fillColor(WidgetTester tester) => tester
      .widget<ColoredBox>(
        find.descendant(of: halves.first, matching: find.byType(ColoredBox)),
      )
      .color;

  test('cada estado tiene su color', () {
    expect(
      {
        for (final status in OrderStatus.values)
          status: orderStatusColor(status),
      },
      {
        OrderStatus.pendingConfirmation: const Color(0xFFD98C21),
        OrderStatus.confirmed: const Color(0xFF3C7A5F),
        OrderStatus.outForDelivery: const Color(0xFF2E6F9E),
        OrderStatus.delivered: const Color(0xFF3C7A5F),
        OrderStatus.cancelled: const Color(0xFF8C3B33),
      },
    );
  });

  testWidgets('la línea llega hasta el estado actual, en su color', (
    tester,
  ) async {
    await pumpTracker(tester, OrderStatus.pendingConfirmation);
    expect(fills(tester), [0, 0, 0, 0, 0, 0]);

    await pumpTracker(tester, OrderStatus.outForDelivery);
    await tester.pumpAndSettle();
    expect(fills(tester), [1, 1, 1, 1, 0, 0]);
    expect(fillColor(tester), const Color(0xFF2E6F9E));

    await pumpTracker(tester, OrderStatus.delivered);
    await tester.pumpAndSettle();
    expect(fills(tester), [1, 1, 1, 1, 1, 1]);
  });

  testWidgets('al mostrarse no se anima', (tester) async {
    await pumpTracker(tester, OrderStatus.confirmed);

    expect(fills(tester), [1, 1, 0, 0, 0, 0]);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('cuando el estado avanza, el tramo nuevo se llena animado', (
    tester,
  ) async {
    await pumpTracker(tester, OrderStatus.confirmed);

    await pumpTracker(tester, OrderStatus.outForDelivery);
    expect(fills(tester), [1, 1, 0, 0, 0, 0]);

    await tester.pump(NeilsMotion.progress * 0.4);
    final middle = fills(tester);
    expect(middle[2], inExclusiveRange(0, 1));
    expect(middle[3], lessThan(1));
    // El color va de verde (confirmado) a azul (en camino).
    expect(fillColor(tester), isNot(const Color(0xFF3C7A5F)));
    expect(fillColor(tester), isNot(const Color(0xFF2E6F9E)));

    await tester.pump(NeilsMotion.progress * 0.6);
    expect(fills(tester), [1, 1, 1, 1, 0, 0]);
    expect(fillColor(tester), const Color(0xFF2E6F9E));
    // Flutter da por terminada la animación en el frame siguiente.
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('con "reducir animaciones" salta al estado nuevo', (
    tester,
  ) async {
    await pumpTracker(tester, OrderStatus.confirmed, reduceMotion: true);

    await pumpTracker(tester, OrderStatus.delivered, reduceMotion: true);

    expect(fills(tester), [1, 1, 1, 1, 1, 1]);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('cancelado: los pasos apagados y el aviso', (tester) async {
    await pumpTracker(tester, OrderStatus.cancelled);

    expect(fills(tester), [0, 0, 0, 0, 0, 0]);
    expect(find.text('Pedido cancelado'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('los pasos ya hechos llevan check; el actual, no', (
    tester,
  ) async {
    await pumpTracker(tester, OrderStatus.outForDelivery);
    expect(find.byIcon(Icons.check), findsNWidgets(2));

    await pumpTracker(tester, OrderStatus.delivered);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsNWidgets(4));
  });

  testWidgets('el estado se lee como texto, no solo con color', (tester) async {
    final semantics = tester.ensureSemantics();

    await pumpTracker(tester, OrderStatus.outForDelivery);
    expect(
      find.bySemanticsLabel('Estado del pedido: En camino, paso 3 de 4'),
      findsOneWidget,
    );
    for (final label in ['Pendiente', 'Confirmado', 'En camino', 'Entregado']) {
      expect(find.text(label), findsOneWidget);
    }

    await pumpTracker(tester, OrderStatus.cancelled);
    expect(
      find.bySemanticsLabel('Estado del pedido: Cancelado'),
      findsOneWidget,
    );
    semantics.dispose();
  });
}
