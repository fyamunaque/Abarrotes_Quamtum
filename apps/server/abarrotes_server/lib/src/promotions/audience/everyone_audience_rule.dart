import '../../common/shopper.dart';
import '../../generated/protocol.dart';
import 'promotion_audience_rule.dart';

/// Las promociones para todos: también para los visitantes sin cuenta.
class EveryoneAudienceRule implements PromotionAudienceRule {
  const EveryoneAudienceRule();

  @override
  PromotionAudience get audience => PromotionAudience.everyone;

  @override
  bool isEligible(Shopper shopper) => true;
}
