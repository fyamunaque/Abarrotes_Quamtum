import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:abarrotes_server/src/common/store_time.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/inventory/inventory_routes.dart';
import 'package:abarrotes_server/src/inventory/inventory_service.dart';
import 'package:abarrotes_server/src/inventory/stock_alerts.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  // Sin rollback: cada sesión usa su propia conexión, como dos peticiones
  // reales. La base temporal del grupo se borra al terminar.
  withServerpod(
    'Movimientos simultáneos',
    rollbackDatabase: RollbackDatabase.disabled,
    (
      sessionBuilder,
      _,
    ) {
      test('dos salidas a la vez no pueden dejar el stock negativo', () async {
        final session = sessionBuilder.build();
        final staff = await insertUser(session, 'uid-staff', UserRole.staff);
        final category = await Category.db.insertRow(
          session,
          Category(name: 'Abarrotes'),
        );
        final product = await Product.db.insertRow(
          session,
          Product(
            name: 'Arroz',
            sku: 'ARROZ',
            priceCents: 450,
            categoryId: category.id!,
            currentStock: 10,
          ),
        );

        Future<Object> sell() => const InventoryService()
            .record(sessionBuilder.build(), (
              productId: product.id!,
              type: MovementType.outgoing,
              quantity: 6,
              reason: null,
            ), by: staff)
            .then<Object>(
              (movement) => movement.product!.currentStock,
              onError: (Object e) => e is ApiException ? e.statusCode : e,
            );

        final results = await Future.wait([sell(), sell()]);

        // Una vende y deja 4; la otra espera el bloqueo, ve 4 y recibe 409.
        expect(results, unorderedEquals([4, 409]));
        expect(
          (await Product.db.findById(session, product.id!))!.currentStock,
          4,
        );
        expect(await InventoryMovement.db.count(session), 1);
      });
    },
  );

  // testNow cae el 1 de octubre en Lima.
  final today = storeDay(testNow);

  withServerpod('Rutas de inventario', (sessionBuilder, _) {
    late Session session;
    late TestClient client;
    late Category abarrotes;
    late Product arroz;

    Future<Product> insertProduct(
      String name, {
      int stock = 10,
      int minStock = 2,
      bool active = true,
      String? expires,
    }) => Product.db.insertRow(
      session,
      Product(
        name: name,
        sku: name.toUpperCase().replaceAll(' ', '-'),
        priceCents: 450,
        categoryId: abarrotes.id!,
        active: active,
        currentStock: stock,
        minStock: minStock,
        expirationDate: expires == null ? null : utcMidnight(expires),
      ),
    );

    setUp(() async {
      session = sessionBuilder.build();
      final server = await serveRoutes(
        () => session,
        inventoryRoutes(
          const InventoryService(),
          StockAlerts(now: () => testNow),
          testVerifier(google),
        ),
      );
      client = TestClient(server, google);
      addTearDown(server.close);
      await insertUser(session, 'uid-staff', UserRole.staff);
      await insertUser(session, 'uid-cliente', UserRole.customer);
      abarrotes = await Category.db.insertRow(
        session,
        Category(name: 'Abarrotes'),
      );
      arroz = await insertProduct('Arroz');
    });

    Future<ApiResult> record(Map<String, Object?> movement) =>
        client.post('/inventory/movements', {
          'productId': arroz.id.toString(),
          ...movement,
        }, as: 'uid-staff');

    Future<int> stockOf(Product product) async =>
        (await Product.db.findById(session, product.id!))!.currentStock;

    group('POST /inventory/movements', () {
      test(
        'una entrada suma al stock y queda registrada con su autor',
        () async {
          final (status, body) = await record({
            'type': 'incoming',
            'quantity': 5,
            'reason': 'Compra al proveedor',
          });

          expect(status, 201);
          expect(body, {
            'id': isA<String>(),
            'type': 'incoming',
            'quantity': 5,
            'reason': 'Compra al proveedor',
            'createdAt': isA<String>(),
            'product': {
              'id': arroz.id.toString(),
              'name': 'Arroz',
              'sku': 'ARROZ',
              'currentStock': 15,
            },
            'user': {'id': isA<String>(), 'name': 'Usuario uid-staff'},
          });
          expect(await stockOf(arroz), 15);
          expect(await InventoryMovement.db.count(session), 1);
        },
      );

      test(
        'una salida resta, y el ajuste aplica la corrección con signo',
        () async {
          await record({'type': 'outgoing', 'quantity': 4});
          final (_, body) = await record({
            'type': 'adjustment',
            'quantity': -2,
            'reason': 'Merma: bolsas rotas',
          });

          expect(body['product']['currentStock'], 4);
          expect(body['quantity'], -2);
          expect(await stockOf(arroz), 4);
        },
      );

      test(
        'si el stock quedaría negativo responde 409 y no cambia nada',
        () async {
          final (status, body) = await record({
            'type': 'outgoing',
            'quantity': 11,
          });
          final adjustment = await record({
            'type': 'adjustment',
            'quantity': -11,
            'reason': 'Conteo',
          });

          expect(status, 409);
          expect(
            body['message'],
            'Stock insuficiente: Arroz tiene 10 unidades',
          );
          expect(adjustment.$1, 409);
          expect(await stockOf(arroz), 10);
          expect(await InventoryMovement.db.count(session), 0);
        },
      );

      test('se puede dejar el stock exactamente en 0', () async {
        final (status, body) = await record({
          'type': 'outgoing',
          'quantity': 10,
        });

        expect((status, body['product']['currentStock']), (201, 0));
      });

      test('valida cantidad según el tipo, y el motivo del ajuste', () async {
        expect(
          (await record({'type': 'incoming', 'quantity': 0})).$2['message'],
          [
            'quantity debe ser mayor que 0 en una entrada',
          ],
        );
        expect(
          (await record({'type': 'outgoing', 'quantity': -3})).$2['message'],
          [
            'quantity debe ser mayor que 0 en una salida',
          ],
        );
        expect(
          (await record({'type': 'adjustment', 'quantity': 0})).$2['message'],
          [
            'quantity no puede ser 0 en un ajuste',
            'reason es obligatorio en un ajuste',
          ],
        );
        expect(
          (await record({'type': 'in', 'quantity': 1.5})).$2['message'],
          [
            'type debe ser incoming, outgoing o adjustment',
            'quantity debe ser un número entero',
          ],
        );
      });

      test('un producto inexistente es 400', () async {
        final (status, body) = await client.post('/inventory/movements', {
          'productId': '0199a000-0000-7000-8000-000000000000',
          'type': 'incoming',
          'quantity': 1,
        }, as: 'uid-staff');

        expect(
          (status, body['message']),
          (400, 'El producto indicado no existe'),
        );
      });
    });

    group('GET /inventory/movements', () {
      test('historial paginado, del más reciente al más antiguo', () async {
        await record({'type': 'incoming', 'quantity': 5});
        await record({'type': 'outgoing', 'quantity': 3});
        final otro = await insertProduct('Azúcar');
        await client.post('/inventory/movements', {
          'productId': otro.id.toString(),
          'type': 'incoming',
          'quantity': 1,
        }, as: 'uid-staff');

        final (status, body) = await client.get(
          '/inventory/movements?productId=${arroz.id}',
          as: 'uid-staff',
        );

        expect(status, 200);
        expect((body['data'] as List).map((m) => m['type']), [
          'outgoing',
          'incoming',
        ]);
        expect(body['meta']['total'], 2);
        expect(body['data'].first['product'].keys, ['id', 'name', 'sku']);
      });

      test('con un producto inexistente es 404', () async {
        expect(
          (await client.get(
            '/inventory/movements?productId=0199a000-0000-7000-8000-000000000000',
            as: 'uid-staff',
          )).$1,
          404,
        );
      });
    });

    group('alertas', () {
      test(
        'stock bajo: activos con stock <= mínimo, los más críticos primero',
        () async {
          await insertProduct('Aceite', stock: 0, minStock: 5);
          await insertProduct('Fideos', stock: 4, minStock: 4);
          await insertProduct('Leche', stock: 1, minStock: 10);
          await insertProduct('Sal', stock: 0, minStock: 5, active: false);

          final (status, body) = await client.get(
            '/inventory/alerts/low-stock',
            as: 'uid-staff',
          );

          expect(status, 200);
          expect(
            [for (final p in body['data']) p['name']],
            [
              'Aceite',
              'Leche',
              'Fideos',
            ],
          );
          expect(body['data'].first, {
            'id': isA<String>(),
            'name': 'Aceite',
            'sku': 'ACEITE',
            'category': 'Abarrotes',
            'currentStock': 0,
            'minStock': 5,
            'shortage': 5,
          });
        },
      );

      test('por vencer: hasta hoy + days, incluidos los ya vencidos', () async {
        await insertProduct('Yogur', expires: addDays(today, -1));
        await insertProduct('Leche', expires: today);
        await insertProduct('Queso', expires: addDays(today, 7));
        await insertProduct('Mantequilla', expires: addDays(today, 8));
        await insertProduct('Jamón', expires: today, stock: 0);
        await insertProduct('Pan', expires: today, active: false);

        final (status, body) = await client.get(
          '/inventory/alerts/expiring',
          as: 'uid-staff',
        );

        expect(status, 200);
        expect(body['days'], 7);
        expect(body['until'], addDays(today, 7));
        expect(
          [for (final p in body['data']) (p['name'], p['daysLeft'])],
          [('Yogur', -1), ('Leche', 0), ('Queso', 7)],
        );
        expect(body['data'][1]['expirationDate'], today);

        final (_, wider) = await client.get(
          '/inventory/alerts/expiring?days=8',
          as: 'uid-staff',
        );
        expect(wider['data'], hasLength(4));
        expect(
          (await client.get(
            '/inventory/alerts/expiring?days=0',
            as: 'uid-staff',
          )).$1,
          400,
        );
      });
    });

    test('todo /inventory es solo para admin y staff', () async {
      for (final path in [
        '/inventory/movements',
        '/inventory/alerts/low-stock',
        '/inventory/alerts/expiring',
      ]) {
        expect((await client.get(path)).$1, 401, reason: path);
        expect(
          (await client.get(path, as: 'uid-cliente')).$1,
          403,
          reason: path,
        );
      }
      expect(
        (await client.post('/inventory/movements', {
          'productId': arroz.id.toString(),
          'type': 'incoming',
          'quantity': 1,
        }, as: 'uid-cliente')).$1,
        403,
      );
      expect(await stockOf(arroz), 10);
    });
  });
}
