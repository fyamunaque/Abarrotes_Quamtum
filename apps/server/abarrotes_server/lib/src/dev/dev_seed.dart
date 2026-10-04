import 'package:serverpod/serverpod.dart';

import '../common/store_time.dart';
import '../generated/protocol.dart';
import '../promotions/promotion_rules.dart';

/// Datos de ejemplo para probar la app contra el servidor local: categorías y
/// productos de una bodega, uno con promoción vigente por 30 días y uno
/// agotado. Sin imágenes: la app muestra su ícono.
///
/// Solo agrega si no hay productos, así que correrlo dos veces no duplica
/// nada. Devuelve cuántos productos creó (0 si ya había). Lo usa
/// `bin/seed_dev.dart`, que se niega fuera de development.
Future<int> seedDevData(Session session, {DateTime Function()? now}) async {
  if (await Product.db.count(session) > 0) return 0;

  return session.db.transaction((transaction) async {
    final categories = <String, Category>{};
    for (final name in _catalog.keys) {
      categories[name] = await Category.db.insertRow(
        session,
        Category(name: name),
        transaction: transaction,
      );
    }

    var created = 0;
    for (final MapEntry(key: category, value: products) in _catalog.entries) {
      for (final p in products) {
        final product = await Product.db.insertRow(
          session,
          Product(
            name: p.name,
            description: p.description,
            sku: p.sku,
            priceCents: p.priceCents,
            currentStock: p.stock,
            minStock: 5,
            categoryId: categories[category]!.id!,
          ),
          transaction: transaction,
        );
        created++;

        if (p.promoPriceCents case final promoPrice?) {
          final today = storeDay((now ?? DateTime.now)());
          final period = toStoredPeriod(today, addDays(today, 29));
          await Promotion.db.insertRow(
            session,
            Promotion(
              productId: product.id!,
              promoPriceCents: promoPrice,
              startDate: period.startDate,
              endDate: period.endDate,
            ),
            transaction: transaction,
          );
        }
      }
    }
    return created;
  });
}

typedef _SeedProduct = ({
  String name,
  String sku,
  String description,
  int priceCents,
  int stock,
  int? promoPriceCents,
});

_SeedProduct _product(
  String name,
  String sku,
  int priceCents,
  int stock,
  String description, {
  int? promoPriceCents,
}) => (
  name: name,
  sku: sku,
  description: description,
  priceCents: priceCents,
  stock: stock,
  promoPriceCents: promoPriceCents,
);

final _catalog = <String, List<_SeedProduct>>{
  'Abarrotes': [
    _product(
      'Arroz extra 5 kg',
      'ARR-5KG',
      2490,
      40,
      'Grano largo, bolsa de 5 kg.',
    ),
    _product(
      'Aceite vegetal 1 L',
      'ACE-1L',
      1090,
      25,
      'Aceite vegetal para cocinar y freír.',
      promoPriceCents: 890,
    ),
    _product('Azúcar rubia 1 kg', 'AZU-1KG', 450, 0, 'Bolsa de 1 kg.'),
    _product('Fideos spaghetti 500 g', 'FID-500', 380, 60, 'Paquete de 500 g.'),
  ],
  'Lácteos': [
    _product(
      'Leche evaporada entera 400 g',
      'LEC-400',
      420,
      48,
      'Lata de 400 g.',
    ),
    _product('Yogurt de fresa 1 L', 'YOG-1L', 750, 15, 'Botella de 1 L.'),
    _product('Queso fresco 500 g', 'QUE-500', 1450, 10, 'Pieza de 500 g.'),
  ],
  'Bebidas': [
    _product('Agua sin gas 2.5 L', 'AGU-2L5', 350, 30, 'Botella de 2.5 L.'),
    _product('Gaseosa 1.5 L', 'GAS-1L5', 650, 24, 'Botella de 1.5 L.'),
  ],
  'Limpieza': [
    _product(
      'Detergente en polvo 900 g',
      'DET-900',
      1290,
      20,
      'Bolsa de 900 g.',
    ),
    _product('Lejía 1 L', 'LEJ-1L', 390, 18, 'Botella de 1 L.'),
  ],
  'Snacks': [
    _product(
      'Galletas de soda, paquete de 6',
      'GAL-6',
      290,
      35,
      'Seis paquetes individuales.',
    ),
  ],
};
