import '../common/money.dart';
import 'category.dart';

/// Una promoción por cantidad o de regalo de un producto: [type] con los
/// nombres del servidor (`buyXPayY`, `extraUnit`, `gift`), cómo se nombra
/// ("2x1", "2.ª al 50 %", "Regalo: Sal 1 kg"), su título si tiene y lo que
/// da, para el detalle ("2x1 en este producto"). Los precios especiales y
/// los % no: van en el precio.
typedef ProductOffer = ({
  String type,
  String label,
  String? title,
  String description,
});

/// Una promoción como la manda el servidor (las de `promotions` de un
/// producto, o una de `/promotions/active`) como [ProductOffer]; null si es
/// de precio (precio especial o %) o de un tipo que esta versión no conoce.
ProductOffer? productOfferFromJson(Object? json) {
  if (json case {'type': final String type, 'label': final String label}
      when const {'buyXPayY', 'extraUnit', 'gift'}.contains(type)) {
    final buy = json['buyQuantity'];
    return (
      type: type,
      label: label,
      title: json['title'] as String?,
      description: switch ((type, json)) {
        ('buyXPayY', _) => '$label en este producto',
        ('extraUnit', {'percent': final int percent}) when buy is int =>
          'La $buy.ª unidad con $percent % menos',
        (
          'gift',
          {
            'giftProduct': {'name': final String name},
            'giftQuantity': final int quantity,
          },
        )
            when buy is int =>
          'Regalo: ${quantity > 1 ? '$quantity × ' : ''}$name por cada $buy',
        _ => label,
      },
    );
  }
  return null;
}

/// Una promoción por cantidad con los números que hacen falta para estimar
/// lo que cuestan N unidades ([Product.totalFor]): `buyXPayY` (lleva
/// [buyQuantity], paga [payQuantity]) o `extraUnit` (cada [buyQuantity].ª
/// unidad con [percent] % menos).
typedef QuantityDeal = ({
  String type,
  int buyQuantity,
  int? payQuantity,
  int? percent,
});

/// La promoción por cantidad de [json] (una de `promotions`), o null si es
/// de otro tipo o le falta un número.
QuantityDeal? quantityDealFromJson(Object? json) => switch (json) {
  {
    'type': 'buyXPayY',
    'buyQuantity': final int buy,
    'payQuantity': final int pay,
  } =>
    (type: 'buyXPayY', buyQuantity: buy, payQuantity: pay, percent: null),
  {
    'type': 'extraUnit',
    'buyQuantity': final int buy,
    'percent': final int percent,
  } =>
    (type: 'extraUnit', buyQuantity: buy, payQuantity: null, percent: percent),
  _ => null,
};

