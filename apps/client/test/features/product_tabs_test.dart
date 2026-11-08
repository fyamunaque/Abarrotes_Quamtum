import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/features/home/product_tabs.dart';
import 'package:neils/offers/offers_providers.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/neils_theme.dart';

import '../fakes.dart';
import '../support.dart';

/// Las pestañas de la portada: Frecuentes (con cuenta), Sugeridos y Promos.
void main() {
  useBundledFonts();

  late FakeCatalogRepository catalog;

  setUp(() {
    catalog = FakeCatalogRepository(
      frequentList: const [rice],
      suggestedList: const [milk],
    );
  });

  Future<GoRouter> pumpTabs(
    WidgetTester tester, {
    Session session = const SignedOut(),
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ProductTabs(),
            ),
          ),
        ),
        GoRoute(
          path: '/catalogo',
          builder: (_, state) => Text('catálogo ${state.uri}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => TestSession(session)),
          catalogRepositoryProvider.overrideWithValue(catalog),
          offersRepositoryProvider.overrideWithValue(FakeOffersRepository()),
        ],
        child: MaterialApp.router(theme: neilsTheme(), routerConfig: router),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return router;
  }

  Finder tab(String label) => find.widgetWithText(ChoiceChip, label);

  bool selected(WidgetTester tester, String label) =>
      tester.widget<ChoiceChip>(tab(label)).selected;

  testWidgets('las tres pestañas entran en una línea en el teléfono', (
    tester,
  ) async {
    await pumpTabs(tester, session: signedInAs(UserRole.customer));

    final top = tester.getTopLeft(tab('Frecuentes')).dy;
    expect(tester.getTopLeft(tab('Sugeridos')).dy, top);
    expect(tester.getTopLeft(tab('Promos')).dy, top);
  });

  testWidgets('sin cuenta no hay Frecuentes y arranca en Sugeridos', (
    tester,
  ) async {
    await pumpTabs(tester);

    expect(tab('Frecuentes'), findsNothing);
    expect(selected(tester, 'Sugeridos'), isTrue);
    expect(find.text('Leche evaporada 400 g'), findsOneWidget);
    expect(catalog.frequentCalls, 0);
  });

  testWidgets('con pedidos arranca en Frecuentes', (tester) async {
    await pumpTabs(tester, session: signedInAs(UserRole.customer));

    expect(selected(tester, 'Frecuentes'), isTrue);
    expect(find.text('Arroz extra 5 kg'), findsOneWidget);
  });

  testWidgets('mientras cargan los Frecuentes, se queda en Frecuentes', (
    tester,
  ) async {
    final gate = catalog.frequentGate = Completer<List<Product>>();
    await pumpTabs(
      tester,
      session: signedInAs(UserRole.customer),
      settle: false,
    );

    // No salta a Sugeridos mientras tanto: Frecuentes con su indicador.
    expect(selected(tester, 'Frecuentes'), isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Leche evaporada 400 g'), findsNothing);

    gate.complete(const [rice]);
    await tester.pumpAndSettle();

    expect(selected(tester, 'Frecuentes'), isTrue);
    expect(find.text('Arroz extra 5 kg'), findsOneWidget);
  });

  testWidgets('si los Frecuentes fallan, pasa a Sugeridos', (tester) async {
    final gate = catalog.frequentGate = Completer<List<Product>>();
    await pumpTabs(
      tester,
      session: signedInAs(UserRole.customer),
      settle: false,
    );

    gate.completeError(const ApiFailure('Sin conexión'));
    await tester.pumpAndSettle();

    expect(selected(tester, 'Sugeridos'), isTrue);
    expect(find.text('Leche evaporada 400 g'), findsOneWidget);
  });

  testWidgets(
    'un cliente sin pedidos ve Sugeridos y el texto vacío al tocar Frecuentes',
    (tester) async {
      catalog = FakeCatalogRepository(suggestedList: const [milk]);
      await pumpTabs(tester, session: signedInAs(UserRole.customer));

      expect(selected(tester, 'Sugeridos'), isTrue);
      expect(find.text('Leche evaporada 400 g'), findsOneWidget);

      await tester.tap(tab('Frecuentes'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Cuando hagas tu primer pedido, aquí verás lo que más pides.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Promos muestra los productos en promoción', (tester) async {
    await pumpTabs(tester);

    await tester.tap(tab('Promos'));
    await tester.pumpAndSettle();

    expect(find.text('Aceite vegetal 1 L'), findsOneWidget);
    expect(catalog.onSaleRequests, contains(true));
  });

  testWidgets('"Ver todas" en Promos lleva a /catalogo?promos=1', (
    tester,
  ) async {
    final router = await pumpTabs(tester);

    await tester.tap(tab('Promos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver todas las promociones'));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/catalogo?promos=1',
    );
  });

  testWidgets('si falla, Reintentar vuelve a pedir', (tester) async {
    catalog.suggestionsFailure = const ApiFailure('Sin conexión');
    await pumpTabs(tester);

    expect(find.text('Sin conexión'), findsOneWidget);

    catalog.suggestionsFailure = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Leche evaporada 400 g'), findsOneWidget);
  });
}
