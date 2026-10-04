import 'dart:math';

// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:serverpod/serverpod.dart' hide Order;

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

/// Pedidos de ejemplo para el panel: 40 de un cliente de ejemplo, repartidos
/// en los últimos 30 días, siempre los mismos (semilla fija).
/// - Los viejos quedaron entregados (y alguno cancelado); los de los últimos
///   días están pendientes, confirmados o en camino.
/// - Cobran el precio de hoy y no tocan el stock: son historia de ejemplo.
/// - Deja también algo para las alertas: el yogurt vence en 3 días y la leche
///   en 10 (si no tenían fecha), y la lejía queda bajo su mínimo.
///
/// El cliente (`seed-cliente-demo`) no es una cuenta de Firebase: no se puede
/// ingresar con él. Solo agrega si no hay pedidos y ya hay productos con
/// stock. Devuelve cuántos pedidos creó.
Future<int> seedDevOrders(Session session, {DateTime Function()? now}) async {
  final clock = (now ?? DateTime.now)().toUtc();
  if (await Order.db.count(session) > 0) return 0;
  final products = await Product.db.find(
    session,
    where: (product) =>
        product.active.equals(true) & (product.currentStock > 0),
    orderBy: (product) => product.sku,
    include: Product.include(
      promotions: Promotion.includeList(
        where: (promotion) => activePromotionWhere(promotion, clock),
        limit: 1,
      ),
    ),
  );
  if (products.isEmpty) return 0;

  final random = Random(42);
  T pick<T>(List<T> options) => options[random.nextInt(options.length)];

  return session.db.transaction((transaction) async {
    final customer =
        await User.db.findFirstRow(
          session,
          where: (user) => user.firebaseUid.equals(_demoCustomerUid),
          transaction: transaction,
        ) ??
        await User.db.insertRow(
          session,
          User(
            firebaseUid: _demoCustomerUid,
            email: 'cliente.demo@neils.pe',
            name: 'Cliente de ejemplo',
            role: UserRole.customer,
            address: 'Av. Arequipa 1234, Lince',
          ),
          transaction: transaction,
        );

    const count = 40;
    for (var i = 0; i < count; i++) {
      // Del día 29 hacia atrás hasta hoy, unos por día.
      final daysAgo = 29 - (i * 29) ~/ (count - 1);
      final createdAt = clock.subtract(
        Duration(
          days: daysAgo,
          hours: random.nextInt(8),
          minutes: random.nextInt(60),
        ),
      );
      final status = switch (daysAgo) {
        <= 1 => pick(const [
          OrderStatus.pendingConfirmation,
          OrderStatus.confirmed,
          OrderStatus.outForDelivery,
        ]),
        <= 3 => pick(const [
          OrderStatus.confirmed,
          OrderStatus.outForDelivery,
          OrderStatus.delivered,
        ]),
        _ =>
          random.nextInt(8) == 0
              ? OrderStatus.cancelled
              : OrderStatus.delivered,
      };

      final lines = [
        for (final product in (List.of(products)..shuffle(random)).take(
          1 + random.nextInt(3),
        ))
          (
            product: product,
            quantity: 1 + random.nextInt(3),
            unitPrice:
                product.promotions?.firstOrNull?.promoPriceCents ??
                product.priceCents,
          ),
      ];
      final order = await Order.db.insertRow(
        session,
        Order(
          status: status,
          totalCents: lines.fold(
            0,
            (sum, line) => sum + line.unitPrice * line.quantity,
          ),
          deliveryAddress: customer.address ?? 'Av. Arequipa 1234, Lince',
          createdAt: createdAt,
          updatedAt: createdAt,
          customerId: customer.id!,
        ),
        transaction: transaction,
      );
      await OrderItem.db.insert(session, [
        for (final line in lines)
          OrderItem(
            quantity: line.quantity,
            unitPriceCents: line.unitPrice,
            orderId: order.id!,
            productId: line.product.id!,
          ),
      ], transaction: transaction);
    }

    final today = storeDay(clock);
    for (final (sku, days) in const [('YOG-1L', 3), ('LEC-400', 10)]) {
      final product = await Product.db.findFirstRow(
        session,
        where: (product) => product.sku.equals(sku),
        transaction: transaction,
      );
      if (product != null && product.expirationDate == null) {
        await Product.db.updateRow(
          session,
          product.copyWith(expirationDate: utcMidnight(addDays(today, days))),
          columns: (product) => [product.expirationDate],
          transaction: transaction,
        );
      }
    }
    final bleach = await Product.db.findFirstRow(
      session,
      where: (product) => product.sku.equals('LEJ-1L'),
      transaction: transaction,
    );
    if (bleach != null && bleach.minStock < bleach.currentStock) {
      await Product.db.updateRow(
        session,
        bleach.copyWith(minStock: bleach.currentStock + 2),
        columns: (product) => [product.minStock],
        transaction: transaction,
      );
    }
    return count;
  });
}

const _demoCustomerUid = 'seed-cliente-demo';

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
