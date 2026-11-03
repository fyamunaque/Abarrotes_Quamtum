import 'package:serverpod/serverpod.dart';

import '../common/shopper.dart';
import '../generated/protocol.dart';
import 'promotion_engine.dart';

/// Lo que products y orders necesitan de las promociones: cuáles puede usar
/// un cliente y cómo se cobra un carrito. La implementa `PromotionsService`;
/// ellos la reciben por constructor y no saben de audiencias ni de tipos.
abstract interface class PromotionPricing {
  /// Las promociones vigentes en [now] que [shopper] puede usar.
  Expression eligibleWhere(
    PromotionTable promotion,
    DateTime now,
    Shopper shopper,
  );

  /// Para el `include` de un producto: todas las que [shopper] puede usar,
  /// con su producto de regalo.
  PromotionIncludeList eligibleFor(DateTime now, Shopper shopper);

  /// Los productos que se pueden regalar con las promociones de
  /// [productIds] que [shopper] puede usar, también las de los códigos que
  /// activó [customerId] (para bloquearlos junto con los comprados, en
  /// orden, antes de cobrar).
  Future<Set<UuidValue>> giftProductIds(
    Session session,
    Set<UuidValue> productIds,
    Shopper shopper, {
    Transaction? transaction,
    UuidValue? customerId,
  });

  /// Cobra [lines] con las promociones vigentes que [shopper] puede usar
  /// (ver `promotion_engine.dart`): precios, descuentos, regalos y avisos.
  /// Con [customerId], también las de los códigos que activó; con
  /// [lockCodes] (al hacer el pedido, dentro de [transaction]) sus canjes
  /// quedan bloqueados hasta el final, y `PricedCart.usedRedemptionIds`
  /// dice cuáles gasta el pedido.
  Future<PricedCart> price(
    Session session,
    List<PricingLine> lines,
    Shopper shopper, {
    Transaction? transaction,
    UuidValue? customerId,
    bool lockCodes = false,
  });
}
