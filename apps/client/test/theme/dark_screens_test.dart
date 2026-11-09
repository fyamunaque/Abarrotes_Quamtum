import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/admin/stats/stats.dart';
import 'package:neils/admin/stats/stats_providers.dart';
import 'package:neils/app.dart';
import 'package:neils/appearance/appearance.dart';
import 'package:neils/appearance/appearance_providers.dart';
import 'package:neils/appearance/appearance_repository.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/offers/offers_providers.dart';
import 'package:neils/orders/fulfillment.dart';
import 'package:neils/orders/order.dart';
import 'package:neils/orders/order_status.dart';
import 'package:neils/orders/orders_providers.dart';
import 'package:neils/router/router.dart';
import 'package:neils/router/routes.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';

import '../fakes.dart';
import '../support.dart';

/// Cada pantalla de la app entera con la preferencia en oscuro, en el
/// teléfono y en el escritorio: sin errores ni desbordes.
void main() {
  useBundledFonts();

  const summary = SalesSummary(
    totalCents: 4550,
    orders: 2,
    averageTicketCents: 2275,
  );

  Future<void> pumpDark(
    WidgetTester tester, {
    required String at,
    required Size size,
    required Session session,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final catalog = FakeCatalogRepository(frequentList: const [rice]);
    final orders = FakeOrderRepository(catalog)
      ..orders.add(
        Order(
          id: 'pedido-1',
          status: OrderStatus.outForDelivery,
          fulfillmentType: FulfillmentType.delivery,
          totalCents: 2490,
          createdAt: DateTime.utc(2026, 10, 14, 15),
          lines: const [],
        ),
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appearanceRepositoryProvider.overrideWithValue(
            MemoryAppearanceRepository(ThemePreference.dark),
          ),
          sessionProvider.overrideWith(() => TestSession(session)),
          catalogRepositoryProvider.overrideWithValue(catalog),
          offersRepositoryProvider.overrideWithValue(FakeOffersRepository()),
          orderRepositoryProvider.overrideWithValue(orders),
          statsRepositoryProvider.overrideWithValue(
            FakeStatsRepository(
              overviewData: const StatsOverview(
                today: summary,
                week: summary,
                month: summary,
                ordersByStatus: {},
                ordersByFulfillment: {},
              ),
            ),
          ),
        ],
        child: const NeilsApp(),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(NeilsApp)))
        .read(routerProvider)
        .go(at);
    await tester.pumpAndSettle();
  }

  final screens = {
    Routes.home: signedInAs(UserRole.admin),
    Routes.catalog: signedInAs(UserRole.admin),
    Routes.product(rice.id): signedInAs(UserRole.admin),
    Routes.cart: signedInAs(UserRole.admin),
    Routes.myOrders: signedInAs(UserRole.customer),
    Routes.login: const SignedOut(),
    '/admin': signedInAs(UserRole.admin),
  };
  const sizes = {'teléfono': Size(390, 844), 'escritorio': Size(1280, 900)};

  for (final MapEntry(key: at, value: session) in screens.entries) {
    for (final MapEntry(key: name, value: size) in sizes.entries) {
      testWidgets('cada pantalla en oscuro, sin errores ni desbordes: '
          '$at en el $name', (tester) async {
        await pumpDark(tester, at: at, size: size, session: session);

        expect(tester.takeException(), isNull);
        final scaffold = find.byType(Scaffold).first;
        expect(Theme.of(tester.element(scaffold)).brightness, Brightness.dark);
      });
    }
  }
}
