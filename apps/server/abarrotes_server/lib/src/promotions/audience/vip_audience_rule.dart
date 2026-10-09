import '../../common/shopper.dart';
import '../../generated/protocol.dart';
import 'promotion_audience_rule.dart';

/// Las promociones VIP: solo para clientes VIP con el correo verificado (eso
/// lo decide el `ShopperResolver`).
class VipAudienceRule implements PromotionAudienceRule {
  const VipAudienceRule();

  @override
  PromotionAudience get audience => PromotionAudience.vip;

  @override
  bool isEligible(Shopper shopper) => shopper.isVip;
}
