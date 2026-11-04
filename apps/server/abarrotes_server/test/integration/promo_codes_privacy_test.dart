import 'package:abarrotes_server/src/products/products_routes.dart';
import 'package:abarrotes_server/src/products/products_service.dart';
import 'package:abarrotes_server/src/promo_codes/db_code_benefits.dart';
import 'package:abarrotes_server/src/promo_codes/promo_codes_service.dart';
import 'package:abarrotes_server/src/promotions/promotions_routes.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import '../support/http_harness.dart';
import '../support/promo_codes_setup.dart';
import '../support/promotions_setup.dart';
import '../support/staff_setup.dart';
import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Las promociones de un código valen solo en el cobro de quien lo activó:
/// no salen en el catálogo ni en las ofertas, para nadie. Hoy lo asegura
/// que la audiencia `code` no tiene regla; este test lo fija.
void main() {
  late RsaKeyPair google;

  setUpAll(() => google = generateRsaKeyPair());

  withServerpod('Las promociones de un código no se ven', (sessionBuilder, _) {
    late Session session;
    late TestClient client;

    setUp(() async {
      session = sessionBuilder.build();
      final promotions = testPromotions(
        codeBenefits: DbCodeBenefits(now: () => testNow),
      );
      final server = await serveRoutes(() => session, [
        ...productsRoutes(
          ProductsService(pricing: promotions, now: () => testNow),
          testGuards(google),
          shoppers: testShoppers,
        ),
        ...promotionsRoutes(
          promotions,
          testGuards(google),
          shoppers: testShoppers,
        ),
      ]);
      client = TestClient(server, google);
      addTearDown(server.close);
      final arroz = await insertRice(session, stock: 10);
      await insertCode(session, arroz);
      final ana = await insertUser(session, 'uid-ana');
      await PromoCodesService(
        now: () => testNow,
      ).redeem(session, customer: ana, isVip: false, code: 'VERANO-10');
    });

    test(
      'ni en el catálogo ni en las ofertas, tampoco para quien lo activó',
      () async {
        for (final viewer in [null, 'uid-ana']) {
          final (_, products) = await client.get('/products', as: viewer);
          final arroz = (products['data'] as List).single as Map;
          expect(arroz['promotions'], isEmpty, reason: '$viewer');
          expect(arroz['unitPrice'], '4.5', reason: '$viewer');

          final (_, offers) = await client.get(
            '/promotions/active?types=all',
            as: viewer,
          );
          expect(offers['data'], isEmpty, reason: '$viewer');
        }
      },
    );
  });
}
