import 'dart:convert';

import 'package:abarrotes_server/src/common/store_time.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/promotions/promotions_routes.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/promotions_setup.dart';
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
          testPromotions(),
          testVerifier(google),
          shoppers: testShoppers,
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
          'audience': 'everyone',
          'title': null,
        });
      },
    );

    test('POST y PATCH guardan la audiencia y el título', () async {
      final (status, created) = await create({
        'audience': 'vip',
        'title': '  Semana VIP  ',
      });
      expect(status, 201);
      expect(created['audience'], 'vip');
      expect(created['title'], 'Semana VIP');

      final (_, renamed) = await client.patch('/promotions/${created['id']}', {
        'audience': 'everyone',
        'title': 'Semana del arroz',
      }, as: 'uid-staff');
      expect(
        (renamed['audience'], renamed['title']),
        (
          'everyone',
          'Semana del arroz',
        ),
      );

      // Un PATCH sin title no lo toca; con title en null, lo borra.
      final (_, kept) = await client.patch('/promotions/${created['id']}', {
        'promoPrice': 3.8,
      }, as: 'uid-staff');
      expect(kept['title'], 'Semana del arroz');
      final (_, cleared) = await client.patch('/promotions/${created['id']}', {
        'title': null,
      }, as: 'uid-staff');
      expect(cleared['title'], isNull);
    });

    test('valida la audiencia y el título', () async {
      final (status, body) = await create({
        'audience': 'mayoristas',
        'title': 'x' * 101,
      });

      expect(status, 400);
      expect(body['message'], [
        'audience debe ser everyone o vip',
        'title admite como máximo 100 caracteres',
      ]);
    });

    test(
      'una promoción VIP y una para todos del mismo producto pueden cruzarse; '
      'dos VIP, no',
      () async {
        await create({});

        final (vipStatus, _) = await create({'audience': 'vip'});
        final (status, body) = await create({
          'audience': 'vip',
          'startDate': day(3),
          'endDate': day(10),
        });

        expect(vipStatus, 201);
        expect(status, 409);
        expect(
          body['message'],
          'Arroz Costeño 1 kg ya tiene una promoción VIP del 2026-10-01 al '
          '2026-10-07 que se cruza con esas fechas',
        );
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

    group('GET /promotions/active', () {
      late Product leche;
      late Map<String, Object?> vipPromo;

      setUp(() async {
        leche = await Product.db.insertRow(
          session,
          Product(
            name: 'Leche Gloria',
            sku: 'LECHE-1',
            priceCents: 420,
            categoryId: arroz.categoryId,
          ),
        );
        final apagado = await Product.db.insertRow(
          session,
          Product(
            name: 'Aceite Primor',
            sku: 'ACEITE-1',
            priceCents: 900,
            active: false,
            categoryId: arroz.categoryId,
          ),
        );
        await create({'title': 'Semana del arroz'});
        vipPromo =
            (await create({'audience': 'vip', 'promoPrice': 3.5})).$2
                as Map<String, Object?>;
        await create({'productId': leche.id.toString(), 'promoPrice': 3.6});
        // Ninguna de estas está vigente para nadie.
        await create({'startDate': day(10), 'endDate': day(12)});
        await create({'startDate': day(-9), 'endDate': day(-1)});
        await create({'active': false, 'audience': 'vip'});
        await create({'productId': apagado.id.toString(), 'promoPrice': 8});

        final admin = await insertUser(session, 'uid-admin', UserRole.admin);
        await insertUser(session, 'uid-vip', UserRole.customer);
        await insertVips(session, admin, ['vip@tienda.pe']);
      });

      test('sin token: solo las de todos y nada de las VIP', () async {
        final (status, body) = await client.get('/promotions/active');

        expect(status, 200);
        expect(body['meta'], {
          'total': 2,
          'page': 1,
          'limit': 20,
          'totalPages': 1,
        });
        expect(body['data'], [
          {
            'id': isA<String>(),
            'title': 'Semana del arroz',
            'audience': 'everyone',
            'promoPrice': '3.9',
            'startDate': '2026-10-01',
            'endDate': '2026-10-07',
            'product': {
              'id': arroz.id.toString(),
              'name': 'Arroz Costeño 1 kg',
              'price': '4.5',
              'imageUrl': null,
            },
          },
          containsPair('promoPrice', '3.6'),
        ]);
        final json = jsonEncode(body);
        expect(json, isNot(contains(vipPromo['id'] as String)));
        expect(json, isNot(contains('vip')));
      });

      test(
        'clientes no VIP, staff y VIPs sin verificar: igual que sin token',
        () async {
          for (final (status, body) in [
            await client.get('/promotions/active', as: 'uid-cliente'),
            await client.get('/promotions/active', as: 'uid-staff'),
            await client.get(
              '/promotions/active',
              as: 'uid-vip',
              email: 'vip@tienda.pe',
              emailVerified: false,
            ),
            // Un token inválido se atiende como visitante.
            await client.get('/promotions/active?limit=20', as: ''),
          ]) {
            expect(status, 200);
            expect(
              (body['data'] as List).map((p) => p['audience']),
              ['everyone', 'everyone'],
            );
          }
        },
      );

      test(
        'un VIP ve también las VIP, por producto y la más barata primero',
        () async {
          final (status, body) = await client.get(
            '/promotions/active',
            as: 'uid-vip',
            email: 'VIP@tienda.pe',
          );

          expect(status, 200);
          expect(body['meta']['total'], 3);
          expect(
            (body['data'] as List).map(
              (p) => [p['product']['name'], p['promoPrice'], p['audience']],
            ),
            [
              ['Arroz Costeño 1 kg', '3.5', 'vip'],
              ['Arroz Costeño 1 kg', '3.9', 'everyone'],
              ['Leche Gloria', '3.6', 'everyone'],
            ],
          );
        },
      );

      test('pagina y valida el query', () async {
        final (_, page2) = await client.get(
          '/promotions/active?limit=1&page=2',
        );
        expect((page2['data'] as List).single['promoPrice'], '3.6');

        final (status, body) = await client.get('/promotions/active?status=x');
        expect(status, 400);
        expect(body['message'], ['La propiedad status no está permitida']);
      });
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
