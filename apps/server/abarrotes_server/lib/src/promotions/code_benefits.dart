import 'package:serverpod/serverpod.dart';

/// Un código que un cliente activó y todavía le sirve: su canje, el código
/// (para nombrar sus promociones, "Código VERANO-10: 2x1") y la compra
/// mínima, si tiene.
typedef CodeBenefit = ({
  UuidValue redemptionId,
  UuidValue promoCodeId,
  String code,
  int? minPurchaseCents,
});

/// Lo que las promociones necesitan de los códigos: los que tiene activos
/// un cliente. La implementa `promo_codes` (`DbCodeBenefits`) y llega a
/// `PromotionsService` por constructor, así promotions no sabe de canjes ni
/// de usos.
abstract interface class CodeBenefits {
  /// Los canjes de [customerId] con el código encendido, sin vencer y con
  /// usos. Con [lock] (al hacer un pedido, dentro de [transaction]),
  /// bloquea esas filas: dos pedidos a la vez no pasan los usos.
  Future<List<CodeBenefit>> activeFor(
    Session session,
    UuidValue customerId, {
    Transaction? transaction,
    bool lock = false,
  });
}

/// Sin códigos (p. ej. en los tests que no los usan).
class NoCodeBenefits implements CodeBenefits {
  const NoCodeBenefits();

  @override
  Future<List<CodeBenefit>> activeFor(
    Session session,
    UuidValue customerId, {
    Transaction? transaction,
    bool lock = false,
  }) async => const [];
}
