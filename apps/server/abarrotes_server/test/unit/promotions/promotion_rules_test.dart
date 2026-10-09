import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/promotions/promotion_rules.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  // Del 1 al 7 de octubre, ambos incluidos (días de Lima).
  final period = toStoredPeriod('2026-10-01', '2026-10-07');

  Promotion promotion({bool active = true}) => Promotion(
    productId: UuidValue.fromString('0199a000-0000-7000-8000-000000000001'),
    promoPriceCents: 390,
    startDate: period.startDate,
    endDate: period.endDate,
    active: active,
  );

  test(
    'guarda el periodo como [00:00 del primer día, 00:00 del día siguiente al último)',
    () {
      expect(period.startDate, DateTime.utc(2026, 10, 1, 5));
      expect(period.endDate, DateTime.utc(2026, 10, 8, 5));
      expect(toDayPeriod(period.startDate, period.endDate), (
        startDate: '2026-10-01',
        endDate: '2026-10-07',
      ));
    },
  );

  test('el estado depende de la fecha y del interruptor', () {
    PromotionStatus at(DateTime now, {bool active = true}) =>
        promotionStatus(promotion(active: active), now);

    expect(at(DateTime.utc(2026, 10, 1, 4, 59)), PromotionStatus.scheduled);
    expect(at(DateTime.utc(2026, 10, 1, 5)), PromotionStatus.active);
    // 23:59 del último día en Lima.
    expect(at(DateTime.utc(2026, 10, 8, 4, 59)), PromotionStatus.active);
    expect(at(DateTime.utc(2026, 10, 8, 5)), PromotionStatus.expired);
    expect(
      at(DateTime.utc(2026, 10, 3), active: false),
      PromotionStatus.disabled,
    );
  });
}
