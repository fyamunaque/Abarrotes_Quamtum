import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/common/money.dart';
import 'package:neils/features/offers/exclusive_offers.dart';
import 'package:neils/offers/offer.dart';
import 'package:neils/offers/offers_providers.dart';
import 'package:neils/router/router.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';

import '../fakes.dart';
import '../support.dart';

/// "Ofertas exclusivas" en el inicio y el catálogo: solo para una cuenta VIP,
/// y sin ninguna pista para las demás.
void main() {
  useBundledFonts();

  const riceOffer = Offer(
    id: 'o-1',
    productId: 'arroz',
    productName: 'Arroz extra 5 kg',
    priceCents: 2490,
    promoPriceCents: 1790,
    endDate: '2026-10-15',
    title: 'Precio VIP de la semana',
    vip: true,
  );

  final customer = signedInAs(UserRole.customer);
  final vip = SignedIn(customer.user.copyWith(isVip: true));

  late FakeOffersRepository offers;
  late TestSession session;

  setUp(() => offers = FakeOffersRepository([riceOffer]));

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required String at,
    required Session signedIn,
    double width = 1280,
  }) async {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    session = TestSession(signedIn);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => session),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          offersRepositoryProvider.overrideWithValue(offers),
        ],
        child: const NeilsApp(),
      ),
    );
    final router = ProviderScope.containerOf(
      tester.element(find.byType(NeilsApp)),
    ).read(routerProvider)..go(at);
    await tester.pumpAndSettle();
    return router;
  }

  /// Nada de VIP ni de ofertas exclusivas en ningún texto de la pantalla.
  void expectNoVipHint() {
    expect(find.byType(ExclusiveOffers), findsWidgets);
    expect(find.textContaining('VIP'), findsNothing);
    expect(find.textContaining('xclusiv'), findsNothing);
  }

  for (final (at, label) in [
    ('/', 'el inicio'),
    ('/catalogo', 'el catálogo'),
  ]) {
    testWidgets('una cuenta VIP ve sus ofertas en $label', (tester) async {
      await pumpApp(tester, at: at, signedIn: vip);

      expect(find.text('Ofertas exclusivas'), findsOneWidget);
      final section = find.byType(ExclusiveOffers);
      Finder inSection(String text) =>
          find.descendant(of: section, matching: find.text(text));
      expect(inSection('Arroz extra 5 kg'), findsOneWidget);
      expect(inSection('Precio VIP de la semana'), findsOneWidget);
      expect(inSection(formatSoles(1790)), findsOneWidget);
      expect(inSection(formatSoles(2490)), findsOneWidget);
      expect(inSection('VIP'), findsOneWidget);
      expect(offers.calls, 1);
    });
  }

  testWidgets('tocar una oferta abre el producto', (tester) async {
    final router = await pumpApp(tester, at: '/', signedIn: vip);

    await tester.tap(find.text('Precio VIP de la semana'));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/producto/arroz',
    );
  });

  testWidgets('en el catálogo, solo sin búsqueda ni categoría', (tester) async {
    await pumpApp(tester, at: '/catalogo?q=arroz', signedIn: vip);

    expect(find.text('Ofertas exclusivas'), findsNothing);
  });

  for (final (signedIn, label) in [
    (const SignedOut(), 'un visitante'),
    (customer, 'un cliente que no es VIP'),
  ]) {
    testWidgets('$label no ve nada VIP y no se piden las ofertas', (
      tester,
    ) async {
      await pumpApp(tester, at: '/', signedIn: signedIn);
      expectNoVipHint();

      await pumpApp(tester, at: '/catalogo', signedIn: signedIn);
      expectNoVipHint();
      expect(offers.calls, 0);
    });
  }

  testWidgets('sin ofertas o si no cargan, la sección no aparece', (
    tester,
  ) async {
    offers.offers = [];
    await pumpApp(tester, at: '/', signedIn: vip);
    expect(find.text('Ofertas exclusivas'), findsNothing);

    offers.failure = const ApiFailure('Sin conexión');
    await pumpApp(tester, at: '/catalogo', signedIn: vip);
    expect(find.text('Ofertas exclusivas'), findsNothing);
    expect(find.text('Sin conexión'), findsNothing);
  });

  testWidgets('si un admin la hace VIP, las ofertas aparecen sin volver a '
      'ingresar', (tester) async {
    await pumpApp(tester, at: '/', signedIn: customer);
    expect(find.text('Ofertas exclusivas'), findsNothing);

    session.set(vip);
    await tester.pumpAndSettle();

    expect(find.text('Ofertas exclusivas'), findsOneWidget);
    expect(offers.calls, 1);
  });

  testWidgets('en un teléfono de 320 px entra sin desbordes', (tester) async {
    await pumpApp(tester, at: '/', signedIn: vip, width: 320);

    expect(find.text('Ofertas exclusivas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
