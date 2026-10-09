import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/cart/cart_provider.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/features/catalog/product_card.dart';
import 'package:neils/features/catalog/product_detail_screen.dart';
import 'package:neils/router/router.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';

import '../fakes.dart';
import '../support.dart';

void main() {
  useBundledFonts();

  late FakeCatalogRepository catalog;
  late ProviderContainer container;

  setUp(() => catalog = FakeCatalogRepository());

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    String at = '/catalogo',
  }) async {
    useWideScreen(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => TestSession(const SignedOut())),
          catalogRepositoryProvider.overrideWithValue(catalog),
        ],
        child: const NeilsApp(),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(NeilsApp)),
    );
    final router = container.read(routerProvider)..go(at);
    await tester.pumpAndSettle();
    return router;
  }

  String location(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  List<String> shownProducts(WidgetTester tester) => [
    for (final card in tester.widgetList<ProductCard>(find.byType(ProductCard)))
      card.product.id,
  ];

  group('catálogo', () {
    testWidgets('muestra todos los productos y las categorías', (tester) async {
      await pumpApp(tester);

      expect(shownProducts(tester), ['arroz', 'aceite', 'leche']);
      for (final chip in ['Todas', 'Abarrotes', 'Lácteos']) {
        expect(find.widgetWithText(ChoiceChip, chip), findsOneWidget);
      }
    });

    testWidgets('filtrar por categoría cambia la URL y los productos', (
      tester,
    ) async {
      final router = await pumpApp(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Lácteos'));
      await tester.pumpAndSettle();

      expect(location(router), '/catalogo?categoria=cat-lacteos');
      expect(shownProducts(tester), ['leche']);
      final selected = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Lácteos'),
      );
      expect(selected.selected, isTrue);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Todas'));
      await tester.pumpAndSettle();
      expect(location(router), '/catalogo');
      expect(shownProducts(tester), hasLength(3));
    });

    testWidgets('un enlace con la categoría abre el catálogo filtrado', (
      tester,
    ) async {
      await pumpApp(tester, at: '/catalogo?categoria=cat-abarrotes');

      expect(shownProducts(tester), ['arroz', 'aceite']);
    });

    testWidgets('"Ver más productos" carga la página siguiente', (
      tester,
    ) async {
      catalog = FakeCatalogRepository(
        productList: [
          for (var i = 1; i <= 3; i++)
            Product(id: 'p$i', name: 'Producto $i', priceCents: 100, stock: 9),
        ],
        pageSize: 2,
      );
      await pumpApp(tester);
      expect(shownProducts(tester), ['p1', 'p2']);

      await tester.ensureVisible(find.text('Ver más productos'));
      await tester.tap(find.text('Ver más productos'));
      await tester.pumpAndSettle();

      expect(shownProducts(tester), ['p1', 'p2', 'p3']);
      expect(find.text('Ver más productos'), findsNothing);
    });

    testWidgets('si no carga, lo dice y deja reintentar', (tester) async {
      catalog.failure = const ApiFailure(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
      await pumpApp(tester);
      expect(find.textContaining('No se pudo conectar'), findsOneWidget);

      catalog.failure = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(shownProducts(tester), hasLength(3));
    });

    testWidgets('una categoría sin productos lo dice', (tester) async {
      catalog = FakeCatalogRepository(productList: const [rice]);
      await pumpApp(tester, at: '/catalogo?categoria=cat-lacteos');

      expect(find.text('No hay productos en esta categoría.'), findsOneWidget);
    });

    testWidgets('"Agregar" suma al carrito y avisa con "Ver carrito"', (
      tester,
    ) async {
      final router = await pumpApp(tester);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('arroz')),
          matching: find.text('Agregar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(cartProvider).quantityOf('arroz'), 1);
      expect(find.text('Agregaste Arroz extra 5 kg'), findsOneWidget);
      expect(find.byTooltip('Carrito: 1'), findsOneWidget);

      await tester.tap(find.text('Ver carrito'));
      await tester.pumpAndSettle();
      expect(location(router), '/carrito');
    });

    testWidgets('buscar cambia la URL y los productos', (tester) async {
      final router = await pumpApp(tester);

      await tester.enterText(find.byType(TextField), '  leche ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(location(router), '/catalogo?q=leche');
      expect(shownProducts(tester), ['leche']);
      expect(catalog.searches.last, 'leche');

      await tester.tap(find.byTooltip('Borrar la búsqueda'));
      await tester.pumpAndSettle();
      expect(location(router), '/catalogo');
      expect(shownProducts(tester), hasLength(3));
      expect(find.byTooltip('Borrar la búsqueda'), findsNothing);
    });

    testWidgets('la lupa también busca, y la categoría conserva lo buscado', (
      tester,
    ) async {
      final router = await pumpApp(tester);

      await tester.enterText(find.byType(TextField), 'aceite');
      await tester.tap(find.byTooltip('Buscar'));
      await tester.pumpAndSettle();
      expect(shownProducts(tester), ['aceite']);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Lácteos'));
      await tester.pumpAndSettle();
      expect(location(router), '/catalogo?categoria=cat-lacteos&q=aceite');
      expect(
        find.text('No encontramos productos para “aceite”.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'aceite',
      );

      await tester.tap(find.text('Ver todos los productos'));
      await tester.pumpAndSettle();
      expect(location(router), '/catalogo');
      expect(shownProducts(tester), hasLength(3));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('un enlace con la búsqueda abre el catálogo ya buscado', (
      tester,
    ) async {
      await pumpApp(tester, at: '/catalogo?q=arroz');

      expect(shownProducts(tester), ['arroz']);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'arroz',
      );
    });

    testWidgets('en un teléfono de 320 px entra sin desbordes', (tester) async {
      await pumpApp(tester, at: '/catalogo?q=arroz');
      tester.view.physicalSize = const Size(320, 800);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('tocar una tarjeta abre el detalle', (tester) async {
      final router = await pumpApp(tester);

      await tester.tap(find.text('Leche evaporada 400 g'));
      await tester.pumpAndSettle();

      expect(location(router), '/producto/leche');
      expect(find.byType(ProductDetailScreen), findsOneWidget);
    });
  });

  group('detalle', () {
    testWidgets('muestra la categoría, el precio, el stock y la descripción', (
      tester,
    ) async {
      await pumpApp(tester, at: '/producto/arroz');

      expect(find.text('Abarrotes'), findsOneWidget);
      expect(find.text('Arroz extra 5 kg'), findsOneWidget);
      expect(find.text('S/ 24.90'), findsOneWidget);
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('Grano largo, bolsa de 5 kg.'), findsOneWidget);
    });

    testWidgets('agrega la cantidad elegida, sin pasar del stock', (
      tester,
    ) async {
      await pumpApp(tester, at: '/producto/aceite');
      expect(find.text('Quedan 3'), findsOneWidget);

      await tester.tap(find.byTooltip('Agregar uno'));
      await tester.pump();
      await tester.tap(find.text('Agregar al carrito'));
      await tester.pumpAndSettle();

      expect(container.read(cartProvider).quantityOf('aceite'), 2);
      expect(find.text('Tienes 2 en el carrito.'), findsOneWidget);

      // Queda 1 por agregar: el + ya no sube.
      await tester.tap(find.byTooltip('Agregar uno'));
      await tester.pump();
      expect(find.text('Cantidad: 1'), findsNothing);
      await tester.tap(find.text('Agregar al carrito'));
      await tester.pumpAndSettle();

      expect(container.read(cartProvider).quantityOf('aceite'), 3);
      expect(find.text('Agregar al carrito'), findsNothing);
      expect(
        find.text('Ya tienes en el carrito todo el stock (3).'),
        findsOneWidget,
      );
    });

    testWidgets('un producto que ya no existe lo dice', (tester) async {
      await pumpApp(tester, at: '/producto/no-existe');

      expect(find.text('Este producto ya no está disponible.'), findsOneWidget);
    });

    testWidgets('sin stock no se puede agregar', (tester) async {
      catalog = FakeCatalogRepository(
        productList: const [
          Product(id: 'azucar', name: 'Azúcar', priceCents: 450, stock: 0),
        ],
      );
      await pumpApp(tester, at: '/producto/azucar');

      expect(find.text('Agotado'), findsOneWidget);
      expect(find.text('Agregar al carrito'), findsNothing);
    });
  });
}
