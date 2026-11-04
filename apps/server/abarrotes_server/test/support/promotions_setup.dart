import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/promotions/audience/everyone_audience_rule.dart';
import 'package:abarrotes_server/src/promotions/audience/selected_audience_rule.dart';
import 'package:abarrotes_server/src/promotions/audience/vip_audience_rule.dart';
import 'package:abarrotes_server/src/promotions/code_benefits.dart';
import 'package:abarrotes_server/src/promotions/promotion_announcer.dart';
import 'package:abarrotes_server/src/promotions/promotions_service.dart';
import 'package:abarrotes_server/src/vip/vip_service.dart';
import 'package:abarrotes_server/src/vip/vip_shopper_resolver.dart';
import 'package:serverpod/serverpod.dart';

import 'test_tokens.dart';

/// Las promociones como en `server.dart` (para todos, VIP y clientes
/// elegidos), con el reloj de los tests y, si se pasan, quién avisa de las
/// que empiezan a regir y los códigos activados de cada cliente.
PromotionsService testPromotions({
  PromotionAnnouncer announcer = const NoPromotionAnnouncer(),
  CodeBenefits codeBenefits = const NoCodeBenefits(),
}) => PromotionsService(
  audienceRules: const [
    EveryoneAudienceRule(),
    VipAudienceRule(),
    SelectedAudienceRule(),
  ],
  announcer: announcer,
  codeBenefits: codeBenefits,
  now: () => testNow,
);

/// Quién es VIP, como en `server.dart`.
const testShoppers = VipShopperResolver(VipService());

/// Da de alta [emails] como clientes VIP activos, agregados por [by].
Future<void> insertVips(Session session, User by, List<String> emails) =>
    VipCustomer.db.insert(session, [
      for (final email in emails)
        VipCustomer(email: email, addedByUserId: by.id!),
    ]);
