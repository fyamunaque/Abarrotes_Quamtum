import '../../common/shopper.dart';
import '../../generated/protocol.dart';

/// Decide quién puede usar las promociones de una [audience]. Para sumar un
/// segmento (p. ej. mayoristas): un valor nuevo en `PromotionAudience`, una
/// regla nueva y pasarla a `PromotionsService` en `server.dart`.
abstract interface class PromotionAudienceRule {
  PromotionAudience get audience;

  bool isEligible(Shopper shopper);
}
