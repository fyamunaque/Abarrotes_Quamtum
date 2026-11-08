import 'package:abarrotes_server/src/common/store_time.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/products/products_routes.dart';
import 'package:abarrotes_server/src/products/products_service.dart';
import 'package:abarrotes_server/src/promotions/promotion_rules.dart';
import 'package:serverpod/serverpod.dart' hide Order;
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/promotions_setup.dart';
import '../support/staff_setup.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Frecuentes (lo que más pide el cliente) y Sugeridos (lo más vendido de la
/// tienda), para las pestañas de la portada.
void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  final today = storeDay(testNow);

  withServerpod('Frecuentes y Sugeridos', (sessionBuilder, _) {
    late Session session;
    late TestClient client;
    late Category abarrotes;
    late User ana;
    late User luis;

    Future<Product> product(
      String name, {
      int stock = 20,
      bool active = true,
      int addedDaysAgo = 60,
    }) => Product.db.insertRow(
      session,
      Product(
        name: name,
        sku: name.toUpperCase().replaceAll(' ', '-'),
        priceCents: 450,
        categoryId: abarrotes.id!,
        currentStock: stock,
        active: active,
        createdAt: testNow.subtract(Duration(days: addedDaysAgo)),
      ),
    );

    /// Un pedido de [customer] de hace [daysAgo] días con [lines]
    /// (producto, cantidad, si es regalo).
    Future<void> order(
      User customer,
      List<(Product, int, bool)> lines, {
      int daysAgo = 1,
      OrderStatus status = OrderStatus.delivered,
    }) async {
      final createdAt = testNow.subtract(Duration(days: daysAgo));
      final order = await Order.db.insertRow(
        session,
        Order(
          status: status,
          fulfillmentType: FulfillmentType.delivery,
          totalCents: 450,
          deliveryAddress: 'Av. Arequipa 123',
          customerId: customer.id!,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
      await OrderItem.db.insert(session, [
        for (final (product, quantity, gift) in lines)
          OrderItem(
            orderId: order.id!,
            productId: product.id!,
            quantity: quantity,
            unitPriceCents: gift ? 0 : 450,
            listUnitPriceCents: 450,
            lineTotalCents: gift ? 0 : quantity * 450,
            isGift: gift,
          ),
      ]);
    }

    List<String> names(dynamic body) => [
      for (final product in body['items'] as List) product['name'] as String,
    ];

    setUp(() async {
      session = sessionBuilder.build();
      final server = await serveRoutes(
        () => session,
        productsRoutes(
          ProductsService(pricing: testPromotions(), now: () => testNow),
          testGuards(google),
          shoppers: testShoppers,
        ),
      );
      client = TestClient(server, google);
      addTearDown(server.close);
      abarrotes = await Category.db.insertRow(
        session,
        Category(name: 'Abarrotes'),
      );
      ana = await insertUser(session, 'uid-ana');
      luis = await insertUser(session, 'uid-luis');
    });

    group('Frecuentes', () {
      test('ordena por cantidad de pedidos', () async {
        final arroz = await product('Arroz');
        final leche = await product('Leche');
        for (var i = 1; i <= 3; i++) {
          await order(ana, [(arroz, 1, false)], daysAgo: i);
        }
        await order(ana, [(leche, 9, false)]);

        final (status, body) = await client.get(
          '/products/frequent',
          as: 'uid-ana',
        );

        expect(status, 200);
        expect(names(body), ['Arroz', 'Leche']);
      });

      test('a igual cantidad de pedidos, primero el más reciente', () async {
        final arroz = await product('Arroz');
        final leche = await product('Leche');
        await order(ana, [(arroz, 1, false)], daysAgo: 5);
        await order(ana, [(leche, 1, false)], daysAgo: 2);

        final (_, body) = await client.get('/products/frequent', as: 'uid-ana');

        expect(names(body), ['Leche', 'Arroz']);
      });

      test(
        'no cuenta cancelados, regalos, dados de baja ni pedidos de hace más '
        'de 180 días',
        () async {
          final arroz = await product('Arroz');
          final cancelado = await product('Cancelado');
          final regalo = await product('Regalo');
          final deBaja = await product('De baja', active: false);
          final viejo = await product('Viejo');
          await order(ana, [(arroz, 1, false), (regalo, 1, true)]);
          await order(ana, [
            (cancelado, 1, false),
          ], status: OrderStatus.cancelled);
          await order(ana, [(deBaja, 1, false)]);
          await order(ana, [(viejo, 1, false)], daysAgo: 181);

          final (_, body) = await client.get(
            '/products/frequent',
            as: 'uid-ana',
          );

          expect(names(body), ['Arroz']);
        },
      );

      test('no mezcla los pedidos de otro cliente', () async {
        final arroz = await product('Arroz');
        final leche = await product('Leche');
        await order(ana, [(arroz, 1, false)]);
        await order(luis, [(leche, 1, false)]);

        final (_, body) = await client.get('/products/frequent', as: 'uid-ana');

        expect(names(body), ['Arroz']);
      });

      test('sin cuenta es 401', () async {
        final (status, _) = await client.get('/products/frequent');

        expect(status, 401);
      });

      test('hasta 20', () async {
        for (var i = 0; i < 22; i++) {
          final p = await product('Producto ${i.toString().padLeft(2, '0')}');
          await order(ana, [(p, 1, false)], daysAgo: 1 + i);
        }

        final (_, body) = await client.get('/products/frequent', as: 'uid-ana');

        expect(names(body), hasLength(20));
      });
    });

    group('Sugeridos', () {
      test('los más vendidos de 30 días, con stock', () async {
        final arroz = await product('Arroz');
        final leche = await product('Leche');
        final agotado = await product('Agotado', stock: 0);
        final viejo = await product('Viejo');
        await order(luis, [(arroz, 5, false), (leche, 2, false)]);
        await order(luis, [(agotado, 50, false)]);
        await order(luis, [(viejo, 90, false)], daysAgo: 31);

        final (status, body) = await client.get('/products/suggested');

        expect(status, 200);
        expect(names(body), ['Arroz', 'Leche']);
      });

      test('no cuenta cancelados, regalos ni dados de baja', () async {
        final arroz = await product('Arroz');
        final cancelado = await product('Cancelado');
        final regalo = await product('Regalo');
        final deBaja = await product('De baja', active: false);
        await order(luis, [(arroz, 1, false), (regalo, 50, true)]);
        await order(luis, [
          (cancelado, 50, false),
        ], status: OrderStatus.cancelled);
        await order(luis, [(deBaja, 50, false)]);

        final (_, body) = await client.get('/products/suggested');

        expect(names(body), ['Arroz']);
      });

      test('a igual cantidad de unidades, por nombre', () async {
        final leche = await product('Leche');
        final arroz = await product('Arroz');
        await order(luis, [(leche, 2, false), (arroz, 2, false)]);

        final (_, body) = await client.get('/products/suggested');

        expect(names(body), ['Arroz', 'Leche']);
      });

      test('con una cuenta VIP, el precio VIP', () async {
        final arroz = await product('Arroz');
        await order(luis, [(arroz, 3, false)]);
        final admin = await insertStaff(session, 'uid-admin');
        await insertUser(session, 'uid-vip');
        await insertVips(session, admin, ['vip@tienda.pe']);
        final period = toStoredPeriod(today, addDays(today, 6));
        await Promotion.db.insertRow(
          session,
          Promotion(
            productId: arroz.id!,
            promoPriceCents: 350,
            startDate: period.startDate,
            endDate: period.endDate,
            audience: PromotionAudience.vip,
            title: 'Solo VIP',
          ),
        );

        final (_, body) = await client.get(
          '/products/suggested',
          as: 'uid-vip',
          email: 'vip@tienda.pe',
        );

        expect((body['items'] as List).single['unitPrice'], '3.5');
      });

      test('sin ventas en 30 días, lo más nuevo con stock', () async {
        await product('Viejo', addedDaysAgo: 90);
        await product('Nuevo', addedDaysAgo: 2);
        await product('Agotado', stock: 0, addedDaysAgo: 1);
        await product('De baja', active: false, addedDaysAgo: 1);

        final (status, body) = await client.get('/products/suggested');

        expect(status, 200);
        expect(names(body), ['Nuevo', 'Viejo']);
      });

      test(
        'sin otras ventas, lo nuevo sin los Frecuentes de la cuenta',
        () async {
          final arroz = await product('Arroz', addedDaysAgo: 1);
          await product('Leche', addedDaysAgo: 5);
          await order(ana, [(arroz, 1, false)]);

          final (_, body) = await client.get(
            '/products/suggested',
            as: 'uid-ana',
          );

          expect(names(body), ['Leche']);
        },
      );

      test('con cuenta, no repite sus Frecuentes', () async {
        final arroz = await product('Arroz');
        final leche = await product('Leche');
        await order(luis, [(arroz, 5, false), (leche, 2, false)]);
        await order(ana, [(arroz, 1, false)]);

        final (_, body) = await client.get(
          '/products/suggested',
          as: 'uid-ana',
        );

        expect(names(body), ['Leche']);
      });
    });

    test('las dos traen el precio con la promoción del cliente', () async {
      final arroz = await product('Arroz');
      await order(luis, [(arroz, 3, false)]);
      final admin = await insertStaff(session, 'uid-admin');
      final vip = await insertUser(session, 'uid-vip');
      await insertVips(session, admin, ['vip@tienda.pe']);
      await order(vip, [(arroz, 1, false)]);
      final period = toStoredPeriod(today, addDays(today, 6));
      await Promotion.db.insertRow(
        session,
        Promotion(
          productId: arroz.id!,
          promoPriceCents: 350,
          startDate: period.startDate,
          endDate: period.endDate,
          audience: PromotionAudience.vip,
          title: 'Solo VIP',
        ),
      );

      final (_, frequent) = await client.get(
        '/products/frequent',
        as: 'uid-vip',
        email: 'vip@tienda.pe',
      );
      final (_, suggested) = await client.get('/products/suggested');

      expect((frequent['items'] as List).single['unitPrice'], '3.5');
      // Sin cuenta, el precio de siempre.
      expect((suggested['items'] as List).single['unitPrice'], '4.5');
    });
  });
}
