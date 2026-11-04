import 'package:serverpod/serverpod.dart';

import '../../common/emails.dart';
import '../../common/shopper.dart';
import '../../generated/protocol.dart';
import 'promotion_audience_rule.dart';

/// Las promociones para clientes elegidos: solo para los VIP (activos y con el
/// correo verificado: eso lo decide el `ShopperResolver`) que están entre sus
/// destinatarios. Si uno deja de ser VIP, deja de valerle.
class SelectedAudienceRule implements PromotionRecipientsRule {
  const SelectedAudienceRule();

  @override
  PromotionAudience get audience => PromotionAudience.selected;

  @override
  bool isEligible(Shopper shopper) => shopper.isVip && shopper.email != null;

  @override
  Expression recipientsWhere(PromotionTable promotion, Shopper shopper) {
    final email = normalizeEmail(shopper.email!);
    return promotion.recipients.any(
      (recipient) => recipient.vipCustomer.email.equals(email),
    );
  }
}
