import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('El modelo de los códigos promocionales', (sessionBuilder, _) {
    late Session session;

    Future<PromoCode> code(String text) => PromoCode.db.insertRow(
      session,
      PromoCode(
        code: text,
        startDate: DateTime.utc(2026, 11, 1, 5),
        endDate: DateTime.utc(2026, 12, 1, 5),
      ),
    );

    setUp(() => session = sessionBuilder.build());

    test('el texto del código es único', () async {
      await code('VERANO-10');
      expect(
        () => code('VERANO-10'),
        throwsA(isA<DatabaseUniqueViolationException>()),
      );
    });

    test('un canje por cliente y código', () async {
      final verano = await code('VERANO-10');
      final ana = await insertUser(session, 'uid-ana');
      Future<PromoCodeRedemption> redeem() => PromoCodeRedemption.db.insertRow(
        session,
        PromoCodeRedemption(
          promoCodeId: verano.id!,
          userId: ana.id!,
          activatedAt: DateTime.utc(2026, 11, 2, 15),
          expiresAt: DateTime.utc(2026, 12, 1, 5),
        ),
      );

      await redeem();
      expect(redeem, throwsA(isA<DatabaseUniqueViolationException>()));
    });

    test('los correos de la lista, uno por código', () async {
      final verano = await code('VERANO-10');
      Future<PromoCodeAllowedEmail> allow() =>
          PromoCodeAllowedEmail.db.insertRow(
            session,
            PromoCodeAllowedEmail(
              promoCodeId: verano.id!,
              email: 'ana@tienda.pe',
            ),
          );

      await allow();
      expect(allow, throwsA(isA<DatabaseUniqueViolationException>()));
    });

    test('las condiciones van por defecto apagadas', () async {
      final verano = await code('VERANO-10');

      expect(verano.active, isTrue);
      expect(verano.newCustomersOnly, isFalse);
      expect(verano.eligibility, PromoCodeEligibility.everyone);
      expect(
        (
          verano.benefitDays,
          verano.maxRedemptions,
          verano.usesPerCustomer,
          verano.minPurchaseCents,
        ),
        (null, null, null, null),
      );
    });
  });
}
