import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/cart/cart_provider.dart';
import 'package:neils/features/catalog/product_card.dart';
import 'package:neils/features/home/home_screen.dart';
import 'package:neils/features/shared/brand.dart';
import 'package:neils/offers/offer.dart';
import 'package:neils/offers/offers_providers.dart';
import 'package:neils/router/router.dart';
import 'package:neils/features/shared/swoosh.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/brand_colors.dart';
import 'package:neils/theme/neils_theme.dart';

import '../fakes.dart';
import '../support.dart';

void main() {
  useBundledFonts();

  late TestSession session;
  late FakeCatalogRepository catalog;
  late FakeOffersRepository offers;

  setUp(() {
    catalog = FakeCatalogRepository();
    offers = FakeOffersRepository();
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    Session signedIn = const SignedOut(),
  }) async {
    session = TestSession(signedIn);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => session),
          catalogRepositoryProvider.overrideWithValue(catalog),
          offersRepositoryProvider.overrideWithValue(offers),
        ],
        child: MaterialApp(theme: neilsTheme(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el swoosh subraya la segunda línea del titular', (tester) async {
    await pumpHome(tester);

    expect(find.byType(AnimatedSwoosh), findsOneWidget);
    final line = tester.getRect(find.text('a la puerta de tu casa'));
    final swoosh = tester.getRect(find.byType(AnimatedSwoosh));
    expect(swoosh.width, closeTo(line.width, 1));
    expect(swoosh.center.dy, greaterThan(line.center.dy));
  });

  testWidgets('deslizar hacia abajo vuelve a pedir el perfil', (tester) async {
    await pumpHome(tester, signedIn: signedInAs(UserRole.customer));

    // La de la pantalla, no la de una fila de productos.
    await tester.fling(
      find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.vertical,
      ),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(session.refreshes, 1);
  });

  /// La app entera, con el router: para seguir los enlaces.
  Future<(GoRouter, ProviderContainer)> pumpApp(
    WidgetTester tester, {
    Session signedIn = const SignedOut(),
    double width = 1280,
  }) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    session = TestSession(signedIn);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => session),
          catalogRepositoryProvider.overrideWithValue(catalog),
          offersRepositoryProvider.overrideWithValue(offers),
        ],
        child: const NeilsApp(),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NeilsApp)),
    );
    final router = container.read(routerProvider)..go('/');
    await tester.pumpAndSettle();
    return (router, container);
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  List<String> shownProducts(WidgetTester tester) => [
    for (final card in tester.widgetList<ProductCard>(find.byType(ProductCard)))
      card.product.id,
  ];

  testWidgets('sin el logo en la barra: la portada ya lo muestra en grande', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.byType(NeilsLogo), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(NeilsLogo),
      ),
      findsNothing,
    );
  });

  testWidgets('las categorías llevan al catálogo filtrado', (tester) async {
    final (router, _) = await pumpApp(tester);

    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Abarrotes'), findsOneWidget);
    await tester.ensureVisible(find.text('Lácteos'));
    await tester.tap(find.text('Lácteos'));
    await tester.pumpAndSettle();

    expect(location(router), '/catalogo?categoria=cat-lacteos');
  });

  testWidgets('cada categoría con otro color, en orden', (tester) async {
    await pumpApp(tester);

    Color colorOf(String name) => tester
        .widget<Material>(
          find
              .ancestor(of: find.text(name), matching: find.byType(Material))
              .first,
        )
        .color!;
    expect(colorOf('Abarrotes'), PlaceholderColors.pairs[0].$1);
    expect(colorOf('Lácteos'), PlaceholderColors.pairs[1].$1);
  });

  testWidgets('en el teléfono, las categorías van de a dos', (tester) async {
    await pumpApp(tester, width: 375);

    expect(
      tester.getTopLeft(find.text('Abarrotes')).dy,
      tester.getTopLeft(find.text('Lácteos')).dy,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Promociones de hoy": los productos en oferta, con Agregar', (
    tester,
  ) async {
    final (_, container) = await pumpApp(tester);

    expect(find.text('Promociones de hoy'), findsOneWidget);
    expect(shownProducts(tester), ['aceite']);
    expect(catalog.onSaleRequests, contains(true));

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Agregar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
    await tester.pumpAndSettle();
    expect(container.read(cartProvider).quantityOf('aceite'), 1);
  });

  testWidgets('sin promociones, no hay "Promociones de hoy"', (tester) async {
    catalog = FakeCatalogRepository(productList: const [rice, milk]);
    await pumpApp(tester);

    expect(find.text('Promociones de hoy'), findsNothing);
    expect(find.byType(ProductCard), findsNothing);
  });

  testWidgets('a una cuenta VIP no le repite sus ofertas exclusivas', (
    tester,
  ) async {
    offers = FakeOffersRepository(const [
      Offer(
        id: 'o-1',
        productId: 'aceite',
        productName: 'Aceite vegetal 1 L',
        priceCents: 1090,
        promoPriceCents: 790,
        endDate: '2026-10-31',
        vip: true,
      ),
    ]);
    final customer = signedInAs(UserRole.customer);
    await pumpApp(
      tester,
      signedIn: SignedIn(customer.user.copyWith(isVip: true)),
    );

    expect(find.text('Ofertas exclusivas'), findsOneWidget);
    expect(find.text('Promociones de hoy'), findsNothing);
  });

  testWidgets('el titular se lee como un solo encabezado', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    expect(
      tester.getSemantics(find.text('Tus abarrotes,')),
      matchesSemantics(
        label: 'Tus abarrotes,\na la puerta de tu casa',
        isHeader: true,
      ),
    );
    semantics.dispose();
  });
}
