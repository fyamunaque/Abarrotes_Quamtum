import '../common/money.dart';
import 'category.dart';

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
  });

  /// Como lo manda el servidor (`productJson` en apps/server, con la
  /// promoción vigente o null). Lanza [FormatException] si no tiene esa forma.
  factory Product.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'price': final String price,
      'currentStock': final int stock,
    }) {
      return Product(
        id: id,
        name: name,
        priceCents: parseCents(price),
        stock: stock,
        promoPriceCents: switch (json['promotion']) {
          {'promoPrice': final String promoPrice} => parseCents(promoPrice),
          _ => null,
        },
        vipPrice: switch (json['promotion']) {
          {'audience': 'vip'} => true,
          _ => false,
        },
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

  /// El precio de la promoción vigente, si tiene una.
  final int? promoPriceCents;

  /// Si esa promoción es solo para clientes VIP. El servidor solo la manda a
  /// quien lo es.
  final bool vipPrice;

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

  bool get inStock => stock > 0;

  /// Cuántos se pueden pedir: el stock, y como mucho 999 (lo que el servidor
  /// acepta por línea).
  int get maxQuantity => stock.clamp(0, 999);
}
