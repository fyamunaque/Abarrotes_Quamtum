import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/cart/cart_provider.dart';
import 'package:neils/features/catalog/category_card.dart';
import 'package:neils/features/catalog/product_card.dart';
import 'package:neils/features/catalog/product_tile.dart';
import 'package:neils/features/home/home_screen.dart';
import 'package:neils/features/shared/brand.dart';
import 'package:neils/features/shared/brand_hero.dart';
import 'package:neils/features/shared/store_search_field.dart';
import 'package:neils/offers/offer.dart';
import 'package:neils/offers/offers_providers.dart';
import 'package:neils/router/router.dart';
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

  testWidgets('el logo va en la barra', (tester) async {
    await pumpHome(tester);

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(NeilsLogo),
      ),
      findsOneWidget,
    );
  });

  testWidgets('escritorio: el titular para negocios y sus botones', (
    tester,
  ) async {
    final (router, _) = await pumpApp(tester);

    expect(
      find.textContaining('Tu negocio siempre abastecido'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Insumos gastronómicos de calidad, con precios competitivos y '
        'entrega confiable.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Ver catálogo'), findsOneWidget);
    // El mensaje ya no es para hogares.
    expect(find.textContaining('abarrotes'), findsNothing);
    expect(find.textContaining('tu casa'), findsNothing);

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Ver promociones').first,
    );
    await tester.pumpAndSettle();
    expect(location(router), '/catalogo?promos=1');
  });

  testWidgets('los tres sellos y la banda de promociones', (tester) async {
    await pumpApp(tester);

    expect(find.byType(TrustBadges), findsOneWidget);
    expect(find.text('Promociones para tu negocio'), findsOneWidget);
    expect(
      find.text(
        'Soluciones prácticas para restaurantes, fast foods y dark kitchens.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Nuestras categorías lleva al catálogo de la categoría', (
    tester,
  ) async {
    final (router, _) = await pumpApp(tester);

    expect(find.text('Nuestras categorías'), findsOneWidget);
    expect(find.byType(CategoryCard), findsNWidgets(2));
    await tester.ensureVisible(find.text('Lácteos'));
    await tester.tap(find.text('Lácteos'));
    await tester.pumpAndSettle();

    expect(location(router), '/catalogo?categoria=cat-lacteos');
  });

  testWidgets('cada categoría con otro color, en orden', (tester) async {
    await pumpApp(tester);

    Color colorOf(String name) => tester
        .widget<ColoredBox>(
          find
              .descendant(
                of: find.ancestor(
                  of: find.text(name),
                  matching: find.byType(CategoryCard),
                ),
                matching: find.byType(ColoredBox),
              )
              .first,
        )
        .color;
    expect(colorOf('Abarrotes'), PlaceholderColors.pairs[0].$1);
    expect(colorOf('Lácteos'), PlaceholderColors.pairs[1].$1);
  });

  testWidgets('en el teléfono, las categorías van en una fila', (
    tester,
  ) async {
    await pumpApp(tester, width: 375);

    expect(
      tester.getTopLeft(find.text('Abarrotes')).dy,
      tester.getTopLeft(find.text('Lácteos')).dy,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('teléfono: saluda con el nombre de la cuenta', (tester) async {
    await pumpApp(
      tester,
      width: 375,
      signedIn: signedInAs(UserRole.customer),
    );

    expect(find.text('¡Hola, Ana!'), findsOneWidget);
    expect(
      find.text('Abastece tu negocio con los mejores productos.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('teléfono, sin cuenta: ¡Hola! y el buscador', (tester) async {
    await pumpApp(tester, width: 375);

    expect(find.text('¡Hola!'), findsOneWidget);
    expect(find.byType(StoreSearchField), findsOneWidget);
  });

  Future<void> openPromos(WidgetTester tester) async {
    final promos = find.widgetWithText(ChoiceChip, 'Promos');
    await tester.ensureVisible(promos);
    await tester.tap(promos);
    await tester.pumpAndSettle();
  }

  testWidgets('la portada muestra las tres pestañas con cuenta', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: signedInAs(UserRole.customer));

    for (final tab in ['Frecuentes', 'Sugeridos', 'Promos']) {
      expect(find.widgetWithText(ChoiceChip, tab), findsOneWidget, reason: tab);
    }
  });

  testWidgets('Promos: tarjetas en escritorio, con Agregar', (tester) async {
    final (_, container) = await pumpApp(tester);
    await openPromos(tester);

    expect(shownProducts(tester), ['aceite']);
    expect(catalog.onSaleRequests, contains(true));

    final add = find.widgetWithText(FilledButton, 'Agregar');
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(container.read(cartProvider).quantityOf('aceite'), 1);
  });

  testWidgets('Promos en lista en el teléfono', (tester) async {
    await pumpApp(tester, width: 375);
    await openPromos(tester);

    expect(find.byType(ProductTile), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);
  });

  testWidgets('sin promociones, Promos lo dice', (tester) async {
    catalog = FakeCatalogRepository(productList: const [rice, milk]);
    await pumpApp(tester);
    await openPromos(tester);

    expect(find.text('Hoy no hay promociones.'), findsOneWidget);
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
    await openPromos(tester);
    expect(find.text('Hoy no hay promociones.'), findsOneWidget);
  });

  testWidgets('el titular se lee como un encabezado', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester);

    expect(
      tester.getSemantics(find.textContaining('Tu negocio siempre abastecido')),
      matchesSemantics(
        label: "Tu negocio siempre abastecido con Neil's.",
        isHeader: true,
      ),
    );
    semantics.dispose();
  });
}
