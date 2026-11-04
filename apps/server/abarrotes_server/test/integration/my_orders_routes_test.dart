// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:abarrotes_server/src/common/store_time.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/orders/orders_routes.dart';
import 'package:abarrotes_server/src/orders/orders_service.dart';
import 'package:serverpod/serverpod.dart' hide Order;
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/promotions_setup.dart';
import '../support/staff_setup.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

/// La búsqueda y los filtros de "Mis pedidos" (`GET /orders/mine`).
void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  withServerpod('Mis pedidos', (sessionBuilder, _) {
    late Session session;
    late TestClient client;
    late User ana;
    late Product arroz;
    late Product leche;

    /// Un pedido de [customer] con [products], del día [day] de la tienda.
    Future<Order> order(
      User customer,
      int number,
      List<Product> products, {
      OrderStatus status = OrderStatus.pendingConfirmation,
      FulfillmentType type = FulfillmentType.delivery,
      required String day,
    }) async {
      final at = storeDayStart(day).add(const Duration(hours: 12));
      final created = await Order.db.insertRow(
        session,
        Order(
          number: number,
          status: status,
          fulfillmentType: type,
          totalCents: 450 * products.length,
          deliveryAddress: type == FulfillmentType.delivery
              ? 'Av. Arequipa 123'
              : null,
          customerId: customer.id!,
          createdAt: at,
          updatedAt: at,
        ),
      );
      await OrderItem.db.insert(session, [
        for (final product in products)
          OrderItem(
            orderId: created.id!,
            productId: product.id!,
            quantity: 1,
            unitPriceCents: 450,
          ),
      ]);
      return created;
    }

    setUp(() async {
      session = sessionBuilder.build();
      final server = await serveRoutes(
        () => session,
        ordersRoutes(
          OrdersService(pricing: testPromotions(), now: () => testNow),
          testGuards(google),
          shoppers: testShoppers,
        ),
      );
      client = TestClient(server, google);
      addTearDown(server.close);
      ana = await insertUser(session, 'uid-ana');
      final luis = await insertUser(session, 'uid-luis');
      final category = await Category.db.insertRow(
        session,
        Category(name: 'Abarrotes'),
      );
      Future<Product> product(String name, String sku) => Product.db.insertRow(
        session,
        Product(
          name: name,
          sku: sku,
          priceCents: 450,
          categoryId: category.id!,
          currentStock: 10,
        ),
      );
      arroz = await product('Arroz Costeño 5 kg', 'ARROZ-5');
      leche = await product('Leche Gloria', 'LECHE-1');

      await order(
        ana,
        1001,
        [arroz],
        status: OrderStatus.delivered,
        day: '2026-09-20',
      );
      await order(
        ana,
        1002,
        [leche],
        status: OrderStatus.cancelled,
        day: '2026-09-25',
      );
      await order(
        ana,
        1003,
        [arroz, leche],
        type: FulfillmentType.pickup,
        status: OrderStatus.preparing,
        day: '2026-09-28',
      );
      await order(ana, 1004, [arroz], day: '2026-09-30');
      // De otro cliente: nunca sale en los de Ana.
      await order(luis, 1005, [arroz], day: '2026-09-30');
    });

    Future<List<Object?>> numbers(String query) async {
      final (status, body) = await client.get(
        '/orders/mine?$query',
        as: 'uid-ana',
      );
      expect(status, 200, reason: query);
      return [for (final o in body['data'] as List) o['number']];
    }

    test('sin filtros, todos los suyos y solo los suyos', () async {
      expect(await numbers(''), [1004, 1003, 1002, 1001]);
    });

    test('busca por N.º o por un producto, sin mayúsculas', () async {
      expect(await numbers('search=1003'), [1003]);
      expect(await numbers('search=leche'), [1003, 1002]);
      expect(await numbers('search=ARROZ%20cost'), [1004, 1003, 1001]);
      // El de otro cliente, aunque se busque su número, no.
      expect(await numbers('search=1005'), isEmpty);
    });

    test('por estado: en curso, entregados o cancelados', () async {
      expect(await numbers('state=active'), [1004, 1003]);
      expect(await numbers('state=delivered'), [1001]);
      expect(await numbers('state=cancelled'), [1002]);
      final (status, body) = await client.get(
        '/orders/mine?state=pendiente',
        as: 'uid-ana',
      );
      expect(status, 400);
      expect(body['message'], [
        'state debe ser active, delivered o cancelled',
      ]);
    });

    test('por tipo de entrega y por días de la tienda', () async {
      expect(await numbers('fulfillmentType=pickup'), [1003]);
      expect(await numbers('from=2026-09-25&to=2026-09-28'), [1003, 1002]);
      expect(await numbers('to=2026-09-20'), [1001]);
      expect(
        await numbers('state=active&fulfillmentType=delivery&search=arroz'),
        [1004],
      );
      expect(
        (await client.get(
          '/orders/mine?from=2026-09-30&to=2026-09-01',
          as: 'uid-ana',
        )).$1,
        400,
      );
    });

    test('pagina con los filtros', () async {
      final (_, body) = await client.get(
        '/orders/mine?state=active&limit=1&page=2',
        as: 'uid-ana',
      );

      expect(body['meta']['total'], 2);
      expect([for (final o in body['data'] as List) o['number']], [1003]);
    });
  });
}
