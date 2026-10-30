import 'package:serverpod/serverpod.dart';

import '../../common/shopper.dart';
import '../../generated/protocol.dart';

/// Decide quién puede usar las promociones de una [audience]. Para sumar un
/// segmento (p. ej. mayoristas): un valor nuevo en `PromotionAudience`, una
/// regla nueva y pasarla a `PromotionsService` en `server.dart`.
abstract interface class PromotionAudienceRule {
  PromotionAudience get audience;

  bool isEligible(Shopper shopper);
}

/// Una regla que, además de decidir quién usa su audiencia, elige entre sus
/// promociones las de cada cliente (p. ej. las de clientes elegidos, por sus
/// destinatarios).
abstract interface class PromotionRecipientsRule
    implements PromotionAudienceRule {
  /// Entre las promociones de [audience], las que valen para [shopper] (uno
  /// que cumple [isEligible]).
  Expression recipientsWhere(PromotionTable promotion, Shopper shopper);
}
