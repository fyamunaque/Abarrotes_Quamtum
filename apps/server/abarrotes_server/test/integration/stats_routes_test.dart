// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:abarrotes_server/src/common/store_time.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/inventory/stock_alerts.dart';
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
import '../support/staff_setup.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

/// testNow es el jueves 1 de octubre de 2026, 07:00 en Lima: la semana
/// empieza el lunes 28 de septiembre y el mes, el 1 de octubre.
void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  withServerpod('Rutas de estadísticas', (sessionBuilder, _) {
    late Session session;
    late TestClient client;
    late Product arroz;
    late Product aceite;
    late Product leche;

    Future<void> insertOrder(
      OrderStatus status,
      DateTime createdAt,
      List<(Product, int quantity, int unitCents)> lines,
    ) async {
      final customer = (await User.db.findFirstRow(
        session,
        where: (u) => u.firebaseUid.equals('uid-cliente'),
      ))!;
      final order = await Order.db.insertRow(
        session,
        Order(
          status: status,
          totalCents: lines.fold(0, (sum, l) => sum + l.$2 * l.$3),
          deliveryAddress: 'Av. Arequipa 123',
          customerId: customer.id!,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
      await OrderItem.db.insert(session, [
        for (final (product, quantity, unitCents) in lines)
          OrderItem(
            orderId: order.id!,
            productId: product.id!,
            quantity: quantity,
            unitPriceCents: unitCents,
          ),
      ]);
    }

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
          guards: testGuards(google),
          now: () => testNow,
        ),
      );
      client = TestClient(server, google);
      addTearDown(server.close);
      await insertStaff(session, 'uid-staff');
      await insertUser(session, 'uid-cliente');

      final category = await Category.db.insertRow(
        session,
        Category(name: 'Abarrotes'),
      );
      Future<Product> product(String name, {int stock = 10, String? expires}) =>
          Product.db.insertRow(
            session,
            Product(
              name: name,
              sku: name.toUpperCase(),
              priceCents: 450,
              categoryId: category.id!,
              currentStock: stock,
              minStock: 2,
              expirationDate: expires == null ? null : utcMidnight(expires),
            ),
          );
      arroz = await product('Arroz');
      aceite = await product('Aceite', stock: 0);
      leche = await product('Leche', expires: '2026-10-03');

      // Ventas (aceptadas por la tienda):
      await insertOrder(OrderStatus.delivered, DateTime.utc(2026, 9, 28, 15), [
        (arroz, 2, 390),
        (aceite, 3, 100),
      ]); // 10.80 el 28/09
      // 23:59 del 30/09 en Lima.
      await insertOrder(
        OrderStatus.confirmed,
        DateTime.utc(2026, 10, 1, 4, 59),
        [
          (leche, 5, 100),
        ],
      ); // 5.00 el 30/09
      // 00:00 del 01/10 en Lima.
      await insertOrder(
        OrderStatus.outForDelivery,
        DateTime.utc(2026, 10, 1, 5),
        [
          (arroz, 1, 333),
        ],
      ); // 3.33 el 01/10
      // No cuentan: pendiente y cancelado.
      await insertOrder(
        OrderStatus.pendingConfirmation,
        DateTime.utc(2026, 10, 1, 10),
        [(leche, 50, 100)],
      );
      await insertOrder(OrderStatus.cancelled, DateTime.utc(2026, 9, 29, 10), [
        (aceite, 99, 100),
      ]);
    });

    Future<dynamic> get(String path) async {
      final (status, body) = await client.get(path, as: 'uid-staff');
      expect(status, 200, reason: '$path: $body');
      return body;
    }

    test(
      'GET /stats/sales: solo pedidos aceptados, por día de Lima, con días en 0',
      () async {
        final body = await get('/stats/sales?from=2026-09-28&to=2026-10-01');

        expect(body['from'], '2026-09-28');
        expect(body['to'], '2026-10-01');
        expect(body['timeZone'], 'America/Lima');
        expect(body['total'], '19.13');
        expect(body['orders'], 3);
        // 19.13 / 3 = 6.3766… → 6.38
        expect(body['averageTicket'], '6.38');
        expect(body['daily'], [
          {'date': '2026-09-28', 'total': '10.8', 'orders': 1},
          {'date': '2026-09-29', 'total': '0', 'orders': 0},
          {'date': '2026-09-30', 'total': '5', 'orders': 1},
          {'date': '2026-10-01', 'total': '3.33', 'orders': 1},
        ]);
      },
    );

    test('GET /stats/sales sin rango: los últimos 30 días hasta hoy', () async {
      final body = await get('/stats/sales');

      expect((body['from'], body['to']), ('2026-09-02', '2026-10-01'));
      expect(body['daily'], hasLength(30));
      expect(body['orders'], 3);
    });

    test(
      'GET /stats/top-products: por unidades y, a igual cantidad, por facturación',
      () async {
        final body = await get(
          '/stats/top-products?from=2026-09-28&to=2026-10-01',
        );

        expect(
          [
            for (final p in body['data'])
              (p['name'], p['quantity'], p['revenue']),
          ],
          [('Leche', 5, '5'), ('Arroz', 3, '11.13'), ('Aceite', 3, '3')],
        );
        expect(body['data'].first['productId'], leche.id.toString());

        final top1 = await get('/stats/top-products?limit=1');
        expect([for (final p in top1['data']) p['name']], ['Leche']);
      },
    );

    test(
      'GET /stats/overview: hoy, semana desde el lunes, mes y pedidos por estado',
      () async {
        final body = await get('/stats/overview');

        expect(body['timeZone'], 'America/Lima');
        expect(body['generatedAt'], testNow.toIso8601String());
        expect(body['today'], {
          'from': '2026-10-01',
          'to': '2026-10-01',
          'total': '3.33',
          'orders': 1,
          'averageTicket': '3.33',
        });
        expect(
          (body['week']['from'], body['week']['total']),
          (
            '2026-09-28',
            '19.13',
          ),
        );
        expect(
          (body['month']['from'], body['month']['orders']),
          (
            '2026-10-01',
            1,
          ),
        );
        expect(body['ordersByStatus'], {
          'pendingConfirmation': 1,
          'confirmed': 1,
          'outForDelivery': 1,
          'delivered': 1,
          'cancelled': 1,
          // Los del recojo en tienda, sin pedidos: en 0.
          'preparing': 0,
          'readyForPickup': 0,
        });
      },
    );

    test('low-stock y expiring reutilizan las alertas de inventory', () async {
      final lowStock = await get('/stats/low-stock');
      final expiring = await get('/stats/expiring?days=2');

      expect([for (final p in lowStock['data']) p['name']], ['Aceite']);
      expect(lowStock['data'].single['shortage'], 2);
      expect(expiring['until'], '2026-10-03');
      expect(
        [for (final p in expiring['data']) (p['name'], p['daysLeft'])],
        [
          ('Leche', 2),
        ],
      );
    });

    test('valida los rangos y los límites', () async {
      final reversed = await client.get(
        '/stats/sales?from=2026-10-05&to=2026-10-01',
        as: 'uid-staff',
      );
      final tooLong = await client.get(
        '/stats/sales?from=2025-01-01&to=2026-10-01',
        as: 'uid-staff',
      );

      expect(reversed.$2['message'], 'from no puede ser posterior a to');
      expect(tooLong.$2['message'], 'El rango no puede superar 366 días');
      for (final path in [
        '/stats/top-products?limit=51',
        '/stats/expiring?days=0',
        '/stats/overview?from=2026-10-01',
        '/stats/sales?from=ayer',
      ]) {
        expect((await client.get(path, as: 'uid-staff')).$1, 400, reason: path);
      }
    });

    test('todo /stats es solo para admin y staff', () async {
      for (final report in [
        'overview',
        'sales',
        'top-products',
        'low-stock',
        'expiring',
      ]) {
        final path = '/stats/$report';
        expect((await client.get(path)).$1, 401, reason: path);
        expect(
          (await client.get(path, as: 'uid-cliente')).$1,
          403,
          reason: path,
        );
      }
    });
  });
}
