import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/cart/cart.dart';
import 'package:neils/cart/cart_provider.dart';
import 'package:neils/cart/cart_storage.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/money.dart';
import 'package:neils/features/catalog/price_tag.dart';
import 'package:neils/features/catalog/product_card.dart';
import 'package:neils/features/catalog/promo_tag.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/brand_colors.dart';
import 'package:neils/theme/motion.dart';
import 'package:neils/theme/neils_theme.dart';
import 'package:neils/theme/palette.dart';

import '../support.dart';

void main() {
  useBundledFonts();

  const rice = Product(
    id: 'arroz',
    name: 'Arroz extra 5 kg',
    priceCents: 2490,
    stock: 12,
  );

  late ProviderContainer container;

  Future<void> pumpCard(
    WidgetTester tester,
    Product product, {
    int inCart = 0,
    bool reduceMotion = false,
  }) {
    container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(() => TestSession(const SignedOut())),
        cartStorageProvider.overrideWithValue(
          MemoryCartStorage(
            inCart == 0 ? const Cart() : Cart([CartLine(product, inCart)]),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: neilsTheme(),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 240,
                  child: ProductCard(product: product),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // El precio, no el total de la pastilla (que con 1 unidad dice lo mismo).
  Finder priceText(String text) =>
      find.descendant(of: find.byType(PriceTag), matching: find.text(text));

  double addScale(WidgetTester tester) => tester
      .widget<AnimatedScale>(
        find.ancestor(
          of: find.byType(FilledButton),
          matching: find.byType(AnimatedScale),
        ),
      )
      .scale;

  testWidgets('muestra el nombre y el precio', (tester) async {
    await pumpCard(tester, rice);

    expect(find.text('Arroz extra 5 kg'), findsOneWidget);
    expect(priceText('S/ 24.90'), findsOneWidget);
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

    expect(priceText('S/ 8.90'), findsOneWidget);
    final before = tester.widget<Text>(find.text('S/ 10.90'));
    expect(before.style?.decoration, TextDecoration.lineThrough);
    expect(before.semanticsLabel, 'Antes S/ 10.90');
  });

  testWidgets('la cinta muestra la primera promoción y el lector dice todas', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpCard(
      tester,
      const Product(
        id: 'aceite',
        name: 'Aceite vegetal 1 L',
        priceCents: 1090,
        stock: 30,
        offers: [
          (
            type: 'buyXPayY',
            label: '2x1',
            title: null,
            description: '2x1 en este producto',
          ),
          (
            type: 'gift',
            label: 'Regalo: Sal 1 kg',
            title: null,
            description: 'Regalo: Sal 1 kg por cada 2',
          ),
        ],
      ),
    );

    expect(
      find.descendant(of: find.byType(PromoTag), matching: find.text('2x1')),
      findsOneWidget,
    );
    // El lector de pantalla dice qué da cada una.
    expect(
      find.bySemanticsLabel(RegExp('2x1 en este producto')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Regalo: Sal 1 kg por cada 2')),
      findsOneWidget,
    );
    // Sin precio tachado: el 2x1 no cambia el precio por unidad.
    expect(priceText(formatSoles(1090)), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('con 20 % menos: el precio tachado y S/ 3.60', (tester) async {
    await pumpCard(
      tester,
      Product.fromJson({
        'id': 'fideos',
        'name': 'Fideos 500 g',
        'price': '4.5',
        'unitPrice': '3.6',
        'currentStock': 20,
        'promotion': null,
        'promotions': [
          {
            'id': 'pr-1',
            'type': 'percentOff',
            'label': '20 % menos',
            'audience': 'everyone',
            'percent': 20,
          },
        ],
      }),
    );

    expect(priceText(formatSoles(360)), findsOneWidget);
    final before = tester.widget<Text>(find.text(formatSoles(450)));
    expect(before.style?.decoration, TextDecoration.lineThrough);
  });

  group('precio VIP', () {
    const vipOil = Product(
      id: 'aceite',
      name: 'Aceite vegetal 1 L',
      priceCents: 1090,
      promoPriceCents: 790,
      vipPrice: true,
      stock: 30,
    );

    double revealOpacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find.descendant(
            of: find.byType(VipReveal),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;

    testWidgets('el precio VIP, el normal tachado y la insignia', (
      tester,
    ) async {
      await pumpCard(tester, vipOil);
      await tester.pumpAndSettle();

      expect(priceText(formatSoles(790)), findsOneWidget);
      final before = tester.widget<Text>(find.text(formatSoles(1090)));
      expect(before.style?.decoration, TextDecoration.lineThrough);
      final tag = tester.widget<Text>(find.text('VIP'));
      expect(tag.style?.color, NeilsPalette.light.brandText);
      expect(tag.semanticsLabel, 'Precio VIP');
      final box =
          tester
                  .widget<Container>(
                    find.ancestor(
                      of: find.text('VIP'),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      expect(box.color, NeilsColors.surface);
    });

    testWidgets('la entrada VIP empieza en 0,97', (tester) async {
      await pumpCard(tester, vipOil);

      final transform = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(VipReveal),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(transform.transform.entry(0, 0), closeTo(0.97, 0.001));
    });

    testWidgets('entra en unos 300 ms, una sola vez', (tester) async {
      await pumpCard(tester, vipOil);

      expect(revealOpacity(tester), 0);
      await tester.pump(const Duration(milliseconds: 150));
      expect(revealOpacity(tester), allOf(greaterThan(0), lessThan(1)));
      await tester.pump(NeilsMotion.reveal);
      expect(revealOpacity(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);

      // Otra vez el mismo producto (p. ej. la lista se reconstruye): no se
      // repite.
      await pumpCard(tester, vipOil);
      expect(revealOpacity(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('con "reducir animaciones" aparece directo', (tester) async {
      await pumpCard(tester, vipOil, reduceMotion: true);
      await tester.pump();

      expect(revealOpacity(tester), 1);
    });

    testWidgets('sin precio VIP no hay insignia ni animación', (tester) async {
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

      expect(find.text('VIP'), findsNothing);
      expect(find.byType(VipReveal), findsNothing);
    });
  });

  testWidgets('"Agregar" suma al carrito y pasa a "Editar"', (tester) async {
    await pumpCard(tester, rice);

    await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
    await tester.pumpAndSettle();

    expect(container.read(cartProvider).quantityOf('arroz'), 1);
    expect(find.text('Editar'), findsOneWidget);
  });

  testWidgets('con el producto en el carrito muestra su cantidad', (
    tester,
  ) async {
    await pumpCard(tester, rice, inCart: 3);

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    // El total de la pastilla: 3 × S/ 24.90.
    expect(find.text(formatSoles(7470)), findsOneWidget);
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

    // Se cancela en vez de soltar: soltar es un toque, que agregaría.
    await gesture.cancel();
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
    await pumpCard(
      tester,
      const Product(
        id: 'azucar',
        name: 'Azúcar rubia 1 kg',
        priceCents: 450,
        stock: 0,
      ),
    );

    expect(find.text('Agregar'), findsNothing);
    final button = find.widgetWithText(FilledButton, 'Agotado');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump();
    expect(addScale(tester), 1);
    await gesture.up();
    expect(container.read(cartProvider).quantityOf('azucar'), 0);
  });
}
