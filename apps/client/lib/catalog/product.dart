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
  });

  final String id;
  final String name;
  final int priceCents;

  /// El precio de la promoción vigente, si tiene una.
  final int? promoPriceCents;

  final String? imageUrl;
  final int stock;

  bool get onSale => promoPriceCents != null;

  /// Lo que se paga hoy.
  int get finalPriceCents => promoPriceCents ?? priceCents;

  bool get inStock => stock > 0;

  /// Cuántos se pueden pedir: el stock, y como mucho 999 (lo que el servidor
  /// acepta por línea).
  int get maxQuantity => stock.clamp(0, 999);
}
