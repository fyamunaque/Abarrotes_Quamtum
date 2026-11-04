import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/promo_codes/promo_codes_service.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/promo_codes_setup.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Lo que devuelve [work]: su valor, o el mensaje de un [ApiException]. Un
/// error de la base (un 500) queda tal cual.
Future<Object?> _outcome(Future<Object?> Function() work) =>
    work().then<Object?>(
      (value) => value,
      onError: (Object e) => e is ApiException ? e.message : e,
    );

void main() {
  // Sin rollback: cada sesión usa su propia conexión, como dos peticiones
  // reales. La base temporal de cada grupo se borra al terminar.
  withServerpod(
    'Dos códigos iguales a la vez',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, _) {
      test('uno se crea y el otro da el 409 de siempre', () async {
        final codes = PromoCodesService(now: () => testNow);
        Future<Object?> create() => _outcome(
          () => codes
              .create(sessionBuilder.build(), (
                code: 'VERANO-10',
                active: false,
                startDate: testDay(0),
                endDate: testDay(29),
                benefitDays: null,
                maxRedemptions: null,
                usesPerCustomer: null,
                minPurchaseCents: null,
                newCustomersOnly: false,
                eligibility: PromoCodeEligibility.everyone,
                allowedEmails: const [],
              ))
              .then((summary) => summary.code.code),
        );

        final results = await Future.wait([create(), create()]);

        expect(
          results,
          unorderedEquals(['VERANO-10', 'Ya existe el código VERANO-10']),
        );
      });
    },
  );

  withServerpod(
    'Borrar un código mientras alguien lo activa',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, _) {
      test('nunca un error de la base: o se borra o se activa', () async {
        final session = sessionBuilder.build();
        final arroz = await insertRice(session);
        final verano = await insertCode(session, arroz);
        final ana = await insertUser(session, 'uid-ana');
        final codes = PromoCodesService(now: () => testNow);

        final results = await Future.wait([
          _outcome(
            () => codes
                .delete(sessionBuilder.build(), verano.id!)
                .then((_) => 'borrado'),
          ),
          _outcome(
            () => codes
                .redeem(
                  sessionBuilder.build(),
                  customer: ana,
                  isVip: false,
                  code: 'VERANO-10',
                )
                .then((_) => 'activado'),
          ),
        ]);

        expect(
          results,
          anyOf(
            unorderedEquals([
              'borrado',
              'El código no existe o ya no está vigente',
            ]),
            unorderedEquals([
              'El código ya se activó: apágalo en vez de borrarlo',
              'activado',
            ]),
          ),
        );
      });
    },
  );
}
