import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:abarrotes_server/src/common/store_time.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/promo_codes/promo_codes_routes.dart';
import 'package:abarrotes_server/src/promo_codes/promo_codes_service.dart';
import 'package:serverpod/serverpod.dart' hide Order;
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/promo_codes_setup.dart';
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

  withServerpod('Activar un código', (sessionBuilder, _) {
    late Session session;
    late TestClient client;
    late Product arroz;

    setUp(() async {
      session = sessionBuilder.build();
      final server = await serveRoutes(
        () => session,
        promoCodesRoutes(
          PromoCodesService(now: () => testNow),
          testGuards(google),
          shoppers: testShoppers,
        ),
      );
      client = TestClient(server, google);
      addTearDown(server.close);
      await insertUser(session, 'uid-ana');
      arroz = await insertRice(session);
    });

    Future<ApiResult> redeem(
      String code, {
      String as = 'uid-ana',
      bool emailVerified = true,
    }) => client.post(
      '/promo-codes/redeem',
      {'code': code},
      as: as,
      emailVerified: emailVerified,
    );

    test('se activa escrito como sea: con su beneficio y sus usos', () async {
      await insertCode(session, arroz, usesPerCustomer: 2);

      final (status, body) = await redeem(' verano-10 ');

      expect(status, 200);
      expect(body, {
        'code': 'VERANO-10',
        // Sin benefitDays, hasta el último día del código.
        'expiresAt': storeDayStart(day(30)).toIso8601String(),
        'usesLeft': 2,
        'minPurchase': null,
        'promotions': [
          {
            'label': '2x1',
            'product': {
              'id': arroz.id.toString(),
              'name': 'Arroz Costeño 1 kg',
            },
          },
        ],
      });
    });

    test('lista solo las promociones del código que valen hoy', () async {
      final verano = await insertCode(session, arroz);
      Future<void> extra({
        bool active = true,
        int start = 0,
        int percent = 20,
      }) => Promotion.db.insertRow(
        session,
        Promotion(
          productId: arroz.id!,
          type: PromotionType.percentOff,
          percent: percent,
          active: active,
          startDate: storeDayStart(day(start)),
          endDate: storeDayStart(day(30)),
          audience: PromotionAudience.code,
          promoCodeId: verano.id,
        ),
      );
      await extra(active: false, percent: 10);
      await extra(start: 5, percent: 15);

      final (_, body) = await redeem('VERANO-10');

      // La apagada y la que todavía no empieza no salen.
      expect(
        [for (final p in body['promotions'] as List) (p as Map)['label']],
        [
          '2x1',
        ],
      );
    });

    test('inexistente, apagado o fuera de fechas: el mismo 404', () async {
      await insertCode(session, arroz, code: 'APAGADO', active: false);
      await insertCode(session, arroz, code: 'FUTURO', startOffset: 1);
      await insertCode(
        session,
        arroz,
        code: 'VENCIDO',
        startOffset: -10,
        endOffset: -1,
      );

      for (final code in ['NO-EXISTE', 'APAGADO', 'FUTURO', 'VENCIDO']) {
        final (status, body) = await redeem(code);
        expect(
          (status, body['message']),
          (
            404,
            'El código no existe o ya no está vigente',
          ),
          reason: code,
        );
      }
    });

    test('se acabaron los canjes', () async {
      await insertCode(session, arroz, maxRedemptions: 1);
      await insertUser(session, 'uid-luis');

      expect((await redeem('VERANO-10')).$1, 200);
      final (status, body) = await redeem('VERANO-10', as: 'uid-luis');
      expect(
        (status, body['message']),
        (
          409,
          'Se acabaron los canjes de este código',
        ),
      );
    });

    test('solo para clientes nuevos', () async {
      await insertCode(session, arroz, newCustomersOnly: true);
      final ana = await User.db.findFirstRow(
        session,
        where: (user) => user.firebaseUid.equals('uid-ana'),
      );
      final luis = await insertUser(session, 'uid-luis');
      Future<void> order(User customer, OrderStatus status) =>
          Order.db.insertRow(
            session,
            Order(
              customerId: customer.id!,
              status: status,
              totalCents: 450,
              deliveryAddress: 'Av. Arequipa 123',
            ),
          );
      await order(ana!, OrderStatus.delivered);
      // Con solo pedidos cancelados, sigue siendo nuevo.
      await order(luis, OrderStatus.cancelled);

      final (status, body) = await redeem('VERANO-10');
      expect(
        (status, body['message']),
        (
          403,
          'Este código es solo para clientes nuevos',
        ),
      );
      expect((await redeem('VERANO-10', as: 'uid-luis')).$1, 200);
    });

    test('solo para clientes VIP', () async {
      await insertCode(session, arroz, eligibility: PromoCodeEligibility.vip);
      final staff = await insertStaff(session, 'uid-staff');
      await insertUser(session, 'uid-vip');
      await insertVips(session, staff, ['uid-vip@tienda.pe']);

      final (status, body) = await redeem('VERANO-10');
      expect(
        (status, body['message']),
        (
          403,
          'Este código es solo para clientes VIP',
        ),
      );
      expect((await redeem('VERANO-10', as: 'uid-vip')).$1, 200);
    });

    test('con lista de correos, solo los de la lista', () async {
      await insertCode(
        session,
        arroz,
        eligibility: PromoCodeEligibility.listed,
        allowedEmails: ['uid-luis@tienda.pe'],
      );
      await insertUser(session, 'uid-luis');

      final (status, body) = await redeem('VERANO-10');
      expect(
        (status, body['message']),
        (
          403,
          'Este código no está disponible para tu cuenta',
        ),
      );
      expect((await redeem('VERANO-10', as: 'uid-luis')).$1, 200);
    });

    test('dos veces: ya lo activaste', () async {
      await insertCode(session, arroz);

      await redeem('VERANO-10');
      final (status, body) = await redeem('verano-10');
      expect((status, body['message']), (409, 'Ya activaste este código'));
    });

    test('sin el correo verificado: 403', () async {
      await insertCode(session, arroz);

      final (status, body) = await redeem('VERANO-10', emailVerified: false);
      expect(status, 403);
      expect(
        body['message'],
        'Confirma tu correo para activar códigos: te enviamos un enlace.',
      );
      expect(await PromoCodeRedemption.db.count(session), 0);
    });

    test('sin cuenta: 401', () async {
      final (status, _) = await client.post('/promo-codes/redeem', {
        'code': 'VERANO-10',
      });
      expect(status, 401);
    });

    test('benefitDays: desde que se activa, y nunca después del fin', () async {
      await insertCode(session, arroz, benefitDays: 7);
      await insertCode(
        session,
        arroz,
        code: 'CORTO',
        benefitDays: 7,
        endOffset: 2,
      );

      final (_, week) = await redeem('VERANO-10');
      expect(
        week['expiresAt'],
        testNow.add(const Duration(days: 7)).toIso8601String(),
      );
      final (_, short) = await redeem('CORTO');
      expect(short['expiresAt'], storeDayStart(day(3)).toIso8601String());
    });

    test('mine: los vigentes, con los usos que quedan', () async {
      final verano = await insertCode(session, arroz, usesPerCustomer: 3);
      final apagado = await insertCode(session, arroz, code: 'APAGADO');
      await insertCode(session, arroz, code: 'SEMANA', benefitDays: 7);
      await redeem('VERANO-10');
      await redeem('APAGADO');
      await redeem('SEMANA');
      await PromoCode.db.updateRow(session, apagado.copyWith(active: false));
      // SEMANA ya venció: se activó hace 8 días.
      await PromoCodeRedemption.db.updateWhere(
        session,
        columnValues: (redemption) => [
          redemption.activatedAt(testNow.subtract(const Duration(days: 8))),
        ],
        where: (redemption) =>
            redemption.promoCodeId.notInSet({verano.id!, apagado.id!}),
      );

      final (status, body) = await client.get(
        '/promo-codes/mine',
        as: 'uid-ana',
      );

      expect(status, 200);
      expect(
        [for (final r in body as List) (r as Map)['code']],
        [
          'VERANO-10',
        ],
      );
      expect((body.single as Map)['usesLeft'], 3);
    });
  });

  // Sin rollback: cada sesión usa su propia conexión, como dos peticiones
  // reales. La base temporal del grupo se borra al terminar.
  withServerpod(
    'Activaciones simultáneas',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, _) {
      test('dos activaciones a la vez no pasan el límite', () async {
        final session = sessionBuilder.build();
        final arroz = await insertRice(session);
        await insertCode(session, arroz, maxRedemptions: 1);
        final ana = await insertUser(session, 'uid-ana');
        final luis = await insertUser(session, 'uid-luis');
        final codes = PromoCodesService(now: () => testNow);

        Future<Object> redeem(User customer) => codes
            .redeem(
              sessionBuilder.build(),
              customer: customer,
              isVip: false,
              code: 'VERANO-10',
            )
            .then<Object>(
              (redemption) => 'activado',
              onError: (Object e) => e is ApiException ? e.message : e,
            );

        final results = await Future.wait([redeem(ana), redeem(luis)]);

        expect(
          results,
          unorderedEquals([
            'activado',
            'Se acabaron los canjes de este código',
          ]),
        );
        expect(await PromoCodeRedemption.db.count(session), 1);
      });
    },
  );
}
