import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/cart/cart.dart';
import 'package:neils/cart/cart_provider.dart';
import 'package:neils/cart/cart_storage.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/money.dart';
import 'package:neils/features/catalog/line_total_pill.dart';
import 'package:neils/features/catalog/product_tile.dart';
import 'package:neils/features/catalog/promo_ribbon.dart';
import 'package:neils/features/catalog/stock_note.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/neils_theme.dart';

import '../support.dart';

void main() {
  useBundledFonts();

  const ham = Product(
    id: 'jamonada',
    sku: '3580',
    name: 'Jamonada especial',
    priceCents: 440,
    stock: 40,
  );

  late ProviderContainer container;

  Future<void> pumpTile(
    WidgetTester tester,
    Product product, {
    int inCart = 0,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: neilsTheme(),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [ProductTile(product: product)],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder plus() => find.widgetWithIcon(IconButton, Icons.add);

  testWidgets('muestra el código y el nombre', (tester) async {
    await pumpTile(tester, ham);

    expect(find.text('3580 – Jamonada especial'), findsOneWidget);
  });

  testWidgets('stockText avisa solo lo necesario', (tester) async {
    expect(stockText(0), 'Agotado');
    expect(stockText(1), 'Última unidad');
    expect(stockText(3), 'Últimas 3');
    expect(stockText(40), 'Disponible');

    const plenty = Product(
      id: 'jamonada',
      sku: '3580',
      name: 'Jamonada especial',
      priceCents: 440,
      stock: 37,
    );
    await pumpTile(tester, plenty);
    expect(find.text('Disponible'), findsOneWidget);
    // El stock total nunca se ve.
    expect(find.textContaining('37'), findsNothing);
  });

  testWidgets('el total de la línea sigue a la cantidad', (tester) async {
    await pumpTile(tester, ham);
    expect(find.text(formatSoles(440)), findsWidgets);

    await tester.tap(plus());
    await tester.pump();
    await tester.tap(plus());
    await tester.pump();

    expect(find.text(formatSoles(1320)), findsOneWidget);
  });

  testWidgets('la pastilla cuenta el 2x1', (tester) async {
    const twoForOne = Product(
      id: 'jamonada',
      sku: '3580',
      name: 'Jamonada especial',
      priceCents: 440,
      stock: 40,
      quantityDeals: [
        (type: 'buyXPayY', buyQuantity: 2, payQuantity: 1, percent: null),
      ],
    );
    await pumpTile(tester, twoForOne);

    await tester.tap(plus());
    await tester.pump();

    // Dos unidades con 2x1: se paga una.
    expect(
      find.descendant(
        of: find.byType(LineTotalPill),
        matching: find.text(formatSoles(440)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Agregar suma la cantidad al carrito', (tester) async {
    await pumpTile(tester, ham);
    await tester.tap(plus());
    await tester.pump();
    await tester.tap(plus());
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
    await tester.pump();

    expect(container.read(cartProvider).quantityOf('jamonada'), 3);
    expect(find.text('Editar'), findsOneWidget);
  });

  testWidgets('con el producto en el carrito dice Editar y su cantidad', (
    tester,
  ) async {
    await pumpTile(tester, ham, inCart: 2);

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Agregar'), findsNothing);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(plus());
    await tester.pump();
    await tester.tap(find.text('Editar'));
    await tester.pump();

    expect(container.read(cartProvider).quantityOf('jamonada'), 3);
  });

  testWidgets('en el máximo el + se deshabilita', (tester) async {
    const twoLeft = Product(
      id: 'jamonada',
      sku: '3580',
      name: 'Jamonada especial',
      priceCents: 440,
      stock: 2,
    );
    await pumpTile(tester, twoLeft, inCart: 2);

    expect(tester.widget<IconButton>(plus()).onPressed, isNull);
    expect(find.text('Últimas 2'), findsOneWidget);
  });

  testWidgets('agotado no se puede agregar', (tester) async {
    const soldOut = Product(
      id: 'jamonada',
      sku: '3580',
      name: 'Jamonada especial',
      priceCents: 440,
      stock: 0,
    );
    await pumpTile(tester, soldOut);

    final button = find.ancestor(
      of: find.text('Agotado').last,
      matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
    );
    expect(button, findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
  });

  testWidgets('la cinta muestra la promoción', (tester) async {
    const withOffer = Product(
      id: 'jamonada',
      sku: '3580',
      name: 'Jamonada especial',
      priceCents: 440,
      stock: 40,
      offers: [
        (
          type: 'buyXPayY',
          label: '2x1',
          title: null,
          description: '2x1 en este producto',
        ),
      ],
    );
    await pumpTile(tester, withOffer);

    expect(
      find.descendant(of: find.byType(PromoRibbon), matching: find.text('2x1')),
      findsOneWidget,
    );
  });

  testWidgets('una cinta larga no tapa el nombre, con texto al 130 %', (
    tester,
  ) async {
    const withLongOffer = Product(
      id: 'jamonada',
      sku: '3580',
      name: 'Jamonada especial de pavo ahumado en paquete familiar',
      priceCents: 440,
      stock: 40,
      offers: [
        (
          type: 'extraUnit',
          label: '2.ª al 50 %',
          title: null,
          description: 'La 2.ª unidad al 50 %',
        ),
      ],
    );
    await pumpTile(tester, withLongOffer, textScale: 1.3);

    final title = tester.getRect(find.text(productTitle(withLongOffer)));
    final ribbon = tester.getRect(find.byType(PromoRibbon));
    expect(title.overlaps(ribbon), isFalse, reason: '$title y $ribbon');
    expect(tester.takeException(), isNull);
  });

  testWidgets('un nombre largo no se desborda en 360 px con texto al 130 %', (
    tester,
  ) async {
    const longName = Product(
      id: 'jamonada',
      sku: '3580',
      name: 'Jamonada especial de pavo ahumado en paquete familiar de 500 g',
      priceCents: 1990,
      stock: 40,
    );
    await pumpTile(
      tester,
      longName,
      size: const Size(360, 800),
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Agregar').hitTestable(), findsOneWidget);
  });
}
