import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/cart/cart.dart';
import 'package:neils/cart/cart_storage.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/app.dart';
import 'package:neils/features/catalog/offer_badges.dart';
import 'package:neils/features/catalog/product_detail_screen.dart';
import 'package:neils/features/catalog/product_photo.dart';
import 'package:neils/features/catalog/product_tile.dart';
import 'package:neils/features/shared/cart_button.dart';
import 'package:neils/router/router.dart';
import 'package:neils/router/routes.dart';
import 'package:neils/theme/palette.dart';
import 'package:neils/features/catalog/promo_tag.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/neils_theme.dart';

import '../fakes.dart';
import '../support.dart';

/// El detalle de un producto: lo que dice del stock, el código y "Editar".
void main() {
  useBundledFonts();

  Product ham({int stock = 37}) => Product(
    id: 'jamonada',
    sku: '3580',
    name: 'Jamonada especial',
    priceCents: 1290,
    stock: stock,
    category: groceries,
    offers: const [
      (
        type: 'buyXPayY',
        label: '2x1',
        title: null,
        description: '2x1 en este producto',
      ),
    ],
  );

  Future<void> pumpDetail(
    WidgetTester tester,
    Product product, {
    int inCart = 0,
    Size size = const Size(1280, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => TestSession(const SignedOut())),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(productList: [product]),
          ),
          cartStorageProvider.overrideWithValue(
            MemoryCartStorage(
              inCart == 0 ? const Cart() : Cart([CartLine(product, inCart)]),
            ),
          ),
        ],
        child: MaterialApp(
          theme: neilsTheme(),
          home: ProductDetailScreen(productId: product.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el detalle no muestra las unidades en stock', (tester) async {
    await pumpDetail(tester, ham());

    expect(find.text('Disponible'), findsOneWidget);
    expect(find.textContaining('37'), findsNothing);
  });

  testWidgets('con pocas avisa cuántas quedan', (tester) async {
    await pumpDetail(tester, ham(stock: 3));

    expect(find.text('Últimas 3'), findsOneWidget);
  });

  testWidgets('con el producto en el carrito dice Editar', (tester) async {
    await pumpDetail(tester, ham(), inCart: 2);

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Tienes 2 en el carrito.'), findsOneWidget);
  });

  testWidgets('muestra el código antes del nombre y la cinta', (tester) async {
    await pumpDetail(tester, ham());

    expect(find.text('3580 – Jamonada especial'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(PromoTag), matching: find.text('2x1')),
      findsOneWidget,
    );
  });

  /// La app entera en [at], con el catálogo de [products].
  Future<String Function()> pumpApp(
    WidgetTester tester, {
    required String at,
    required List<Product> products,
    Size size = const Size(1280, 900),
    bool settle = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => TestSession(const SignedOut())),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(productList: products),
          ),
        ],
        child: const NeilsApp(),
      ),
    );
    final router = ProviderScope.containerOf(
      tester.element(find.byType(NeilsApp)),
    ).read(routerProvider)..go(at);
    await tester.pumpAndSettle();
    return () => router.routerDelegate.currentConfiguration.uri.toString();
  }

  testWidgets('en el teléfono, Volver y el carrito sobre la foto', (
    tester,
  ) async {
    await pumpDetail(tester, ham(), size: const Size(390, 844));

    // Sin la barra de arriba: la foto llega al borde.
    expect(find.byType(AppBar), findsNothing);
    final photo = tester.getRect(find.byType(ProductPhoto).first);
    expect(photo.width, 390);
    for (final button in [find.byTooltip('Volver'), find.byType(CartButton)]) {
      final rect = tester.getRect(button);
      expect(photo.contains(rect.center), isTrue, reason: '$button');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('en escritorio, la ruta lleva a la categoría', (tester) async {
    final location = await pumpApp(
      tester,
      at: Routes.product('jamonada'),
      products: [ham()],
    );

    final crumbs = find.byKey(const ValueKey('ruta'));
    expect(
      find.descendant(of: crumbs, matching: find.text('Catálogo')),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: crumbs, matching: find.text(groceries.name)),
    );
    await tester.pumpAndSettle();

    expect(location(), Routes.catalogOf(groceries.id));
  });

  testWidgets('la promoción se explica en su recuadro', (tester) async {
    await pumpDetail(tester, ham());

    final box = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.byType(OfferDescriptions),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (box.decoration as BoxDecoration).color,
      NeilsPalette.light.surfaceAlt,
    );
  });

  testWidgets('la foto es el mismo Hero que la fila', (tester) async {
    await pumpApp(
      tester,
      at: Routes.catalog,
      products: [ham()],
      size: const Size(390, 844),
    );

    Finder heroes() => find.byWidgetPredicate(
      (w) => w is Hero && w.tag == productHeroTag(ham()),
    );
    await tester.tap(find.text(productTitle(ham())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // En vuelo: el de la fila y el del detalle.
    expect(heroes(), findsNWidgets(2));

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(heroes(), findsOneWidget);
  });
}
