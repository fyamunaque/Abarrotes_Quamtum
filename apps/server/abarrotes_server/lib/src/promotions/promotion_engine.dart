import 'package:serverpod/serverpod.dart' show UuidValue;

import '../generated/protocol.dart';
import 'promotion_labels.dart';

/// El motor de cobro: con qué precio y qué descuentos se cobra cada línea,
/// y qué se regala. Es una función pura (sin base de datos): la llaman el
/// pedido, la cotización y el catálogo a través de `PromotionPricing`.
///
/// Orden fijo en cada línea, con las promociones vigentes que el cliente
/// puede usar:
/// 1. Precio unitario: el precio especial más bajo, o el normal.
/// 2. Porcentajes: todos, en cadena, redondeando al céntimo en cada paso.
/// 3. Por cantidad, sobre el precio del paso 2: primero los NxM y después la
///    unidad extra. Cada unidad entra en una sola; entre dos que compiten
///    gana la que más ahorra.
/// 4. Regalos: líneas aparte a S/ 0, hasta donde alcance el stock.

/// Un producto que se compra, con su precio normal.
typedef PricingLine = ({
  UuidValue productId,
  String name,
  int listUnitPriceCents,
  int quantity,
});

/// Un producto que se puede regalar: si está activo y cuánto stock tiene.
typedef GiftProduct = ({
  UuidValue id,
  String name,
  int priceCents,
  bool active,
  int stock,
});

/// Una línea cobrada: la comprada (con sus promociones) o un regalo.
class PricedLine {
  PricedLine({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.listUnitPriceCents,
    required this.unitPriceCents,
    required this.lineTotalCents,
    required this.isGift,
    required this.promotions,
  });

  final UuidValue productId;
  final String name;
  final int quantity;

  /// El precio normal.
  final int listUnitPriceCents;

  /// Después del precio especial y los porcentajes (0 en un regalo).
  final int unitPriceCents;

  /// Lo que se cobra por la línea.
  final int lineTotalCents;
  final bool isGift;
  final List<AppliedPromotion> promotions;
}

/// El carrito cobrado: las líneas compradas y, al final, los regalos.
class PricedCart {
  PricedCart({required this.lines, required this.notices});

  final List<PricedLine> lines;

  /// Avisos para el cliente (p. ej. un regalo sin stock).
  final List<String> notices;

  /// A precio normal, sin los regalos.
  int get subtotalCents => lines
      .where((line) => !line.isGift)
      .fold(0, (sum, line) => sum + line.listUnitPriceCents * line.quantity);

  int get totalCents => lines.fold(0, (sum, line) => sum + line.lineTotalCents);

  int get discountCents => subtotalCents - totalCents;

  Set<UuidValue> get appliedPromotionIds => {
    for (final line in lines)
      for (final promotion in line.promotions) promotion.promotionId,
  };
}

