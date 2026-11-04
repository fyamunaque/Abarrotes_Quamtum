import 'dart:convert';

import 'package:abarrotes_server/src/common/store_time.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/promotions/promotions_routes.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/fake_push.dart';
import '../support/http_harness.dart';
import '../support/staff_setup.dart';
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
    late RecordingAnnouncer announcer;

    setUp(() async {
      session = sessionBuilder.build();
      announcer = RecordingAnnouncer();
      final server = await serveRoutes(
        () => session,
        promotionsRoutes(
          testPromotions(announcer: announcer),
          testGuards(google),
          shoppers: testShoppers,
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
          'type': 'specialPrice',
          'label': 'Precio especial S/ 3.90',
          'promoPrice': '3.9',
          'percent': null,
          'buyQuantity': null,
          'payQuantity': null,
          'giftProduct': null,
          'giftQuantity': null,
          'startDate': '2026-10-01',
          'endDate': '2026-10-07',
          'active': true,
          'status': 'active',
          'audience': 'everyone',
          'promoCode': null,
          'title': null,
          'recipients': <Object?>[],
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

    group('tipos', () {
      late Product sal;

      setUp(() async {
        sal = await Product.db.insertRow(
          session,
          Product(
            name: 'Sal 1 kg',
            sku: 'SAL-1',
            priceCents: 150,
            categoryId: arroz.categoryId,
          ),
        );
      });

      /// Una promoción de [type] para el arroz, sin precio promocional, en
      /// los días [from]–[to] (así no se cruzan entre ellas).
      Future<ApiResult> typed(
        String type,
        Map<String, Object?> fields, {
        int from = 0,
        int to = 1,
      }) => client.post('/promotions', {
        'productId': arroz.id.toString(),
        'type': type,
        'startDate': day(from),
        'endDate': day(to),
        ...fields,
      }, as: 'uid-staff');

      test('crea cada tipo con sus campos', () async {
        final (percentStatus, percent) = await typed('percentOff', {
          'percent': 20,
        });
        expect(percentStatus, 201);
        expect(
          (percent['type'], percent['label'], percent['promoPrice']),
          ('percentOff', '20 % menos', null),
        );
        expect(percent['percent'], 20);

        final (_, twoForOne) = await typed(
          'buyXPayY',
          {
            'buyQuantity': 2,
            'payQuantity': 1,
          },
          from: 2,
          to: 3,
        );
        expect(twoForOne['label'], '2x1');
        expect(
          (twoForOne['buyQuantity'], twoForOne['payQuantity']),
          (2, 1),
        );

        final (_, extra) = await typed(
          'extraUnit',
          {
            'buyQuantity': 2,
            'percent': 50,
          },
          from: 4,
          to: 5,
        );
        expect(extra['label'], '2.ª al 50 %');

        final (giftStatus, gift) = await typed(
          'gift',
          {
            'buyQuantity': 2,
            'giftProductId': sal.id.toString(),
            'giftQuantity': 1,
          },
          from: 6,
          to: 7,
        );
        expect(giftStatus, 201);
        expect(gift['label'], 'Regalo: Sal 1 kg');
        expect(gift['giftProduct'], {
          'id': sal.id.toString(),
          'name': 'Sal 1 kg',
        });
        expect(gift['giftQuantity'], 1);
      });

      test(
        'si el regalo se dio de baja, la promoción se puede apagar',
        () async {
          final (_, gift) = await typed('gift', {
            'buyQuantity': 2,
            'giftProductId': sal.id.toString(),
            'giftQuantity': 1,
          });
          await Product.db.updateRow(session, sal.copyWith(active: false));

          // El panel manda el mismo regalo al guardar.
          final (status, body) = await client.patch(
            '/promotions/${gift['id']}',
            {
              'active': false,
              'giftProductId': sal.id.toString(),
            },
            as: 'uid-staff',
          );

          expect((status, body['active']), (200, false));
        },
      );

      test('sin type es precio especial, como antes', () async {
        final (status, body) = await create({});

        expect(status, 201);
        expect(body['type'], 'specialPrice');
        expect(body['label'], 'Precio especial S/ 3.90');
        expect(body['giftProduct'], isNull);
      });

      test('valida los campos de cada tipo', () async {
        Future<Object?> error(String type, Map<String, Object?> fields) async {
          final (status, body) = await typed(type, fields);
          expect(status, 400, reason: '$type $fields');
          return body['message'];
        }

        Matcher says(String message) =>
            anyOf(equals(message), contains(message));

        expect(
          await error('percentOff', {'percent': 0}),
          says('percent debe estar entre 1 y 90'),
        );
        expect(
          await error('percentOff', {'percent': 91}),
          says('percent debe estar entre 1 y 90'),
        );
        expect(
          await error('extraUnit', {'buyQuantity': 2, 'percent': 101}),
          says('percent debe estar entre 1 y 100'),
        );
        expect(
          await error('buyXPayY', {'buyQuantity': 2, 'payQuantity': 2}),
          says('payQuantity debe ser menor que buyQuantity'),
        );
        expect(
          await error('buyXPayY', {'buyQuantity': 11, 'payQuantity': 1}),
          says('buyQuantity debe estar entre 2 y 10'),
        );
        expect(
          await error('gift', {
            'buyQuantity': 11,
            'giftProductId': sal.id.toString(),
            'giftQuantity': 1,
          }),
          says('buyQuantity debe estar entre 1 y 10'),
        );
        expect(
          await error('gift', {
            'buyQuantity': 2,
            'giftProductId': sal.id.toString(),
            'giftQuantity': 11,
          }),
          says('giftQuantity debe estar entre 1 y 10'),
        );
        expect(
          await error('gift', {
            'buyQuantity': 2,
            'giftProductId': arroz.id.toString(),
            'giftQuantity': 1,
          }),
          says('El regalo tiene que ser otro producto'),
        );
        final apagado = await Product.db.insertRow(
          session,
          Product(
            name: 'Azúcar',
            sku: 'AZU-1',
            priceCents: 300,
            categoryId: arroz.categoryId,
            active: false,
          ),
        );
        for (final id in [
          apagado.id.toString(),
          '0199a000-0000-7000-8000-000000000000',
        ]) {
          expect(
            await error('gift', {
              'buyQuantity': 2,
              'giftProductId': id,
              'giftQuantity': 1,
            }),
            says('El producto de regalo no existe o está dado de baja'),
          );
        }
        expect(
          await error('buyXPayY', {
            'buyQuantity': 2,
            'payQuantity': 1,
            'percent': 10,
          }),
          says('percent no va en una promoción buyXPayY'),
        );
        expect(
          await error('specialPrice', {}),
          says('promoPrice es obligatorio en un precio especial'),
        );
        expect(await Promotion.db.count(session), 0);
      });

      test('el tipo no cambia al editar', () async {
        final (_, created) = await create({});

        final (status, body) = await client.patch(
          '/promotions/${created['id']}',
          {'type': 'percentOff'},
          as: 'uid-staff',
        );

        expect(status, 400);
        expect(body['message'], ['La propiedad type no está permitida']);
      });
    });

    test('valida la audiencia y el título', () async {
      final (status, body) = await create({
        'audience': 'mayoristas',
        'title': 'x' * 101,
      });

      expect(status, 400);
      expect(body['message'], [
        'audience debe ser everyone, vip, selected o code',
        'title admite como máximo 100 caracteres',
      ]);
    });

    test(
      'una que se cruza avisa con la lista; confirmOverlap la crea',
      () async {
        await create({});

        final (status, body) = await create({
          'audience': 'vip',
          'promoPrice': 3.5,
          'startDate': day(3),
          'endDate': day(9),
        });

        expect(status, 409);
        expect(
          body['message'],
          'Se acumula con otras promociones del producto',
        );
        expect(body['overlaps'], [
          {
            'id': isA<String>(),
            'type': 'specialPrice',
            'audience': 'everyone',
            'label': 'Precio especial S/ 3.90',
            'startDate': day(0),
            'endDate': day(6),
          },
        ]);
        expect(await Promotion.db.count(session), 1);

        final (confirmed, _) = await create({
          'audience': 'vip',
          'promoPrice': 3.5,
          'startDate': day(3),
          'endDate': day(9),
          'confirmOverlap': true,
        });
        expect(confirmed, 201);
      },
    );

    test('editar no se cruza consigo misma', () async {
      final (_, created) = await create({});

      final (status, _) = await client.patch('/promotions/${created['id']}', {
        'promoPrice': 3.5,
      }, as: 'uid-staff');

      expect(status, 200);
    });

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
      'misma audiencia y tipo también se acumula si se confirma; apagadas, '
      'de otro producto o en otras fechas no avisan',
      () async {
        await create({});

        final (status, body) = await create({
          'startDate': day(3),
          'endDate': day(10),
        });
        expect(status, 409);
        expect((body['overlaps'] as List).single['audience'], 'everyone');
        expect(
          (await create({
            'startDate': day(3),
            'endDate': day(10),
            'confirmOverlap': true,
          })).$1,
          201,
        );

        // Apagada, desde el día siguiente al último o de otro producto: nada
        // que avisar.
        expect((await create({'active': false})).$1, 201);
        expect(
          (await create({'startDate': day(11), 'endDate': day(12)})).$1,
          201,
        );
        final leche = await Product.db.insertRow(
          session,
          Product(
            name: 'Leche',
            sku: 'LECHE-9',
            priceCents: 420,
            categoryId: arroz.categoryId,
          ),
        );
        expect(
          (await create({
            'productId': leche.id.toString(),
            'promoPrice': 4,
          })).$1,
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
            (await create({
                  'audience': 'vip',
                  'promoPrice': 3.5,
                  'confirmOverlap': true,
                })).$2
                as Map<String, Object?>;
        await create({'productId': leche.id.toString(), 'promoPrice': 3.6});
        // Ninguna de estas está vigente para nadie.
        await create({'startDate': day(10), 'endDate': day(12)});
        await create({'startDate': day(-9), 'endDate': day(-1)});
        await create({'active': false, 'audience': 'vip'});
        await create({'productId': apagado.id.toString(), 'promoPrice': 8});

        final admin = await insertStaff(session, 'uid-admin');
        await insertUser(session, 'uid-vip');
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
            'type': 'specialPrice',
            'label': 'Precio especial S/ 3.90',
            'promoPrice': '3.9',
            'percent': null,
            'buyQuantity': null,
            'payQuantity': null,
            'giftProduct': null,
            'giftQuantity': null,
            'startDate': '2026-10-01',
            'endDate': '2026-10-07',
            'product': {
              'id': arroz.id.toString(),
              'name': 'Arroz Costeño 1 kg',
              'price': '4.5',
              'imageUrl': null,
              'categoryId': arroz.categoryId.toString(),
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

      test('los otros tipos, solo con types=all (las apps de antes leen '
          'promoPrice)', () async {
        final (created, _) = await client.post('/promotions', {
          'productId': leche.id.toString(),
          'type': 'buyXPayY',
          'buyQuantity': 2,
          'payQuantity': 1,
          'startDate': day(0),
          'endDate': day(6),
          'confirmOverlap': true,
        }, as: 'uid-staff');
        expect(created, 201);

        final (_, before) = await client.get('/promotions/active');
        final (_, all) = await client.get('/promotions/active?types=all');

        List<Object?> types(Object? body) => [
          for (final p in (body as Map)['data'] as List) (p as Map)['type'],
        ];
        expect(types(before), everyElement('specialPrice'));
        expect(types(all), contains('buyXPayY'));
        expect((await client.get('/promotions/active?types=x')).$1, 400);
      });

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

    group('clientes elegidos', () {
      late VipCustomer ana;
      late VipCustomer luis;
      late VipCustomer beto;

      Future<VipCustomer> vip(String email) async =>
          (await VipCustomer.db.findFirstRow(
            session,
            where: (vip) => vip.email.equals(email),
          ))!;

      Future<void> deactivate(VipCustomer customer) => VipCustomer.db
          .updateRow(session, customer.copyWith(active: false))
          .then((_) {});

      Future<ApiResult> selected(
        List<VipCustomer> recipients, [
        Map<String, Object?> changes = const {},
      ]) => create({
        'audience': 'selected',
        'promoPrice': 3.2,
        'recipientIds': [for (final r in recipients) r.id.toString()],
        ...changes,
      });

      Future<ApiResult> patch(String id, Map<String, Object?> body) =>
          client.patch('/promotions/$id', body, as: 'uid-staff');

      List<Object?> emailsOf(Map<String, Object?> body) => [
        for (final r in body['recipients'] as List) (r as Map)['email'],
      ];

      setUp(() async {
        final admin = await insertStaff(session, 'uid-admin');
        await insertVips(session, admin, [
          'luis@tienda.pe',
          'ana@tienda.pe',
          'beto@tienda.pe',
        ]);
        ana = await vip('ana@tienda.pe');
        luis = await vip('luis@tienda.pe');
        beto = await vip('beto@tienda.pe');
        await deactivate(beto);
      });

      test('POST guarda los elegidos; el panel los ve por correo', () async {
        final (status, body) = await selected([luis, ana]);

        expect(status, 201);
        expect(body['audience'], 'selected');
        expect(body['recipients'], [
          {'id': ana.id.toString(), 'email': 'ana@tienda.pe'},
          {'id': luis.id.toString(), 'email': 'luis@tienda.pe'},
        ]);
        expect(await PromotionRecipient.db.count(session), 2);
        // Las demás, sin elegidos.
        final (_, everyone) = await create({
          'promoPrice': 4,
          'confirmOverlap': true,
        });
        expect(everyone['recipients'], isEmpty);
      });

      test('valida los elegidos', () async {
        Future<Object?> error(Map<String, Object?> body) async {
          final (status, error) = await create(body);
          expect(status, 400, reason: '$body');
          return error['message'];
        }

        expect(
          await error({'audience': 'selected'}),
          'Elige al menos un cliente VIP',
        );
        expect(
          await error({'audience': 'selected', 'recipientIds': []}),
          ['recipientIds debe tener entre 1 y 100 elementos'],
        );
        expect(
          await error({
            'audience': 'selected',
            'recipientIds': ['ana'],
          }),
          ['recipientIds[0] debe ser un UUID'],
        );
        for (final id in [
          beto.id.toString(),
          '0199a000-0000-7000-8000-000000000000',
        ]) {
          expect(
            await error({
              'audience': 'selected',
              'recipientIds': [ana.id.toString(), id],
            }),
            'Algún cliente elegido no es un cliente VIP activo',
          );
        }
        expect(
          await error({
            'audience': 'vip',
            'recipientIds': [ana.id.toString()],
          }),
          'recipientIds solo va en una promoción para clientes elegidos',
        );
        expect(await Promotion.db.count(session), 0);
      });

      test('también avisan del cruce, como las demás', () async {
        expect((await selected([ana])).$1, 201);

        final (status, body) = await selected([ana], {'promoPrice': 3});
        expect(status, 409);
        expect((body['overlaps'] as List).single['audience'], 'selected');
        expect(
          (await selected([ana], {'promoPrice': 3, 'confirmOverlap': true})).$1,
          201,
        );
        expect(
          (await create({'audience': 'vip', 'confirmOverlap': true})).$1,
          201,
        );
      });

      test(
        'PATCH cambia los elegidos o los deja; con otra audiencia, ninguno',
        () async {
          final (_, created) = await selected([ana]);
          final id = created['id'] as String;

          final (status, changed) = await patch(id, {
            'recipientIds': [luis.id.toString()],
          });
          expect(status, 200);
          expect(emailsOf(changed), ['luis@tienda.pe']);

          // Sin recipientIds, los mismos; aunque Luis ya no sea VIP (deja de
          // valerle solo), la promoción se sigue editando.
          await deactivate(luis);
          final (kept, same) = await patch(id, {'promoPrice': 3.1});
          expect(kept, 200);
          expect(emailsOf(same), ['luis@tienda.pe']);
          // Pero no se elige a uno que ya no es VIP.
          expect(
            (await patch(id, {
              'recipientIds': [beto.id.toString()],
            })).$1,
            400,
          );

          final (_, vipOnly) = await patch(id, {'audience': 'vip'});
          expect(vipOnly['audience'], 'vip');
          expect(vipOnly['recipients'], isEmpty);
          expect(await PromotionRecipient.db.count(session), 0);

          // De vuelta a clientes elegidos, hay que elegirlos.
          expect(
            (await patch(id, {'audience': 'selected'})).$2['message'],
            'Elige al menos un cliente VIP',
          );
        },
      );

      test(
        '/promotions/active: solo para los elegidos que siguen siendo VIP',
        () async {
          final (_, promotion) = await selected([ana]);
          for (final uid in ['uid-ana', 'uid-luis']) {
            await insertUser(session, uid);
          }

          Future<List<Object?>> audiences(
            String uid,
            String email, {
            bool emailVerified = true,
          }) async {
            final (_, body) = await client.get(
              '/promotions/active',
              as: uid,
              email: email,
              emailVerified: emailVerified,
            );
            return [for (final p in body['data'] as List) p['audience']];
          }

          // Con el correo en mayúsculas también es ella.
          expect(await audiences('uid-ana', 'Ana@Tienda.pe'), ['selected']);
          expect(
            jsonEncode((await client.get('/promotions/active')).$2),
            isNot(contains(promotion['id'] as String)),
          );
          expect(await audiences('uid-luis', 'luis@tienda.pe'), isEmpty);
          expect(
            await audiences(
              'uid-ana',
              'ana@tienda.pe',
              emailVerified: false,
            ),
            isEmpty,
          );
          await deactivate(ana);
          expect(await audiences('uid-ana', 'ana@tienda.pe'), isEmpty);
        },
      );

      test('al crearla, el aviso lleva a los elegidos', () async {
        await selected([ana, luis]);

        final announced = announcer.announced.single;
        expect(announced.audience, PromotionAudience.selected);
        expect(
          {for (final r in announced.recipients!) r.vipCustomer!.email},
          {'ana@tienda.pe', 'luis@tienda.pe'},
        );
      });
    });

    test(
      'crear una que ya rige la anuncia; programada o apagada, no',
      () async {
        final (_, vigente) = await create({'audience': 'vip'});
        await create({'startDate': day(10), 'endDate': day(12)});
        await create({
          'active': false,
          'audience': 'vip',
          'startDate': day(20),
          'endDate': day(22),
        });

        expect(announcer.announced, hasLength(1));
        final announced = announcer.announced.single;
        expect(announced.id.toString(), vigente['id']);
        expect(announced.audience, PromotionAudience.vip);
        // Con su producto, para armar el aviso.
        expect(announced.product?.name, 'Arroz Costeño 1 kg');
      },
    );

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