/// Un producto del catálogo, como lo muestra la app. Montos en céntimos, como
/// en el servidor (que en el JSON los manda como texto: `"4.5"`).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.stock,
    this.promoPriceCents,
    this.imageUrl,
    this.description,
    this.category,
    this.sku = '',
    this.active = true,
    this.minStock = 0,
    this.expirationDate,
    this.vipPrice = false,
    this.offers = const [],
    this.quantityDeals = const [],
  });

  /// Como lo manda el servidor (`productJson` en apps/server): el precio
  /// por unidad de quien mira (`unitPrice`, con el precio especial y los %)
  /// y sus promociones. Un servidor anterior solo manda `promotion`, el
  /// precio especial. Lanza [FormatException] si no tiene esa forma.
  factory Product.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'price': final String price,
      'currentStock': final int stock,
    }) {
      final priceCents = parseCents(price);
      final promotions = switch (json['promotions']) {
        final List<Object?> list => list,
        _ => const <Object?>[],
      };
      final promoPriceCents = switch ((json['unitPrice'], json['promotion'])) {
        (final String unit, _) => switch (parseCents(unit)) {
          final cents when cents < priceCents => cents,
          _ => null,
        },
        (_, {'promoPrice': final String promoPrice}) => parseCents(promoPrice),
        _ => null,
      };
      // Para los VIP (todos o algunos elegidos): el precio especial que se
      // cobra (el más bajo) o algún %.
      bool forVip(Object? audience) =>
          audience == 'vip' || audience == 'selected';
      final vipPrice =
          promoPriceCents != null &&
          (switch (json['promotion']) {
                {'audience': final audience} => forVip(audience),
                _ => false,
              } ||
              promotions.any(
                (p) => switch (p) {
                  {'type': 'percentOff', 'audience': final audience} => forVip(
                    audience,
                  ),
                  _ => false,
                },
              ));
      return Product(
        id: id,
        name: name,
        priceCents: priceCents,
        stock: stock,
        promoPriceCents: promoPriceCents,
        vipPrice: vipPrice,
        offers: [
          for (final promotion in promotions) ?productOfferFromJson(promotion),
        ],
        quantityDeals: [
          for (final promotion in promotions) ?quantityDealFromJson(promotion),
        ],
        imageUrl: json['imageUrl'] as String?,
        description: json['description'] as String?,
        category: json['category'] == null
            ? null
            : Category.fromJson(json['category']),
        sku: json['sku'] as String? ?? '',
        active: json['active'] as bool? ?? true,
        minStock: json['minStock'] as int? ?? 0,
        expirationDate: switch (json['expirationDate']) {
          final String date => DateTime.parse(date),
          _ => null,
        },
      );
    }
    throw FormatException('No es un producto', json);
  }

  // Lo que sigue lo usa el panel; la tienda solo ve productos activos.
  final String sku;
  final bool active;
  final int minStock;

  /// El día de vencimiento (en UTC, a las 00:00), si tiene.
  final DateTime? expirationDate;

  /// Si el stock llegó al mínimo (o está por debajo).
  bool get lowStock => stock <= minStock;

  final String id;
  final String name;
  final int priceCents;

  /// El precio por unidad con las promociones de precio (precio especial y
  /// %), si es menor que el normal.
  final int? promoPriceCents;

  /// Si ese precio sale de una promoción solo para clientes VIP. El
  /// servidor solo la manda a quien lo es.
  final bool vipPrice;

  /// Las promociones por cantidad y de regalo que puede usar quien mira.
  final List<ProductOffer> offers;

  /// Las promociones por cantidad, con sus números, para [totalFor].
  final List<QuantityDeal> quantityDeals;

  final String? imageUrl;
  final int stock;
  final String? description;
  final Category? category;

  bool get onSale => promoPriceCents != null;

  /// El mismo producto sin su precio VIP (para quien ya no es VIP): el precio
  /// normal, hasta que el servidor diga el de hoy.
  Product withoutVipPrice() => !vipPrice
      ? this
      : Product(
          id: id,
          name: name,
          priceCents: priceCents,
          stock: stock,
          imageUrl: imageUrl,
          description: description,
          category: category,
          sku: sku,
          active: active,
          minStock: minStock,
          expirationDate: expirationDate,
        );

  /// Lo que se paga hoy.
  int get finalPriceCents => promoPriceCents ?? priceCents;

  /// Lo que costarían [quantity] unidades, como las cobra el servidor: el
  /// precio de hoy ([finalPriceCents]) y, sobre él, las promociones por
  /// cantidad (primero las NxM y después las de la N.ª unidad, cada vez la
  /// que más ahorra con las unidades que quedan). La cotización del carrito
  /// tiene la última palabra.
  int totalFor(int quantity) {
    final unit = finalPriceCents;
    var units = quantity;
    var saved = 0;
    for (final type in const ['buyXPayY', 'extraUnit']) {
      final candidates = [
        for (final deal in quantityDeals)
          if (deal.type == type && deal.buyQuantity > 0) deal,
      ];
      while (candidates.isNotEmpty) {
        QuantityDeal? best;
        var bestSaved = 0;
        var bestUsed = 0;
        for (final deal in candidates) {
          final groups = units ~/ deal.buyQuantity;
          final dealSaved = switch (deal.type) {
            'buyXPayY' =>
              groups *
                  (deal.buyQuantity - (deal.payQuantity ?? deal.buyQuantity)) *
                  unit,
            _ => groups * (unit * (deal.percent ?? 0) / 100).round(),
          };
          if (dealSaved > bestSaved) {
            best = deal;
            bestSaved = dealSaved;
            bestUsed = groups * deal.buyQuantity;
          }
        }
        if (best == null) break;
        units -= bestUsed;
        saved += bestSaved;
        candidates.remove(best);
      }
    }
    return unit * quantity - saved;
  }

  bool get inStock => stock > 0;

  /// Cuántos se pueden pedir: el stock, y como mucho 999 (lo que el servidor
  /// acepta por línea).
  int get maxQuantity => stock.clamp(0, 999);
}
