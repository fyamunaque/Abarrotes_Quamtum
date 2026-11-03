import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../promotions/code_benefits.dart';
import 'promo_codes_service.dart';

/// [CodeBenefits] con los canjes guardados: los del cliente con el código
/// encendido, sin vencer y con usos (los pedidos no cancelados que los
/// usaron, menos que `usesPerCustomer`).
class DbCodeBenefits implements CodeBenefits {
  DbCodeBenefits({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  Future<List<CodeBenefit>> activeFor(
    Session session,
    UuidValue customerId, {
    Transaction? transaction,
    bool lock = false,
  }) async {
    final now = _now().toUtc();
    final redemptions = await PromoCodeRedemption.db.find(
      session,
      where: (redemption) =>
          redemption.userId.equals(customerId) &
          redemption.promoCode.active.equals(true) &
          (redemption.expiresAt > now),
      orderBy: (redemption) => redemption.id,
      include: PromoCodeRedemption.include(promoCode: PromoCode.include()),
      transaction: transaction,
    );
    if (redemptions.isEmpty) return const [];
    if (lock) {
      // Se bloquean por id, en orden, y recién después se cuentan los usos:
      // el otro pedido que los usaba ya terminó.
      await PromoCodeRedemption.db.find(
        session,
        where: (redemption) => redemption.id.inSet(<UuidValue>{
          for (final redemption in redemptions) redemption.id!,
        }),
        orderBy: (redemption) => redemption.id,
        lockMode: LockMode.forUpdate,
        transaction: transaction,
      );
    }
    return [
      for (final redemption in redemptions)
        if (await _hasUses(session, redemption, transaction))
          (
            redemptionId: redemption.id!,
            promoCodeId: redemption.promoCodeId,
            code: redemption.promoCode!.code,
            minPurchaseCents: redemption.promoCode!.minPurchaseCents,
          ),
    ];
  }

  Future<bool> _hasUses(
    Session session,
    PromoCodeRedemption redemption,
    Transaction? transaction,
  ) async {
    final limit = redemption.promoCode!.usesPerCustomer;
    if (limit == null) return true;
    return await PromoCodesService.usesOf(
          session,
          redemption.id!,
          transaction: transaction,
        ) <
        limit;
  }
}