/// Cobra [lines] con las promociones de cada producto
/// ([promotionsByProduct]: las vigentes que el cliente puede usar) y los
/// datos de los productos de regalo ([giftProducts]).
PricedCart priceCart(
  List<PricingLine> lines,
  Map<UuidValue, List<Promotion>> promotionsByProduct,
  Map<UuidValue, GiftProduct> giftProducts,
) {
  final priced = <PricedLine>[];
  final gifts = <PricedLine>[];
  final notices = <String>[];
  // Lo que queda de cada regalo: su stock menos lo que ya se compra.
  final giftStock = <UuidValue, int>{
    for (final gift in giftProducts.values)
      gift.id: gift.active
          ? gift.stock -
                lines
                    .where((line) => line.productId == gift.id)
                    .fold(0, (sum, line) => sum + line.quantity)
          : 0,
  };

  for (final line in lines) {
    final promotions = promotionsByProduct[line.productId] ?? const [];
    final applied = <AppliedPromotion>[];

    // 1. y 2.
    final (:unit, :steps) = _unitPrice(line.listUnitPriceCents, promotions);
    for (final (promotion, savedPerUnit) in steps) {
      applied.add(_applied(promotion, savedPerUnit * line.quantity));
    }

    // 3.
    var units = line.quantity;
    var quantitySaved = 0;
    for (final type in [PromotionType.buyXPayY, PromotionType.extraUnit]) {
      final candidates = [
        for (final p in promotions)
          if (p.type == type) p,
      ];
      while (candidates.isNotEmpty) {
        final best = _best(candidates, units, unit);
        if (best == null) break;
        final (promotion, used, saved) = best;
        applied.add(_applied(promotion, saved));
        units -= used;
        quantitySaved += saved;
        candidates.remove(promotion);
      }
    }

    priced.add(
      PricedLine(
        productId: line.productId,
        name: line.name,
        quantity: line.quantity,
        listUnitPriceCents: line.listUnitPriceCents,
        unitPriceCents: unit,
        lineTotalCents: unit * line.quantity - quantitySaved,
        isGift: false,
        promotions: applied,
      ),
    );

    // 4.
    for (final promotion in promotions) {
      if (promotion.type != PromotionType.gift) continue;
      final wanted =
          line.quantity ~/ promotion.buyQuantity! * promotion.giftQuantity!;
      if (wanted == 0) continue;
      final giftId = promotion.giftProductId!;
      final gift = giftProducts[giftId];
      final name = gift?.name ?? promotion.giftProduct?.name ?? 'El regalo';
      final left = giftStock[giftId] ?? 0;
      if (gift == null || left <= 0) {
        notices.add('$name ya no está disponible para regalo');
        continue;
      }
      final given = wanted <= left ? wanted : left;
      if (given < wanted) {
        notices.add('Solo quedaba $given de $name para regalo');
      }
      giftStock[giftId] = left - given;
      gifts.add(
        PricedLine(
          productId: giftId,
          name: name,
          quantity: given,
          listUnitPriceCents: gift.priceCents,
          unitPriceCents: 0,
          lineTotalCents: 0,
          isGift: true,
          promotions: [_applied(promotion, gift.priceCents * given)],
        ),
      );
    }
  }
  return PricedCart(lines: [...priced, ...gifts], notices: notices);
}

/// El precio por unidad con los pasos 1 y 2 (lo que muestra el catálogo).
int unitPriceFor(int listUnitPriceCents, List<Promotion> promotions) =>
    _unitPrice(listUnitPriceCents, promotions).unit;

/// Pasos 1 y 2: el precio y cuánto ahorró por unidad cada promoción.
({int unit, List<(Promotion, int)> steps}) _unitPrice(
  int listUnitPriceCents,
  List<Promotion> promotions,
) {
  final steps = <(Promotion, int)>[];
  var unit = listUnitPriceCents;
  final specials = [
    for (final p in promotions)
      if (p.type == PromotionType.specialPrice &&
          p.promoPriceCents! < listUnitPriceCents)
        p,
  ]..sort((a, b) => a.promoPriceCents!.compareTo(b.promoPriceCents!));
  if (specials.firstOrNull case final special?) {
    steps.add((special, unit - special.promoPriceCents!));
    unit = special.promoPriceCents!;
  }
  for (final p in promotions) {
    if (p.type != PromotionType.percentOff) continue;
    final after = (unit * (100 - p.percent!) / 100).round();
    steps.add((p, unit - after));
    unit = after;
  }
  return (unit: unit, steps: steps);
}

/// Entre [candidates] (del mismo tipo por cantidad), la que más ahorra sobre
/// [units] unidades a [unit]: la promoción, cuántas unidades usa y cuánto
/// ahorra. Null si ninguna ahorra (desempate: el id menor).
(Promotion, int, int)? _best(List<Promotion> candidates, int units, int unit) {
  (Promotion, int, int)? best;
  for (final p in candidates) {
    final groups = units ~/ p.buyQuantity!;
    final used = groups * p.buyQuantity!;
    final saved = switch (p.type) {
      PromotionType.buyXPayY =>
        groups * (p.buyQuantity! - p.payQuantity!) * unit,
      _ => groups * (unit * p.percent! / 100).round(),
    };
    if (saved <= 0) continue;
    if (best == null ||
        saved > best.$3 ||
        (saved == best.$3 &&
            p.id.toString().compareTo(best.$1.id.toString()) < 0)) {
      best = (p, used, saved);
    }
  }
  return best;
}

AppliedPromotion _applied(Promotion promotion, int savedCents) =>
    AppliedPromotion(
      promotionId: promotion.id!,
      label: promotionLabel(promotion),
      savedCents: savedCents,
    );
