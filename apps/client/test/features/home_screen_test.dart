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
import 'package:neils/features/home/campaign_band.dart';
import 'package:neils/features/home/home_screen.dart';
import 'package:neils/features/shared/diagonal_band.dart';
import 'package:neils/features/home/store_footer.dart';
import 'package:neils/features/admin/home/greeting.dart';
import 'package:neils/store/store_providers.dart';
import 'package:neils/store/store_settings.dart';
import 'package:neils/features/shared/brand.dart';
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

  testWidgets('deslizar hacia abajo vuelve a pedir Frecuentes y Sugeridos', (
    tester,
  ) async {
    await pumpHome(tester, signedIn: signedInAs(UserRole.customer));
    final (frequent, suggested) = (
      catalog.frequentCalls,
      catalog.suggestedCalls,
    );

    await tester.fling(
      find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.vertical,
      ),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(catalog.frequentCalls, frequent + 1);
    expect(catalog.suggestedCalls, suggested + 1);
  });

  /// La app entera, con el router: para seguir los enlaces.
  Future<(GoRouter, ProviderContainer)> pumpApp(
    WidgetTester tester, {
    Session signedIn = const SignedOut(),
    double width = 1280,
    StoreSettings store = sampleStore,
    bool settle = true,
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
          storeRepositoryProvider.overrideWithValue(FakeStoreRepository(store)),
        ],
        child: const NeilsApp(),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NeilsApp)),
    );
    final router = container.read(routerProvider)..go('/');
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return (router, container);
  }

  /// La opacidad del titular de escritorio (la de su entrada).
  double titleOpacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find
            .ancestor(
              of: find.textContaining('Insumos para restaurantes'),
              matching: find.byType(Opacity),
            )
            .first,
      )
      .opacity;

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
      find.textContaining('Insumos para restaurantes y cafeterías'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Embutidos, lácteos, panes y abarrotes, con entrega a tu negocio o '
        'recojo en tienda.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Ver catálogo'), findsOneWidget);
    // El mensaje es para negocios, no para hogares.
    expect(find.textContaining('tu casa'), findsNothing);

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Ver promociones').first,
    );
    await tester.pumpAndSettle();
    expect(location(router), '/catalogo?promos=1');
  });

  testWidgets('la franja de la campaña, sin los sellos', (tester) async {
    await pumpApp(tester);

    expect(find.byType(CampaignBand), findsOneWidget);
    expect(find.text('Entrega confiable'), findsNothing);
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

  testWidgets('en el teléfono, las categorías van en una fila', (tester) async {
    await pumpApp(tester, width: 375);

    expect(
      tester.getTopLeft(find.text('Abarrotes')).dy,
      tester.getTopLeft(find.text('Lácteos')).dy,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('teléfono: saluda con el nombre de la cuenta', (tester) async {
    await pumpApp(tester, width: 375, signedIn: signedInAs(UserRole.customer));

    expect(
      find.text('${greetingFor(DateTime.now().toUtc())}, Ana'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('teléfono, sin cuenta: el saludo y el buscador', (tester) async {
    await pumpApp(tester, width: 375);

    expect(find.text(greetingFor(DateTime.now().toUtc())), findsOneWidget);
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
      tester.getSemantics(find.textContaining('Insumos para restaurantes')),
      matchesSemantics(
        label: 'Insumos para restaurantes y cafeterías',
        isHeader: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('cada pestaña tiene su título', (tester) async {
    catalog = FakeCatalogRepository(frequentList: const [rice]);
    await pumpApp(tester, signedIn: signedInAs(UserRole.customer));

    expect(find.text('Reposición habitual'), findsOneWidget);
    for (final (tab, title) in [
      ('Sugeridos', 'Lo más pedido'),
      ('Promos', 'Promociones de hoy'),
      ('Frecuentes', 'Reposición habitual'),
    ]) {
      final chip = find.widgetWithText(ChoiceChip, tab);
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget, reason: tab);
    }
  });

  testWidgets('el horario de la tienda aparece si está cargado', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Atendemos Lun a sáb de 8 a 20 h'), findsOneWidget);
  });

  testWidgets('sin horario no hay línea', (tester) async {
    await pumpApp(
      tester,
      store: const StoreSettings(
        name: "Neil's Food Services",
        address: 'Av. Arequipa 1234, Lince',
      ),
    );

    expect(find.textContaining('Atendemos'), findsNothing);
  });

  testWidgets('el pie muestra la dirección de la tienda', (tester) async {
    await pumpApp(tester);

    final footer = find.byType(StoreFooter);
    expect(
      find.descendant(
        of: footer,
        matching: find.text('Av. Arequipa 1234, Lince'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: footer, matching: find.text("Neil's Food Services")),
      findsOneWidget,
    );
  });

  testWidgets('la entrada se ve una vez por sesión', (tester) async {
    final (router, _) = await pumpApp(tester, settle: false);

    // La primera vez entra: al principio, transparente.
    expect(titleOpacity(tester), lessThan(1));
    await tester.pumpAndSettle();
    expect(titleOpacity(tester), 1);

    router.go('/catalogo');
    await tester.pumpAndSettle();
    router.go('/');
    await tester.pump();

    // La segunda vez ya está: el titular y la foto, asentada.
    expect(titleOpacity(tester), 1);
    final photo = tester.widget<Transform>(
      find
          .ancestor(
            of: find.byType(DiagonalBand),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(photo.transform.entry(0, 0), 1);
  });

  testWidgets(
    'con reducir animaciones, el titular está desde el primer cuadro',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpApp(tester, settle: false);

      expect(titleOpacity(tester), 1);
    },
  );

  testWidgets('el buscador responde durante la entrada', (tester) async {
    await pumpApp(tester, settle: false);
    expect(titleOpacity(tester), lessThan(1));

    final search = find.byType(TextField).first;
    await tester.tap(search);
    await tester.enterText(search, 'arroz');
    await tester.pump();

    expect(find.text('arroz'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('la portada entra en 320 y en 1280 sin desbordes', (
    tester,
  ) async {
    for (final width in [320.0, 1280.0]) {
      await pumpApp(
        tester,
        width: width,
        signedIn: signedInAs(UserRole.customer),
      );
      expect(tester.takeException(), isNull, reason: '$width');
    }
  });
}
