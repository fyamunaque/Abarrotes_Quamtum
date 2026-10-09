import 'package:abarrotes_server/src/common/store_time.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/promotions/promotions_routes.dart';
import 'package:abarrotes_server/src/promotions/promotions_service.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  // testNow cae el 1 de octubre en Lima.
  final today = storeDay(testNow);
  String day(int offset) => addDays(today, offset);

  withServerpod('Rutas de promociones', (sessionBuilder, _) {
    late Session session;
    late TestClient client;
    late Product arroz;

    setUp(() async {
      session = sessionBuilder.build();
      final server = await serveRoutes(
        () => session,
        promotionsRoutes(
          PromotionsService(now: () => testNow),
          testVerifier(google),
        ),
      );
      client = TestClient(server, google);
      addTearDown(server.close);
      await insertUser(session, 'uid-staff', UserRole.staff);
      await insertUser(session, 'uid-cliente', UserRole.customer);
      final category = await Category.db.insertRow(
        session,
        Category(name: 'Abarrotes'),
      );
      arroz = await Product.db.insertRow(
        session,
        Product(
          name: 'Arroz Costeño 1 kg',
          sku: 'ARROZ-1',
          priceCents: 450,
          categoryId: category.id!,
        ),
      );
    });

    Future<ApiResult> create(Map<String, Object?> changes) =>
        client.post('/promotions', {
          'productId': arroz.id.toString(),
          'promoPrice': 3.9,
          'startDate': day(0),
          'endDate': day(6),
          ...changes,
        }, as: 'uid-staff');

    test(
      'POST crea una promoción vigente (active) con días de la tienda',
      () async {
        final (status, body) = await create({});

        expect(status, 201);
        expect(body, {
          'id': isA<String>(),
          'productId': arroz.id.toString(),
          'product': {
            'id': arroz.id.toString(),
            'name': 'Arroz Costeño 1 kg',
            'sku': 'ARROZ-1',
            'price': '4.5',
          },
          'promoPrice': '3.9',
          'startDate': '2026-10-01',
          'endDate': '2026-10-07',
          'active': true,
          'status': 'active',
        });
      },
    );

    test('el estado sale de la fecha: scheduled, expired y disabled', () async {
      final scheduled = await create({
        'startDate': day(10),
        'endDate': day(12),
      });
      final expired = await create({'startDate': day(-9), 'endDate': day(-1)});
      final disabled = await create({'active': false});

      expect(scheduled.$2['status'], 'scheduled');
      expect(expired.$2['status'], 'expired');
      expect(disabled.$2['status'], 'disabled');
    });

    test(
      'dos promociones encendidas del mismo producto no se cruzan (409)',
      () async {
        await create({});

        final (status, body) = await create({
          'startDate': day(3),
          'endDate': day(10),
        });

        expect(status, 409);
        expect(
          body['message'],
          'Arroz Costeño 1 kg ya tiene una promoción del 2026-10-01 al '
          '2026-10-07 que se cruza con esas fechas',
        );
        // Apagada sí puede cruzarse, y desde el día siguiente al último, también.
        expect((await create({'active': false})).$1, 201);
        expect(
          (await create({'startDate': day(7), 'endDate': day(8)})).$1,
          201,
        );
      },
    );

    test('el precio promocional debe ser menor al normal (400)', () async {
      final (status, body) = await create({'promoPrice': 4.5});

      expect(status, 400);
      expect(
        body['message'],
        'El precio promocional debe ser menor al precio normal (4.5)',
      );
    });

    test('valida fechas, montos y el producto', () async {
      expect(
        (await create({'startDate': day(5), 'endDate': day(1)})).$2['message'],
        'endDate no puede ser anterior a startDate',
      );
      expect((await create({'startDate': '2026-02-30'})).$2['message'], [
        'startDate debe ser una fecha AAAA-MM-DD',
      ]);
      expect((await create({'promoPrice': 0})).$1, 400);
      expect((await create({'promoPrice': 3.999})).$1, 400);
      final missing = await create({
        'productId': '0199a000-0000-7000-8000-000000000000',
      });
      expect(missing.$1, 400);
      expect(missing.$2['message'], 'El producto indicado no existe');
    });

    test('PATCH apaga la promoción y no permite cambiar el producto', () async {
      final (_, created) = await create({});

      final (status, body) = await client.patch(
        '/promotions/${created['id']}',
        {'active': false},
        as: 'uid-staff',
      );
      expect((status, body['status']), (200, 'disabled'));

      final otherProduct = await client.patch(
        '/promotions/${created['id']}',
        {'productId': arroz.id.toString()},
        as: 'uid-staff',
      );
      expect(otherProduct.$2['message'], [
        'La propiedad productId no está permitida',
      ]);
    });

    test('PATCH valida la promoción tal como quedaría', () async {
      await create({});
      final (_, later) = await create({
        'startDate': day(10),
        'endDate': day(12),
      });

      final moved = await client.patch(
        '/promotions/${later['id']}',
        {'startDate': day(5)},
        as: 'uid-staff',
      );
      final cheaper = await client.patch(
        '/promotions/${later['id']}',
        {'promoPrice': 3.5, 'endDate': day(14)},
        as: 'uid-staff',
      );

      expect(moved.$1, 409);
      expect(cheaper.$1, 200);
      expect(cheaper.$2['promoPrice'], '3.5');
      expect(cheaper.$2['endDate'], day(14));
    });

    test(
      'GET lista paginado, la de inicio más reciente primero, y filtra',
      () async {
        await create({'startDate': day(-9), 'endDate': day(-1)});
        await create({});
        await create({'startDate': day(10), 'endDate': day(12)});

        final (status, body) = await client.get(
          '/promotions?limit=2',
          as: 'uid-staff',
        );
        expect(status, 200);
        expect((body['data'] as List).map((p) => p['status']), [
          'scheduled',
          'active',
        ]);
        expect(body['meta'], {
          'total': 3,
          'page': 1,
          'limit': 2,
          'totalPages': 2,
        });

        final expired = await client.get(
          '/promotions?status=expired&productId=${arroz.id}',
          as: 'uid-staff',
        );
        expect((expired.$2['data'] as List).single['status'], 'expired');
        expect(
          (await client.get('/promotions?status=otro', as: 'uid-staff')).$1,
          400,
        );
      },
    );

    test('DELETE borra (204) y después es 404', () async {
      final (_, created) = await create({});

      expect(
        await client.delete('/promotions/${created['id']}', as: 'uid-staff'),
        (204, null),
      );
      expect(
        (await client.get(
          '/promotions/${created['id']}',
          as: 'uid-staff',
        )).$1,
        404,
      );
    });

    test('todo /promotions es solo para admin y staff', () async {
      expect((await client.get('/promotions')).$1, 401);
      expect((await client.get('/promotions', as: 'uid-cliente')).$1, 403);
      expect(
        (await client.post('/promotions', {}, as: 'uid-cliente')).$1,
        403,
      );
    });
  });
}
