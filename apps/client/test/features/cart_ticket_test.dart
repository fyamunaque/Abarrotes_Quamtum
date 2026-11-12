import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/common/money.dart';
import 'package:neils/features/cart/cart_ticket.dart';
import 'package:neils/theme/neils_theme.dart';
import 'package:neils/theme/palette.dart';

import '../support.dart';

/// El resumen del carrito: un ticket con el borde de arriba perforado.
void main() {
  useBundledFonts();

  Future<void> pumpTicket(
    WidgetTester tester,
    CartTicket ticket, {
    double width = 390,
    double textScale = 1,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = Size(width, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: neilsTheme(brightness),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 700),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ticket,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('el ticket muestra subtotal, descuentos y total estimado', (
    tester,
  ) async {
    await pumpTicket(
      tester,
      const CartTicket(
        subtotalCents: 4980,
        discountCents: 2490,
        totalCents: 2490,
      ),
    );

    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text(formatSoles(4980)), findsOneWidget);
    expect(find.text('Descuentos'), findsOneWidget);
    expect(find.text('−${formatSoles(2490)}'), findsOneWidget);
    expect(find.text('Total estimado'), findsOneWidget);
    expect(find.text(formatSoles(2490)), findsOneWidget);
    expect(
      find.text('El precio final lo confirma la tienda al hacer el pedido.'),
      findsOneWidget,
    );
  });

  testWidgets('sin descuentos muestra el subtotal, sin línea de descuentos', (
    tester,
  ) async {
    await pumpTicket(
      tester,
      const CartTicket(subtotalCents: 2490, discountCents: 0, totalCents: 2490),
    );

    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Descuentos'), findsNothing);
    expect(find.text('Total estimado'), findsOneWidget);
    // El subtotal y el total estimado: el mismo monto, dos veces.
    expect(find.text(formatSoles(2490)), findsNWidgets(2));
  });

  testWidgets('el borde de arriba es perforado, sobre el panel cálido', (
    tester,
  ) async {
    await pumpTicket(
      tester,
      const CartTicket(subtotalCents: 2490, discountCents: 0, totalCents: 2490),
    );

    final clip = tester.widget<ClipPath>(
      find.descendant(
        of: find.byType(CartTicket),
        matching: find.byType(ClipPath),
      ),
    );
    expect(clip.clipper, isA<PerforatedEdgeClipper>());
    final path = clip.clipper!.getClip(const Size(300, 200));
    // Las perforaciones: el centro de la primera queda afuera (18 agujeros
    // en 300 px: el primero centrado en 300 / 18 / 2).
    expect(path.contains(const Offset(300 / 18 / 2, 1)), isFalse);
    expect(path.contains(const Offset(300 / 18, 1)), isTrue);
    expect(path.contains(const Offset(150, 100)), isTrue);
    final paper = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(CartTicket),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(paper.color, NeilsPalette.light.surfaceAlt);
  });

  testWidgets('el ticket entra a 320 con el texto al 130 %', (tester) async {
    await pumpTicket(
      tester,
      const CartTicket(
        subtotalCents: 1234590,
        discountCents: 123450,
        totalCents: 1111140,
      ),
      width: 320,
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('en oscuro, el ticket va sobre el panel cálido oscuro', (
    tester,
  ) async {
    await pumpTicket(
      tester,
      const CartTicket(
        subtotalCents: 4980,
        discountCents: 2490,
        totalCents: 2490,
      ),
      brightness: Brightness.dark,
    );

    const dark = NeilsPalette.dark;
    final paper = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(CartTicket),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(paper.color, dark.surfaceAlt);
    expect(
      tester.widget<Text>(find.text('−${formatSoles(2490)}')).style?.color,
      dark.positive,
    );
    expect(tester.takeException(), isNull);
  });
}
