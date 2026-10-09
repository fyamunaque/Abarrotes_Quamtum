// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:abarrotes_server/src/common/store_time.dart';
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

      expect(created, 25);
      expect(
        [for (final c in await Category.db.find(session)) c.name]..sort(),
        [
          'Abarrotes',
          'Bebidas',
          'Carnes y embutidos',
          'Cuidado personal',
          'Frutas y verduras',
          'Limpieza',
          'Lácteos y huevos',
          'Panadería',
          'Snacks y dulces',
        ],
      );
      // Ninguna categoría queda vacía en la tienda.
      for (final category in await Category.db.find(session)) {
        expect(
          await Product.db.count(
            session,
            where: (product) => product.categoryId.equals(category.id),
          ),
          greaterThanOrEqualTo(1),
          reason: category.name,
        );
      }
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
      expect(await Product.db.count(session), 25);
      expect(await Category.db.count(session), 9);
      expect(await Promotion.db.count(session), 1);
    });

    test(
      'completa una base con el catálogo viejo, sin tocar lo que hay',
      () async {
        final session = sessionBuilder.build();
        final dairy = await Category.db.insertRow(
          session,
          Category(name: 'Lácteos'),
        );
        await Category.db.insertRow(session, Category(name: 'Snacks'));
        // Un producto del seed que alguien editó y dio de baja.
        await Product.db.insertRow(
          session,
          Product(
            name: 'Leche evaporada (editada)',
            sku: 'LEC-400',
            priceCents: 999,
            currentStock: 3,
            minStock: 1,
            active: false,
            categoryId: dairy.id!,
          ),
        );

        expect(await seedDevData(session, now: () => testNow), 24);

        final names = [for (final c in await Category.db.find(session)) c.name];
        expect(names, hasLength(9));
        expect(names, containsAll(['Lácteos y huevos', 'Snacks y dulces']));
        expect(names, isNot(contains('Lácteos')));
        final milk = (await Product.db.findFirstRow(
          session,
          where: (product) => product.sku.equals('LEC-400'),
        ))!;
        expect(milk.name, 'Leche evaporada (editada)');
        expect(milk.priceCents, 999);
        expect(milk.active, isFalse);
        expect(milk.categoryId, dairy.id);
      },
    );

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
          // Todos los estados, y los dos más recientes esperan confirmación.
          expect(
            orders.map((o) => o.status).toSet(),
            OrderStatus.values.toSet(),
          );
          final newest = [...orders]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          expect(
            newest.take(2).map((o) => o.status),
            everyElement(OrderStatus.pendingConfirmation),
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

      /// Un pedido de una cuenta real, con un item.
      Future<Order> otherCustomerOrder() async {
        final other = await insertUser(
          session,
          'uid-cliente',
          UserRole.customer,
        );
        final rice = (await Product.db.findFirstRow(
          session,
          where: (product) => product.sku.equals('ARR-5KG'),
        ))!;
        final order = await Order.db.insertRow(
          session,
          Order(
            status: OrderStatus.pendingConfirmation,
            totalCents: 2490,
            deliveryAddress: 'Jr. Real 1',
            customerId: other.id!,
          ),
        );
        await OrderItem.db.insertRow(
          session,
          OrderItem(
            quantity: 1,
            unitPriceCents: 2490,
            orderId: order.id!,
            productId: rice.id!,
          ),
        );
        return order;
      }

      /// Los del cliente de ejemplo, el más reciente primero.
      Future<List<Order>> demoOrders() async {
        final demo = (await User.db.findFirstRow(
          session,
          where: (user) => user.firebaseUid.equals('seed-cliente-demo'),
        ))!;
        final orders = await Order.db.find(
          session,
          where: (order) => order.customerId.equals(demo.id),
        );
        return orders..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      test('los pedidos de otra cuenta no impiden los de ejemplo', () async {
        await otherCustomerOrder();

        expect(await seedDevOrders(session, now: () => testNow), 40);
        expect(await Order.db.count(session), 41);
      });

      test('reiniciar: los de ejemplo, de nuevo hasta hoy; los demás, '
          'intactos', () async {
        await seedDevOrders(session, now: () => testNow);
        final other = await otherCustomerOrder();
        // La demo es 10 días después.
        final later = testNow.add(const Duration(days: 10));

        expect(await resetDevOrders(session, now: () => later), 40);

        final orders = await demoOrders();
        expect(orders, hasLength(40));
        expect(
          orders.every(
            (o) =>
                !o.createdAt.isAfter(later) &&
                o.createdAt.isAfter(later.subtract(const Duration(days: 31))),
          ),
          isTrue,
        );
        expect(
          orders.take(2).map((o) => o.status),
          everyElement(OrderStatus.pendingConfirmation),
        );
        // El pedido de la otra cuenta sigue, con su item; los items de los
        // pedidos de ejemplo viejos ya no están.
        expect(await Order.db.findById(session, other.id!), isNotNull);
        expect(
          await OrderItem.db.count(
            session,
            where: (item) => item.orderId.equals(other.id),
          ),
          1,
        );
        final demoItems = await OrderItem.db.count(
          session,
          where: (item) =>
              item.orderId.inSet({for (final order in orders) order.id!}),
        );
        expect(await OrderItem.db.count(session), demoItems + 1);

        // Los vencimientos de ejemplo, desde el día nuevo.
        final yogurt = (await Product.db.findFirstRow(
          session,
          where: (product) => product.sku.equals('YOG-1L'),
        ))!;
        expect(
          yogurt.expirationDate,
          utcMidnight(addDays(storeDay(later), 3)),
        );
      });

      test('reiniciar dos veces da lo mismo', () async {
        await resetDevOrders(session, now: () => testNow);
        final first = [for (final o in await demoOrders()) o.totalCents];

        await resetDevOrders(session, now: () => testNow);
        final second = [for (final o in await demoOrders()) o.totalCents];

        expect(second, first);
        expect(await Order.db.count(session), 40);
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
