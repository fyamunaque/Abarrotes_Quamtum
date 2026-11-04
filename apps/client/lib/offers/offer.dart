import '../catalog/product.dart';
import '../common/money.dart';

/// Una promoción vigente como la ve el cliente (`GET /promotions/active` en
/// apps/server): el producto con su precio normal y el de la oferta (un
/// precio especial o un %), o lo que da ([deal]: un NxM, una unidad extra o
/// un regalo).
class Offer {
  const Offer({
    required this.id,
    required this.productId,
    required this.productName,
    required this.priceCents,
    this.promoPriceCents,
    this.deal,
    required this.endDate,
    this.title,
    this.vip = false,
    this.imageUrl,
    this.categoryId,
  });

  /// Lanza [FormatException] si [json] no tiene esa forma.
  factory Offer.fromJson(Object? json) => switch (json) {
    {
          'id': final String id,
          'endDate': final String endDate,
          'product':
              {
                'id': final String productId,
                'name': final String productName,
                'price': final String price,
              } &&
              final Map<Object?, Object?> product,
        } &&
        final Map<Object?, Object?> map =>
      Offer(
        id: id,
        productId: productId,
        productName: productName,
        priceCents: parseCents(price),
        // Un % se redondea como en el servidor.
        promoPriceCents: switch (map) {
          {'promoPrice': final String promoPrice} => parseCents(promoPrice),
          {'type': 'percentOff', 'percent': final int percent} =>
            (parseCents(price) * (100 - percent) / 100).round(),
          _ => null,
        },
        deal: productOfferFromJson(map),
        endDate: endDate,
        title: map['title'] as String?,
        // Para los VIP: todos o algunos elegidos.
        vip: map['audience'] == 'vip' || map['audience'] == 'selected',
        imageUrl: product['imageUrl'] as String?,
        categoryId: product['categoryId'] as String?,
      ),
    _ => throw FormatException('No es una oferta', json),
  };

  final String id;
  final String productId;
  final String productName;
  final String? imageUrl;

  /// La categoría del producto: el color de su marcador si no tiene foto.
  final String? categoryId;

  /// El precio normal del producto y el de la oferta, si es de precio.
  final int priceCents;
  final int? promoPriceCents;

  /// Si no es de precio: el NxM, la unidad extra o el regalo.
  final ProductOffer? deal;

  /// El último día (de la tienda, `AAAA-MM-DD`) en que rige.
  final String endDate;

  /// El nombre de la oferta (p. ej. "Semana del arroz"), si tiene.
  final String? title;

  /// Si es solo para clientes VIP.
  final bool vip;
}
