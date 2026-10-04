/// Lo que se manda al crear o editar un producto. Al editar se mandan todos
/// los campos editables: un campo opcional en null lo borra (descripción,
/// imagen, vencimiento). El stock solo se pone al crear; después, por
/// inventario.
class ProductInput {
  const ProductInput({
    required this.name,
    required this.sku,
    required this.priceCents,
    required this.categoryId,
    required this.minStock,
    required this.active,
    this.description,
    this.imageUrl,
    this.expirationDate,
    this.initialStock = 0,
  });

  final String name;
  final String sku;
  final int priceCents;
  final String categoryId;
  final int minStock;
  final bool active;
  final String? description;
  final String? imageUrl;

  /// El día de vencimiento (se manda a las 00:00 UTC, como lo guarda el
  /// servidor).
  final DateTime? expirationDate;

  /// Solo al crear.
  final int initialStock;

  /// El body de `POST /products` ([create]) o `PATCH /products/:id`.
  Map<String, Object?> toJson({required bool create}) => {
    'name': name,
    'sku': sku,
    // El servidor recibe soles como número ("4.5" → 4.5).
    'price': priceCents / 100,
    'categoryId': categoryId,
    'minStock': minStock,
    'active': active,
    'description': description,
    'imageUrl': imageUrl,
    'expirationDate': switch (expirationDate) {
      final date? => DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).toIso8601String(),
      null => null,
    },
    if (create) 'currentStock': initialStock,
  };
}
