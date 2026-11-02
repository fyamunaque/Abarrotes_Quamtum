/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _is;

/// Qué da una promoción. Cada tipo usa sus campos de `Promotion`; el cobro
/// de cada línea lo calcula `promotion_engine.dart`.
enum PromotionType implements _is.SerializableModel {
  /// Un precio menor que el normal (`promoPriceCents`).
  specialPrice,

  /// Un porcentaje menos sobre el precio (`percent`).
  percentOff,

  /// Lleva N, paga M (`buyQuantity`, `payQuantity`): 2x1, 3x2…
  buyXPayY,

  /// Cada N.ª unidad con un porcentaje menos (`buyQuantity`, `percent`).
  extraUnit,

  /// Cada X unidades, Y de otro producto gratis (`buyQuantity`,
  /// `giftProduct`, `giftQuantity`).
  gift;

  static PromotionType fromJson(String name) {
    switch (name) {
      case 'specialPrice':
        return PromotionType.specialPrice;
      case 'percentOff':
        return PromotionType.percentOff;
      case 'buyXPayY':
        return PromotionType.buyXPayY;
      case 'extraUnit':
        return PromotionType.extraUnit;
      case 'gift':
        return PromotionType.gift;
      default:
        return PromotionType.specialPrice;
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
