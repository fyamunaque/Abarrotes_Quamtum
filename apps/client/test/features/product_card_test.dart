import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/features/catalog/product_card.dart';
import 'package:neils/features/shared/swoosh.dart';
import 'package:neils/theme/motion.dart';
import 'package:neils/theme/neils_theme.dart';

import '../support.dart';

void main() {
  useBundledFonts();

  const rice = Product(
    id: 'arroz',
    name: 'Arroz extra 5 kg',
    priceCents: 2490,
    stock: 12,
  );

  Future<void> pumpCard(
    WidgetTester tester,
    Product product, {
    VoidCallback? onAdd,
    bool reduceMotion = false,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: neilsTheme(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 220,
              child: ProductCard(product: product, onAdd: onAdd ?? () {}),
            ),
          ),
        ),
      ),
    ),
  );

  double addScale(WidgetTester tester) => tester
      .widget<AnimatedScale>(
        find.ancestor(
          of: find.byType(FilledButton),
          matching: find.byType(AnimatedScale),
        ),
      )
      .scale;

  testWidgets('muestra el nombre y el precio subrayado con el swoosh', (
    tester,
  ) async {
    await pumpCard(tester, rice);

    expect(find.text('Arroz extra 5 kg'), findsOneWidget);
    expect(find.text('S/ 24.90'), findsOneWidget);
    final price = tester.getRect(find.text('S/ 24.90'));
    final underline = tester.getRect(find.byType(Swoosh));
    expect(underline.width, closeTo(price.width, 1));
    expect(underline.top, greaterThan(price.center.dy));
  });

  testWidgets('un nombre corto y uno largo dan tarjetas de igual alto', (
    tester,
  ) async {
    await pumpCard(tester, rice);
    final short = tester.getSize(find.byType(ProductCard)).height;

    await pumpCard(
      tester,
      const Product(
        id: 'leche',
        name: 'Leche evaporada entera, paquete de 6 latas de 400 g',
        priceCents: 2350,
        stock: 8,
      ),
    );

    expect(tester.getSize(find.byType(ProductCard)).height, short);
  });

  testWidgets('en promoción muestra el precio normal tachado', (tester) async {
    await pumpCard(
      tester,
      const Product(
        id: 'aceite',
        name: 'Aceite vegetal 1 L',
        priceCents: 1090,
        promoPriceCents: 890,
        stock: 30,
      ),
    );

    expect(find.text('S/ 8.90'), findsOneWidget);
    final before = tester.widget<Text>(find.text('S/ 10.90'));
    expect(before.style?.decoration, TextDecoration.lineThrough);
    expect(before.semanticsLabel, 'Antes S/ 10.90');
  });

  testWidgets('"Agregar" llama a onAdd', (tester) async {
    var added = 0;
    await pumpCard(tester, rice, onAdd: () => added++);

    await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
    await tester.pumpAndSettle();

    expect(added, 1);
  });

  testWidgets('"Agregar" se achica mientras se presiona y vuelve al soltar', (
    tester,
  ) async {
    await pumpCard(tester, rice);
    expect(addScale(tester), 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Agregar')),
    );
    await tester.pump();
    expect(addScale(tester), lessThan(1));
    await tester.pump(NeilsMotion.press);
    final pressed = tester.getSize(find.byType(FilledButton));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(addScale(tester), 1);
    // AnimatedScale no cambia el layout: lo achica al pintarlo.
    expect(tester.getSize(find.byType(FilledButton)), pressed);
  });

  testWidgets('con "reducir animaciones" no cambia de tamaño', (tester) async {
    await pumpCard(tester, rice, reduceMotion: true);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Agregar')),
    );
    await tester.pump();
    expect(addScale(tester), 1);
    await gesture.up();
  });

  testWidgets('sin stock dice "Agotado" y no deja agregar', (tester) async {
    var added = 0;
    await pumpCard(
      tester,
      const Product(
        id: 'azucar',
        name: 'Azúcar rubia 1 kg',
        priceCents: 450,
        stock: 0,
      ),
      onAdd: () => added++,
    );

    expect(find.text('Agregar'), findsNothing);
    final button = find.widgetWithText(FilledButton, 'Agotado');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump();
    expect(addScale(tester), 1);
    await gesture.up();
    expect(added, 0);
  });
}
