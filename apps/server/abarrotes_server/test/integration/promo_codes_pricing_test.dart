import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:abarrotes_server/src/common/money.dart';
import 'package:abarrotes_server/src/common/shopper.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/orders/orders_service.dart';
import 'package:abarrotes_server/src/promo_codes/db_code_benefits.dart';
import 'package:abarrotes_server/src/promo_codes/promo_codes_service.dart';
import 'package:abarrotes_server/src/promotions/promotions_service.dart';
import 'package:serverpod/serverpod.dart' hide Order;
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/promo_codes_setup.dart';
import '../support/promotions_setup.dart';
import '../support/staff_setup.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Las promociones con los códigos activados, con el reloj de los tests (o
/// [now]).
PromotionsService _pricing({DateTime Function()? now}) =>
    testPromotions(codeBenefits: DbCodeBenefits(now: now ?? () => testNow));

Shopper _shopper(User user) => Shopper(email: user.email, emailVerified: true);

void main() {
  withServerpod('El cobro con códigos', (sessionBuilder, _) {
    late Session session;
    late Product arroz;
    late User staff;
    late User ana;
    late User luis;
    late PromoCodesService codes;

    setUp(() async {
      session = sessionBuilder.build();
      arroz = await insertRice(session, stock: 100);
      staff = await insertStaff(session, 'uid-staff');
      ana = await insertUser(session, 'uid-ana');
      luis = await insertUser(session, 'uid-luis');
      codes = PromoCodesService(now: () => testNow);
    });

    Future<RedeemedCode> redeem(User customer, [String code = 'VERANO-10']) =>
        codes.redeem(session, customer: customer, isVip: false, code: code);

    Future<PricedQuote> quote(
      User customer,
      int quantity, {
      PromotionsService? pricing,
    }) async {
      final (:cart, products: _) =
          await OrdersService(
            pricing: pricing ?? _pricing(),
            now: () => testNow,
          ).quote(
            session,
            shopper: _shopper(customer),
            customerId: customer.id,
            lines: [(productId: arroz.id!, quantity: quantity)],
          );
      return (
        total: cart.totalCents,
        labels: [
          for (final line in cart.lines)
            for (final promotion in line.promotions) promotion.label,
        ],
        notices: cart.notices,
      );
    }

    Future<Order> order(User customer, int quantity) async {
      final placed =
          await OrdersService(
            pricing: _pricing(),
            now: () => testNow,
          ).create(
            session,
            customer: customer,
            shopper: _shopper(customer),
            fulfillmentType: FulfillmentType.delivery,
            deliveryAddress: 'Av. Arequipa 123',
            lines: [
              (
                productId: arroz.id!,
                quantity: quantity,
                shownUnitPriceCents: null,
                shownLineTotalCents: null,
              ),
            ],
          );
      return placed.order;
    }

    test(
      'quien lo activó paga con el 2x1 del código; otro cliente no',
      () async {
        await insertCode(session, arroz);
        await redeem(ana);

        final mine = await quote(ana, 2);
        expect(mine.total, 450);
        expect(mine.labels, ['Código VERANO-10: 2x1']);
        expect((await quote(luis, 2)).total, 900);

        final placed = await order(ana, 2);
        expect(placed.totalCents, 450);
        expect(await OrderPromoCodeUse.db.count(session), 1);
        // Otro cliente pide sin el código.
        expect((await order(luis, 2)).totalCents, 900);
        expect(await OrderPromoCodeUse.db.count(session), 1);
      },
    );

    test('un pedido gasta un uso y cancelarlo lo devuelve', () async {
      await insertCode(session, arroz, usesPerCustomer: 1);
      await redeem(ana);

      final placed = await order(ana, 2);
      expect(await codes.mine(session, ana), isEmpty);
      // Sin usos, ya no se aplica.
      expect((await quote(ana, 2)).total, 900);

      await OrdersService(
        pricing: _pricing(),
        now: () => testNow,
      ).changeStatus(session, placed.id!, OrderStatus.cancelled, by: staff);
      final back = await codes.mine(session, ana);
      expect(back.single.usesLeft, 1);
      expect((await quote(ana, 2)).total, 450);
    });

    test('un pedido que no usa sus promociones no gasta el uso', () async {
      await insertCode(session, arroz, usesPerCustomer: 1);
      await redeem(ana);

      // Una sola unidad: el 2x1 no se completa.
      await order(ana, 1);

      expect(await OrderPromoCodeUse.db.count(session), 0);
      expect((await codes.mine(session, ana)).single.usesLeft, 1);
    });

    test('la cotización no gasta usos', () async {
      await insertCode(session, arroz, usesPerCustomer: 1);
      await redeem(ana);

      await quote(ana, 2);
      await quote(ana, 2);

      expect(await OrderPromoCodeUse.db.count(session), 0);
      expect((await codes.mine(session, ana)).single.usesLeft, 1);
    });

    test('la compra mínima: sin llegar, el aviso con cuánto falta', () async {
      await insertCode(session, arroz, minPurchaseCents: 2000);
      await redeem(ana);

      // 2 arroces: S/ 9.00 sin el código.
      final short = await quote(ana, 2);
      expect(short.total, 900);
      expect(short.notices, [
        'Con ${formatSoles(1100)} más se aplica tu código VERANO-10',
      ]);
      // 6 arroces: S/ 27.00; el 2x1 se aplica tres veces.
      final enough = await quote(ana, 6);
      expect(enough.total, 1350);
      expect(enough.notices, isEmpty);
    });

    test('vencido por benefitDays, ya no aplica', () async {
      await insertCode(session, arroz, benefitDays: 1);
      await redeem(ana);

      expect((await quote(ana, 2)).total, 450);
      final later = _pricing(
        now: () => testNow.add(const Duration(days: 2)),
      );
      expect((await quote(ana, 2, pricing: later)).total, 900);
    });

    test(
      'pausar el código corta el beneficio; bajar el límite no rompe nada',
      () async {
        final verano = await insertCode(session, arroz, maxRedemptions: 5);
        await redeem(ana);
        await redeem(luis);
        PromoCodeInput Function(PromoCodeInput) set({
          bool? active,
          int? maxRedemptions,
        }) =>
            (current) => (
              code: current.code,
              active: active ?? current.active,
              startDate: current.startDate,
              endDate: current.endDate,
              benefitDays: current.benefitDays,
              maxRedemptions: maxRedemptions ?? current.maxRedemptions,
              usesPerCustomer: current.usesPerCustomer,
              minPurchaseCents: current.minPurchaseCents,
              newCustomersOnly: current.newCustomersOnly,
              eligibility: current.eligibility,
              allowedEmails: current.allowedEmails,
            );

        await codes.update(session, verano.id!, set(active: false));
        expect((await quote(ana, 2)).total, 900);
        await codes.update(session, verano.id!, set(active: true));
        expect((await quote(ana, 2)).total, 450);

        // Por debajo de los canjes que ya hay: los de antes siguen.
        final lowered = await codes.update(
          session,
          verano.id!,
          set(maxRedemptions: 1),
        );
        expect(lowered.code.maxRedemptions, 1);
        expect((await quote(luis, 2)).total, 450);
        final rosa = await insertUser(session, 'uid-rosa');
        await expectLater(
          redeem(rosa),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'Se acabaron los canjes de este código',
            ),
          ),
        );
      },
    );
  });

  // Sin rollback: cada sesión usa su propia conexión, como dos peticiones
  // reales. La base temporal del grupo se borra al terminar.
  withServerpod(
    'Pedidos simultáneos con un código',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, _) {
      test('dos pedidos a la vez no pasan usesPerCustomer', () async {
        final session = sessionBuilder.build();
        final arroz = await insertRice(session, stock: 100);
        await insertCode(session, arroz, usesPerCustomer: 1);
        final ana = await insertUser(session, 'uid-ana');
        await PromoCodesService(
          now: () => testNow,
        ).redeem(session, customer: ana, isVip: false, code: 'VERANO-10');

        Future<int> place() =>
            OrdersService(pricing: _pricing(), now: () => testNow)
                .create(
                  sessionBuilder.build(),
                  customer: ana,
                  shopper: _shopper(ana),
                  fulfillmentType: FulfillmentType.delivery,
                  deliveryAddress: 'Av. Arequipa 123',
                  lines: [
                    (
                      productId: arroz.id!,
                      quantity: 2,
                      shownUnitPriceCents: null,
                      shownLineTotalCents: null,
                    ),
                  ],
                )
                .then((placed) => placed.order.totalCents);

        final totals = await Future.wait([place(), place()]);

        // Uno con el 2x1 y otro sin él.
        expect(totals, unorderedEquals([450, 900]));
        expect(await OrderPromoCodeUse.db.count(session), 1);
      });
    },
  );
}

typedef PricedQuote = ({int total, List<String> labels, List<String> notices});
