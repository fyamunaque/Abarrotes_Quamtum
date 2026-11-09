import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/features/home/campaign_band.dart';
import 'package:neils/router/routes.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/neils_theme.dart';
import 'package:neils/theme/palette.dart';

import '../fakes.dart';
import '../support.dart';

/// La franja roja de la campaña: la primera promoción por cantidad del día,
/// cuántos productos están en promoción y "Ver promociones".
void main() {
  useBundledFonts();

  Product onSale(String id, {List<ProductOffer> offers = const []}) => Product(
    id: id,
    name: id,
    priceCents: 500,
    promoPriceCents: 400,
    stock: 10,
    offers: offers,
  );

  const threeForTwo = (
    type: 'buyXPayY',
    label: '3x2',
    title: null,
    description: '3x2 en Jamonada especial',
  );
  const gift = (
    type: 'gift',
    label: 'Regalo: Pan',
    title: null,
    description: 'Regalo: Pan por cada 6',
  );

  late GoRouter router;

  Future<void> pumpBand(
    WidgetTester tester,
    List<Product> products, {
    double width = 390,
    double textScale = 1,
    int pageSize = 20,
    ApiFailure? failure,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final catalog = FakeCatalogRepository(
      productList: products,
      pageSize: pageSize,
    )..failure = failure;
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: const [CampaignBand(), Text('Después')],
              ),
            ),
          ),
        ),
        GoRoute(
          path: Routes.catalog,
          builder: (_, state) => Text('Catálogo ${state.uri}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => TestSession(const SignedOut())),
          catalogRepositoryProvider.overrideWithValue(catalog),
        ],
        child: MaterialApp.router(
          theme: neilsTheme(brightness),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el título sale de la primera promoción por cantidad', (
    tester,
  ) async {
    await pumpBand(tester, [
      onSale('hot-dog'),
      onSale('yogur', offers: const [gift]),
      onSale('jamonada', offers: const [threeForTwo]),
    ]);

    expect(find.text('3x2 en Jamonada especial'), findsOneWidget);
    // Roja, con el texto blanco.
    final band = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(CampaignBand),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(band.color, NeilsPalette.light.brandFill);
    expect(
      tester.widget<Text>(find.text('3x2 en Jamonada especial')).style?.color,
      NeilsPalette.light.onBrand,
    );
  });

  testWidgets('sin promociones por cantidad, el título general', (
    tester,
  ) async {
    await pumpBand(tester, [
      onSale('hot-dog'),
      onSale('yogur', offers: const [gift]),
    ]);

    expect(find.text('Promociones para tu negocio'), findsOneWidget);
  });

  testWidgets('cuenta los productos en promoción', (tester) async {
    // Más que una página: cuenta el total, no los de la primera.
    await pumpBand(tester, [
      onSale('a'),
      onSale('b'),
      onSale('c'),
    ], pageSize: 2);
    expect(find.text('3 productos en promoción hoy'), findsOneWidget);

    await pumpBand(tester, [onSale('a')]);
    expect(find.text('1 producto en promoción hoy'), findsOneWidget);
  });

  testWidgets('Ver promociones lleva al catálogo de promociones', (
    tester,
  ) async {
    await pumpBand(tester, [onSale('a')]);

    await tester.tap(find.text('Ver promociones'));
    await tester.pumpAndSettle();

    expect(find.text('Catálogo ${Routes.promotions}'), findsOneWidget);
  });

  testWidgets('si falla, no ocupa lugar', (tester) async {
    await pumpBand(tester, [
      onSale('a'),
    ], failure: const ApiFailure('Sin conexión'));

    expect(
      tester.getSize(find.byType(CampaignBand, skipOffstage: false)).height,
      0,
    );
    // Lo que sigue queda arriba de todo, donde estaría la franja.
    expect(tester.getTopLeft(find.text('Después')).dy, 16);
  });

  testWidgets('entra a 320 con el texto al 130 %', (tester) async {
    await pumpBand(
      tester,
      [
        onSale('jamonada', offers: const [threeForTwo]),
        onSale('b'),
      ],
      width: 320,
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Ver promociones').hitTestable(), findsOneWidget);
  });

  testWidgets('en oscuro, el mismo rojo con el texto blanco', (tester) async {
    await pumpBand(tester, [
      onSale('jamonada', offers: const [threeForTwo]),
    ], brightness: Brightness.dark);

    expect(
      tester.widget<Text>(find.text('3x2 en Jamonada especial')).style?.color,
      NeilsPalette.dark.onBrand,
    );
  });
}
