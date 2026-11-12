import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/appearance/appearance.dart';
import 'package:neils/appearance/appearance_providers.dart';
import 'package:neils/appearance/appearance_repository.dart';
import 'package:neils/cart/cart.dart';
import 'package:neils/cart/cart_storage.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/features/cart/add_to_cart.dart';
import 'package:neils/features/cart/cart_notice.dart';
import 'package:neils/features/catalog/product_photo.dart';
import 'package:neils/features/shared/cart_bar.dart';
import 'package:neils/orders/orders_providers.dart';
import 'package:neils/router/router.dart';
import 'package:neils/router/routes.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/neils_theme.dart';
import 'package:neils/theme/palette.dart';

import '../fakes.dart';
import '../support.dart';

void main() {
  useBundledFonts();

  final products = [
    for (var i = 0; i < 4; i++)
      Product(
        id: 'p$i',
        sku: '10$i',
        name: 'Producto $i',
        priceCents: 300 + i,
        stock: 20,
      ),
  ];

  /// La tienda entera en un teléfono, en el catálogo.
  Future<GoRouter> pumpStore(
    WidgetTester tester, {
    Cart cart = const Cart(),
    Size size = const Size(390, 844),
    ThemePreference appearance = ThemePreference.light,
  }) async {
    final catalog = FakeCatalogRepository(productList: products);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appearanceRepositoryProvider.overrideWithValue(
            MemoryAppearanceRepository(appearance),
          ),
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
    final router = container.read(routerProvider)..go('/catalogo');
    await tester.pumpAndSettle();
    return router;
  }

  Finder inRow(String id, String text) =>
      find.descendant(of: find.byKey(ValueKey(id)), matching: find.text(text));

  Finder inNotice(Finder finder) =>
      find.descendant(of: find.byType(CartNotice), matching: finder);

  Future<void> addFirst(WidgetTester tester) async {
    await tester.tap(inRow('p0', 'Agregar'));
    await tester.pumpAndSettle();
  }

  String path(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  testWidgets(
    'al agregar, la tarjeta muestra la foto, el nombre y "Ver carrito"',
    (tester) async {
      await pumpStore(tester);
      await addFirst(tester);

      expect(find.byType(CartNotice), findsOneWidget);
      expect(inNotice(find.text('Agregado al carrito')), findsOneWidget);
      expect(inNotice(find.text('Producto 0')), findsOneWidget);
      expect(inNotice(find.byType(ProductPhoto)), findsOneWidget);
      expect(inNotice(find.text('Ver carrito')), findsOneWidget);
    },
  );

  testWidgets('se va sola a los 3 segundos', (tester) async {
    await pumpStore(tester);
    await addFirst(tester);
    expect(find.byType(CartNotice), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(CartNotice), findsNothing);
  });

  testWidgets('"Ver carrito" lleva al carrito y cierra el aviso', (
    tester,
  ) async {
    final router = await pumpStore(tester);
    await addFirst(tester);

    await tester.tap(inNotice(find.text('Ver carrito')));
    await tester.pumpAndSettle();

    expect(path(router), Routes.cart);
    expect(find.byType(CartNotice), findsNothing);
  });

  testWidgets('se cierra al deslizarla hacia abajo', (tester) async {
    await pumpStore(tester);
    await addFirst(tester);

    await tester.drag(find.byType(CartNotice), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(find.byType(CartNotice), findsNothing);
  });

  testWidgets('en el teléfono flota sobre la barra roja del carrito', (
    tester,
  ) async {
    await pumpStore(tester);
    await addFirst(tester);

    final notice = tester.getRect(find.byType(CartNotice));
    final bar = tester.getRect(find.byType(CartBar));
    expect(notice.bottom, lessThanOrEqualTo(bar.top));
  });

  testWidgets('al editar la cantidad dice cuántas lleva', (tester) async {
    await pumpStore(tester, cart: Cart([CartLine(products.first, 2)]));

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('p0')),
        matching: find.byTooltip('Agregar uno'),
      ),
    );
    await tester.pump();
    await tester.tap(inRow('p0', 'Editar'));
    await tester.pumpAndSettle();

    expect(inNotice(find.text('Ahora llevas 3')), findsOneWidget);
    expect(inNotice(find.text('Producto 0')), findsOneWidget);
  });

  testWidgets('con todo el stock ya en el carrito, lo dice', (tester) async {
    const last = Product(
      id: 'ultimo',
      sku: '200',
      name: 'Queso andino',
      priceCents: 1500,
      stock: 1,
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => addToCart(context, ref, last),
                child: const Text('Probar'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: Routes.cart,
          builder: (context, _) => const Scaffold(body: Text('El carrito')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => TestSession(const SignedOut())),
          cartStorageProvider.overrideWithValue(
            MemoryCartStorage(const Cart([CartLine(last, 1)])),
          ),
        ],
        child: MaterialApp.router(theme: neilsTheme(), routerConfig: router),
      ),
    );

    await tester.tap(find.text('Probar'));
    await tester.pumpAndSettle();

    expect(inNotice(find.text('Ya tienes todo el stock')), findsOneWidget);
    expect(inNotice(find.text('Queso andino')), findsOneWidget);
    expect(inNotice(find.byIcon(Icons.info_outline)), findsOneWidget);
  });

  testWidgets('en 320 px con el texto al 130 % entra entera', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpStore(tester, size: const Size(320, 700));
    await addFirst(tester);

    expect(tester.takeException(), isNull);
    expect(inNotice(find.text('Ver carrito')).hitTestable(), findsOneWidget);
  });

  testWidgets('en oscuro va sobre la tarjeta oscura, con su borde', (
    tester,
  ) async {
    await pumpStore(tester, appearance: ThemePreference.dark);
    await addFirst(tester);

    const dark = NeilsPalette.dark;
    final card = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(CartNotice),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(card.color, dark.surface);
    expect((card.shape! as RoundedRectangleBorder).side.color, dark.line);
    expect(
      tester.widget<Icon>(inNotice(find.byIcon(Icons.check_circle))).color,
      dark.positive,
    );
  });
}
