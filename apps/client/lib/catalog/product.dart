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
  });

  /// Como lo manda el servidor (el `Product` de packages/shared-types, con la
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
        imageUrl: json['imageUrl'] as String?,
        description: json['description'] as String?,
        category: json['category'] == null
            ? null
            : Category.fromJson(json['category']),
      );
    }
    throw FormatException('No es un producto', json);
  }

  final String id;
  final String name;
  final int priceCents;

  /// El precio de la promoción vigente, si tiene una.
  final int? promoPriceCents;

  final String? imageUrl;
  final int stock;
  final String? description;
  final Category? category;

  bool get onSale => promoPriceCents != null;

  /// Lo que se paga hoy.
  int get finalPriceCents => promoPriceCents ?? priceCents;

  bool get inStock => stock > 0;

  /// Cuántos se pueden pedir: el stock, y como mucho 999 (lo que el servidor
  /// acepta por línea).
  int get maxQuantity => stock.clamp(0, 999);
}
