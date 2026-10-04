// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:abarrotes_server/src/dev/dev_seed.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/inventory/stock_alerts.dart';
import 'package:abarrotes_server/src/promotions/promotion_rules.dart';
import 'package:abarrotes_server/src/stats/providers/expiring_products_report_provider.dart';
import 'package:abarrotes_server/src/stats/providers/low_stock_report_provider.dart';
import 'package:abarrotes_server/src/stats/providers/order_status_report_provider.dart';
import 'package:abarrotes_server/src/stats/providers/overview_report_provider.dart';
import 'package:abarrotes_server/src/stats/providers/sales_report_provider.dart';
import 'package:abarrotes_server/src/stats/providers/top_products_report_provider.dart';
import 'package:abarrotes_server/src/stats/stats_routes.dart';
import 'package:serverpod/serverpod.dart' hide Order;
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  withServerpod('Seed de desarrollo', (sessionBuilder, _) {
    test('carga categorías y productos, con una promoción vigente y uno '
        'agotado', () async {
      final session = sessionBuilder.build();

      final created = await seedDevData(session, now: () => testNow);

      expect(created, 12);
      expect(await Category.db.count(session), 5);
      expect(await Product.db.count(session), 12);
      expect(
        await Product.db.count(
          session,
          where: (product) => product.currentStock.equals(0),
        ),
        1,
      );
      final promotions = await Promotion.db.find(
        session,
        where: (promotion) => activePromotionWhere(promotion, testNow),
      );
      expect(promotions, hasLength(1));
      expect(promotions.single.promoPriceCents, 890);
    });

    test('correrlo de nuevo no duplica nada', () async {
      final session = sessionBuilder.build();
      await seedDevData(session, now: () => testNow);

      expect(await seedDevData(session, now: () => testNow), 0);
      expect(await Product.db.count(session), 12);
      expect(await Category.db.count(session), 5);
    });

    group('pedidos de ejemplo', () {
      late Session session;
      late TestClient client;

      setUp(() async {
        session = sessionBuilder.build();
        final alerts = StockAlerts(now: () => testNow);
        const sales = SalesReportProvider();
        final server = await serveRoutes(
          () => session,
          statsRoutes(
            overview: OverviewReportProvider(
              sales: sales,
              orderStatus: const OrderStatusReportProvider(),
              now: () => testNow,
            ),
            sales: sales,
            topProducts: const TopProductsReportProvider(),
            lowStock: LowStockReportProvider(alerts),
            expiring: ExpiringProductsReportProvider(alerts),
            verifier: testVerifier(google),
            now: () => testNow,
          ),
        );
        client = TestClient(server, google);
        addTearDown(server.close);
        await insertUser(session, 'uid-staff', UserRole.staff);
        await seedDevData(session, now: () => testNow);
      });

      test('sin productos no crea pedidos', () async {
        final empty = sessionBuilder.build();
        await Promotion.db.deleteWhere(
          empty,
          where: (p) => Constant.bool(true),
        );
        await Product.db.deleteWhere(empty, where: (p) => Constant.bool(true));

        expect(await seedDevOrders(empty, now: () => testNow), 0);
        expect(await Order.db.count(empty), 0);
      });

      test(
        'reparte 40 pedidos en 30 días y dejan ventas para el panel',
        () async {
          expect(await seedDevOrders(session, now: () => testNow), 40);

          final orders = await Order.db.find(session);
          expect(orders, hasLength(40));
          expect(orders.map((o) => o.customerId).toSet(), hasLength(1));
          expect(
            orders.every(
              (o) =>
                  !o.createdAt.isAfter(testNow) &&
                  o.createdAt.isAfter(
                    testNow.subtract(const Duration(days: 31)),
                  ),
            ),
            isTrue,
          );
          expect(
            orders.map((o) => o.status).toSet(),
            containsAll([
              OrderStatus.delivered,
              OrderStatus.pendingConfirmation,
            ]),
          );

          final (status, sales) = await client.get(
            '/stats/sales',
            as: 'uid-staff',
          );
          expect(status, 200);
          final days = [
            for (final day in sales['daily'] as List)
              if (day['orders'] as int > 0) day['date'],
          ];
          expect(days.length, greaterThan(15));

          final (_, top) = await client.get(
            '/stats/top-products?limit=5',
            as: 'uid-staff',
          );
          expect(top['data'], hasLength(5));
        },
      );

      test('deja algo en las alertas de stock y de vencimiento', () async {
        await seedDevOrders(session, now: () => testNow);

        final (_, low) = await client.get('/stats/low-stock', as: 'uid-staff');
        expect(
          [for (final p in low['data'] as List) p['name']],
          containsAll(['Azúcar rubia 1 kg', 'Lejía 1 L']),
        );

        final (_, expiring) = await client.get(
          '/stats/expiring?days=7',
          as: 'uid-staff',
        );
        expect(
          [for (final p in expiring['data'] as List) p['name']],
          [
            'Yogurt de fresa 1 L',
          ],
        );
      });

      test('correrlo de nuevo no duplica los pedidos', () async {
        await seedDevOrders(session, now: () => testNow);

        expect(await seedDevOrders(session, now: () => testNow), 0);
        expect(await Order.db.count(session), 40);
        expect(
          await User.db.count(
            session,
            where: (user) => user.firebaseUid.equals('seed-cliente-demo'),
          ),
          1,
        );
      });
    });
  });
}
