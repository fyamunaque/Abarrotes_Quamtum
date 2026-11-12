import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/features/catalog/promo_tag.dart';
import 'package:neils/theme/neils_theme.dart';
import 'package:neils/theme/palette.dart';

import '../support.dart';

/// La etiqueta de mercado: recta, con borde punteado rojo y el texto en el
/// rojo de los textos.
void main() {
  useBundledFonts();

  const twoForOne = (
    type: 'buyXPayY',
    label: '2x1',
    title: null,
    description: '2x1 en este producto',
  );
  const gift = (
    type: 'gift',
    label: 'Regalo: Sal 1 kg',
    title: null,
    description: 'Regalo: Sal 1 kg por cada 2',
  );
  const secondHalf = (
    type: 'nthUnitPercent',
    label: '2.ª al 50 %',
    title: null,
    description: 'La 2.ª unidad al 50 %',
  );

  Future<void> pumpTag(
    WidgetTester tester,
    Widget tag, {
    Brightness brightness = Brightness.light,
    double width = 390,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: neilsTheme(brightness),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 400),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(alignment: Alignment.topLeft, child: tag),
            ),
          ),
        ),
      ),
    );
  }

  DashedBorderPainter painterOf(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byType(PromoTag),
                  matching: find.byType(CustomPaint),
                ),
              )
              .painter!
          as DashedBorderPainter;

  testWidgets('muestra la primera promoción y el lector dice todas', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpTag(tester, const PromoTag([twoForOne, gift]));

    expect(find.text('2x1'), findsOneWidget);
    expect(find.text('+ regalo'), findsNothing);
    expect(
      find.bySemanticsLabel(
        '2x1 en este producto. Regalo: Sal 1 kg por cada 2',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('un regalo dice "+ regalo", y el del carrito "Regalo"', (
    tester,
  ) async {
    await pumpTag(tester, const PromoTag([gift]));
    expect(find.text('+ regalo'), findsOneWidget);

    await pumpTag(tester, const PromoTag.gift());
    expect(find.text('Regalo'), findsOneWidget);
  });

  testWidgets('en claro, borde rojo punteado y texto brandText', (
    tester,
  ) async {
    await pumpTag(tester, const PromoTag([twoForOne]));

    const light = NeilsPalette.light;
    expect(painterOf(tester).color, light.brandFill);
    expect(painterOf(tester).dash, greaterThan(0));
    expect(tester.widget<Text>(find.text('2x1')).style?.color, light.brandText);
  });

  testWidgets('en oscuro, borde rojo y texto brandText', (tester) async {
    await pumpTag(
      tester,
      const PromoTag([twoForOne]),
      brightness: Brightness.dark,
    );

    const dark = NeilsPalette.dark;
    expect(painterOf(tester).color, dark.brandFill);
    expect(tester.widget<Text>(find.text('2x1')).style?.color, dark.brandText);
  });

  testWidgets('sin promociones no ocupa lugar', (tester) async {
    await pumpTag(tester, const PromoTag([]));

    expect(tester.getSize(find.byType(PromoTag)), Size.zero);
    expect(
      find.descendant(
        of: find.byType(PromoTag),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });

  testWidgets('la etiqueta va en lugar de "Disponible", no de los avisos', (
    tester,
  ) async {
    Product product({required int stock, bool offer = true}) => Product(
      id: 'jamonada',
      name: 'Jamonada',
      priceCents: 440,
      stock: stock,
      offers: offer ? const [twoForOne] : const [],
    );

    await pumpTag(tester, TagOrStock(product(stock: 40)));
    expect(find.text('2x1'), findsOneWidget);
    expect(find.text('Disponible'), findsNothing);

    await pumpTag(tester, TagOrStock(product(stock: 4)));
    expect(find.text('2x1'), findsOneWidget);
    expect(find.text('Últimas 4'), findsOneWidget);

    await pumpTag(tester, TagOrStock(product(stock: 40, offer: false)));
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.byType(PromoTag), findsNothing);
  });

  testWidgets('"2.ª al 50 %" entra a 320 con el texto al 130 %', (
    tester,
  ) async {
    await pumpTag(
      tester,
      const PromoTag([secondHalf]),
      width: 320,
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('2.ª al 50 %'), findsOneWidget);
    // En una sola línea: no se parte la etiqueta.
    final text = tester.getSize(find.text('2.ª al 50 %'));
    expect(text.height, lessThan(30));
    expect(tester.getSize(find.byType(PromoTag)).width, lessThan(320 - 32));
  });
}
