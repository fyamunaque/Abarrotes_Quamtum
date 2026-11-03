import 'package:abarrotes_server/src/common/store_time.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/promo_codes/promo_codes_routes.dart';
import 'package:abarrotes_server/src/promo_codes/promo_codes_service.dart';
import 'package:abarrotes_server/src/promotions/promotions_routes.dart';
import 'package:serverpod/serverpod.dart' hide Order;
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/promotions_setup.dart';
import '../support/staff_setup.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  // testNow cae el 1 de octubre en Lima.
  final today = storeDay(testNow);
  String day(int offset) => addDays(today, offset);

  test('normalizePromoCode: sin espacios en los extremos y en mayúsculas', () {
    expect(normalizePromoCode('  verano-10 '), 'VERANO-10');
    expect(isValidPromoCode('VERANO-10'), isTrue);
    expect(isValidPromoCode('AB'), isFalse);
    expect(isValidPromoCode('VERANO 10'), isFalse);
    expect(isValidPromoCode('A' * 21), isFalse);
  });

  withServerpod('Rutas de códigos promocionales', (sessionBuilder, _) {
    late Session session;
    late TestClient client;
    late Product arroz;

    setUp(() async {
      session = sessionBuilder.build();
      final server = await serveRoutes(() => session, [
        ...promoCodesRoutes(
          PromoCodesService(now: () => testNow),
          testGuards(google),
          shoppers: testShoppers,
        ),
        ...promotionsRoutes(
          testPromotions(),
          testGuards(google),
          shoppers: testShoppers,
        ),
      ]);
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
        client.post('/promo-codes', {
          'code': 'VERANO-10',
          'startDate': day(0),
          'endDate': day(29),
          ...changes,
        }, as: 'uid-staff');

    /// Un 2x1 del arroz que da el código [codeId].
    Future<ApiResult> addPromotion(String codeId) =>
        client.post('/promotions', {
          'productId': arroz.id.toString(),
          'type': 'buyXPayY',
          'buyQuantity': 2,
          'payQuantity': 1,
          'startDate': day(0),
          'endDate': day(29),
          'audience': 'code',
          'promoCodeId': codeId,
        }, as: 'uid-staff');

    Future<PromoCodeRedemption> redeem(String codeId, String uid) async {
      final user = await insertUser(session, uid);
      return PromoCodeRedemption.db.insertRow(
        session,
        PromoCodeRedemption(
          promoCodeId: UuidValue.fromString(codeId),
          userId: user.id!,
          activatedAt: testNow,
          expiresAt: testNow.add(const Duration(days: 30)),
        ),
      );
    }

    test('crea un código con su texto y condiciones', () async {
      final (status, body) = await create({
        'code': ' verano-10 ',
        'benefitDays': 7,
        'maxRedemptions': 100,
        'usesPerCustomer': 2,
        'minPurchase': 30,
        'newCustomersOnly': true,
        'eligibility': 'listed',
        'allowedEmails': ['Ana@Tienda.pe', ' luis@tienda.pe'],
      });

      expect(status, 201);
      expect(body, {
        'id': isA<String>(),
        'code': 'VERANO-10',
        // Sin promociones todavía, se crea apagado.
        'active': false,
        'status': 'paused',
        'startDate': day(0),
        'endDate': day(29),
        'benefitDays': 7,
        'maxRedemptions': 100,
        'usesPerCustomer': 2,
        'minPurchase': '30',
        'newCustomersOnly': true,
        'eligibility': 'listed',
        'allowedEmails': ['ana@tienda.pe', 'luis@tienda.pe'],
        'promotions': <Object?>[],
        'redemptions': 0,
        'orders': 0,
      });
    });

    test('sin condiciones: todo opcional', () async {
      final (status, body) = await create({});

      expect(status, 201);
      expect(body['eligibility'], 'everyone');
      expect(body['newCustomersOnly'], isFalse);
      expect(
        [
          body['benefitDays'],
          body['maxRedemptions'],
          body['usesPerCustomer'],
          body['minPurchase'],
        ],
        [null, null, null, null],
      );
    });

    group('valida', () {
      for (final text in ['ab', 'VERANO 10', 'VERANO_10', 'A' * 21]) {
        test('el texto "$text"', () async {
          final (status, body) = await create({'code': text});
          expect(status, 400);
          expect(
            body['message'],
            'code debe tener de 3 a 20 letras, números o guiones',
          );
        });
      }

      test('un texto repetido, escrito de otra forma: 409', () async {
        await create({});
        final (status, body) = await create({'code': 'Verano-10'});
        expect(status, 409);
        expect(body['message'], 'Ya existe el código VERANO-10');
      });

      test('las fechas, los límites y la lista de correos', () async {
        expect(
          (await create({
            'startDate': day(5),
            'endDate': day(4),
          })).$2['message'],
          'endDate no puede ser anterior a startDate',
        );
        expect((await create({'maxRedemptions': 0})).$1, 400);
        expect((await create({'usesPerCustomer': 0})).$1, 400);
        expect((await create({'benefitDays': 0})).$1, 400);
        expect(
          (await create({'eligibility': 'listed'})).$2['message'],
          'Escribe al menos un correo',
        );
        expect(
          (await create({
            'eligibility': 'listed',
            'allowedEmails': ['no-es-un-correo'],
          })).$2['message'],
          'Algún correo no es válido: no-es-un-correo',
        );
        expect(
          (await create({
            'allowedEmails': ['ana@tienda.pe'],
          })).$2['message'],
          'allowedEmails solo va con eligibility listed',
        );
      });

      test('encender sin promociones', () async {
        final (status, body) = await create({'active': true});
        expect(status, 400);
        expect(
          body['message'],
          'Agrega al menos una promoción antes de encender el código',
        );
      });
    });

    test('las promociones del código', () async {
      final (_, code) = await create({});
      final id = code['id'] as String;

      final (status, promotion) = await addPromotion(id);
      expect(status, 201);
      expect(promotion['audience'], 'code');
      expect(promotion['promoCode'], {'id': id, 'code': 'VERANO-10'});

      final (_, withPromotion) = await client.get(
        '/promo-codes/$id',
        as: 'uid-staff',
      );
      expect(
        [
          for (final p in withPromotion['promotions'] as List)
            (p as Map)['label'],
        ],
        ['2x1'],
      );

      // Con una promoción ya se enciende.
      final (patched, on) = await client.patch('/promo-codes/$id', {
        'active': true,
      }, as: 'uid-staff');
      expect(patched, 200);
      expect(on['status'], 'active');
    });

    test(
      'promoCodeId solo con la audiencia code, y de un código que existe',
      () async {
        final (_, code) = await create({});
        final id = code['id'] as String;
        Future<ApiResult> promotion(Map<String, Object?> changes) =>
            client.post('/promotions', {
              'productId': arroz.id.toString(),
              'promoPrice': 3.9,
              'startDate': day(0),
              'endDate': day(6),
              ...changes,
            }, as: 'uid-staff');

        expect(
          (await promotion({'audience': 'code'})).$2['message'],
          'promoCodeId es obligatorio en una promoción de código',
        );
        expect(
          (await promotion({'promoCodeId': id})).$2['message'],
          'promoCodeId solo va en una promoción de código',
        );
        expect(
          (await promotion({
            'audience': 'code',
            'promoCodeId': '01900000-0000-7000-8000-000000000000',
          })).$2['message'],
          'El código indicado no existe',
        );
      },
    );

    test('estado y conteos', () async {
      final (_, verano) = await create({});
      final id = verano['id'] as String;
      await addPromotion(id);
      await client.patch('/promo-codes/$id', {'active': true}, as: 'uid-staff');
      await create({
        'code': 'VIEJO',
        'startDate': day(-30),
        'endDate': day(-1),
      });
      final ana = await redeem(id, 'uid-ana');
      await redeem(id, 'uid-luis');
      final order = await Order.db.insertRow(
        session,
        Order(
          customerId: ana.userId,
          status: OrderStatus.delivered,
          totalCents: 450,
          fulfillmentType: FulfillmentType.delivery,
          deliveryAddress: 'Av. Arequipa 123',
          number: 1001,
        ),
      );
      await OrderPromoCodeUse.db.insertRow(
        session,
        OrderPromoCodeUse(orderId: order.id!, redemptionId: ana.id!),
      );

      final (_, page) = await client.get('/promo-codes', as: 'uid-staff');
      final byCode = {
        for (final c in (page['data'] as List).cast<Map>()) c['code']: c,
      };
      expect(byCode['VERANO-10']!['status'], 'active');
      expect(
        (byCode['VERANO-10']!['redemptions'], byCode['VERANO-10']!['orders']),
        (2, 1),
      );
      expect(byCode['VIEJO']!['status'], 'paused');

      final (_, paused) = await client.get(
        '/promo-codes?status=paused',
        as: 'uid-staff',
      );
      expect(
        [for (final c in paused['data'] as List) (c as Map)['code']],
        [
          'VIEJO',
        ],
      );
      final (_, found) = await client.get(
        '/promo-codes?search=veran',
        as: 'uid-staff',
      );
      expect(
        [for (final c in found['data'] as List) (c as Map)['code']],
        [
          'VERANO-10',
        ],
      );
    });

    test('un código encendido y vencido: expired', () async {
      final (_, code) = await create({
        'code': 'OTONO',
        'startDate': day(-30),
        'endDate': day(-1),
      });
      final id = code['id'] as String;
      await PromoCode.db.updateRow(
        session,
        (await PromoCode.db.findById(
          session,
          UuidValue.fromString(id),
        ))!.copyWith(active: true),
      );

      final (_, body) = await client.get('/promo-codes/$id', as: 'uid-staff');
      expect(body['status'], 'expired');
    });

    test('con canjes, el texto no cambia y no se borra', () async {
      final (_, code) = await create({});
      final id = code['id'] as String;
      await addPromotion(id);
      await redeem(id, 'uid-ana');

      final (renamed, renameBody) = await client.patch('/promo-codes/$id', {
        'code': 'OTRO',
      }, as: 'uid-staff');
      expect(renamed, 409);
      expect(
        renameBody['message'],
        'El código ya se activó: no se puede cambiar el texto',
      );
      final (deleted, deleteBody) = await client.delete(
        '/promo-codes/$id',
        as: 'uid-staff',
      );
      expect(deleted, 409);
      expect(
        deleteBody['message'],
        'El código ya se activó: apágalo en vez de borrarlo',
      );
      // Lo demás sí cambia.
      final (patched, body) = await client.patch('/promo-codes/$id', {
        'maxRedemptions': 50,
      }, as: 'uid-staff');
      expect((patched, body['maxRedemptions']), (200, 50));
    });

    test('sin canjes, se borra con sus promociones', () async {
      final (_, code) = await create({});
      final id = code['id'] as String;
      await addPromotion(id);

      final (status, _) = await client.delete(
        '/promo-codes/$id',
        as: 'uid-staff',
      );

      expect(status, 204);
      expect(await PromoCode.db.count(session), 0);
      expect(await Promotion.db.count(session), 0);
    });

    test('un cliente no entra: 403', () async {
      final (status, _) = await client.get('/promo-codes', as: 'uid-cliente');
      expect(status, 403);
    });
  });
}
