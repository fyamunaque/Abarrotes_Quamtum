import 'package:abarrotes_server/src/dev/dev_seed.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/promotions/promotion_rules.dart';
import 'package:test/test.dart';

import '../support/test_tokens.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Seed de desarrollo', (sessionBuilder, _) {
    test('carga categorías y productos, con una promoción vigente y uno '
        'agotado', () async {
      final session = sessionBuilder.build();

      final created = await seedDevData(session, now: () => testNow);

      expect(created, 12);
      expect(await Category.db.count(session), 5);
      expect(await Product.db.count(session), 12);
      expect(
        await Product.db.count(
          session,
          where: (product) => product.currentStock.equals(0),
        ),
        1,
      );
      final promotions = await Promotion.db.find(
        session,
        where: (promotion) => activePromotionWhere(promotion, testNow),
      );
      expect(promotions, hasLength(1));
      expect(promotions.single.promoPriceCents, 890);
    });

    test('correrlo de nuevo no duplica nada', () async {
      final session = sessionBuilder.build();
      await seedDevData(session, now: () => testNow);

      expect(await seedDevData(session, now: () => testNow), 0);
      expect(await Product.db.count(session), 12);
      expect(await Category.db.count(session), 5);
    });
  });
}
