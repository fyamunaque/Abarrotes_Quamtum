import '../common/money.dart';
import '../generated/protocol.dart';

/// Cómo se nombra una promoción para las personas, según su tipo: "Precio
/// especial S/ 19.90", "20 % menos", "2x1", "2.ª al 50 %" o "Regalo: Sal
/// 1 kg" (sin el producto de regalo incluido, solo "Regalo").
String promotionLabel(Promotion promotion) => switch (promotion.type) {
  PromotionType.specialPrice =>
    'Precio especial ${formatSoles(promotion.promoPriceCents!)}',
  PromotionType.percentOff => '${promotion.percent} % menos',
  PromotionType.buyXPayY => '${promotion.buyQuantity}x${promotion.payQuantity}',
  PromotionType.extraUnit =>
    '${promotion.buyQuantity}.ª al ${promotion.percent} %',
  PromotionType.gift => switch (promotion.giftProduct) {
    final gift? => 'Regalo: ${gift.name}',
    null => 'Regalo',
  },
};
