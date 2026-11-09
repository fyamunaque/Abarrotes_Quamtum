import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/cart/cart.dart';
import 'package:neils/cart/cart_storage.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/money.dart';
import 'package:neils/features/catalog/product_tile.dart';
import 'package:neils/features/shared/cart_bar.dart';
import 'package:neils/app.dart';
import 'package:neils/orders/orders_providers.dart';
import 'package:neils/router/router.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/neils_theme.dart';

import '../fakes.dart';
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

  final products = [
    for (var i = 0; i < 10; i++)
      Product(
        id: 'p$i',
        sku: '10$i',
        name: 'Producto $i',
        priceCents: 300 + i,
        stock: 20,
      ),
  ];

  Future<GoRouter> pumpStore(
    WidgetTester tester, {
    Cart cart = const Cart(),
    Size size = const Size(390, 844),
    String at = '/catalogo',
  }) async {
    final catalog = FakeCatalogRepository(productList: products);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => TestSession(const SignedOut())),
          cartStorageProvider.overrideWithValue(MemoryCartStorage(cart)),
          catalogRepositoryProvider.overrideWithValue(catalog),
          orderRepositoryProvider.overrideWithValue(
            FakeOrderRepository(catalog),
          ),
        ],
        child: const NeilsApp(),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NeilsApp)),
    );
    final router = container.read(routerProvider)..go(at);
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('con el carrito vacío no hay barra', (tester) async {
    await pumpStore(tester);

    expect(find.byType(CartBar), findsNothing);
  });

  testWidgets(
    'con productos muestra Continuar, la cantidad y el total, y lleva al '
    'carrito',
    (tester) async {
      final router = await pumpStore(
        tester,
        cart: const Cart([CartLine(ham, 3)]),
      );

      final bar = find.byType(CartBar);
      expect(bar, findsOneWidget);
      expect(
        find.descendant(of: bar, matching: find.text('Continuar')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bar, matching: find.text('3')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bar, matching: find.text(formatSoles(1320))),
        findsOneWidget,
      );

      await tester.tap(bar);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/carrito');
    },
  );

  testWidgets('se anuncia como un botón que se puede tocar', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: neilsTheme(),
        home: Scaffold(
          body: CartBar(
            label: 'Continuar',
            count: 3,
            totalCents: 1320,
            onPressed: () => taps++,
          ),
        ),
      ),
    );

    // El lector de pantalla lee la barra entera como un botón, y tocarla
    // desde ahí hace lo mismo que tocarla con el dedo.
    final node = tester.getSemantics(find.text('Continuar'));
    expect(node, isSemantics(isButton: true, hasTapAction: true));
    tester.semantics.tap(find.semantics.byLabel(RegExp('Continuar')));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('el número son las unidades y así se anuncia', (tester) async {
    final semantics = tester.ensureSemantics();
    Future<String> labelFor(int count) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: neilsTheme(),
          home: Scaffold(
            body: CartBar(
              label: 'Continuar',
              count: count,
              totalCents: 1320,
              onPressed: () {},
            ),
          ),
        ),
      );
      return tester.getSemantics(find.text('Continuar')).label;
    }

    expect(await labelFor(3), contains('3 unidades'));
    expect(await labelFor(1), contains('1 unidad'));
    expect(await labelFor(3), isNot(contains('productos')));
    semantics.dispose();
  });

  testWidgets('en escritorio no hay barra', (tester) async {
    await pumpStore(
      tester,
      cart: const Cart([CartLine(ham, 3)]),
      size: const Size(1280, 900),
    );

    expect(find.byType(CartBar), findsNothing);
  });

  testWidgets('el último producto queda visible sobre la barra', (
    tester,
  ) async {
    await pumpStore(tester, cart: const Cart([CartLine(ham, 1)]));

    // La pantalla, no la fila de categorías.
    final page = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    final last = find.text(productTitle(products.last));
    await tester.scrollUntilVisible(last, 400, scrollable: page.first);
    // Hasta el final de la lista.
    await tester.drag(page.first, const Offset(0, -2000));
    await tester.pumpAndSettle();

    final tile = tester.getRect(
      find.ancestor(of: last, matching: find.byType(ProductTile)).first,
    );
    expect(
      tile.bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(CartBar)).top),
    );
  });
}
