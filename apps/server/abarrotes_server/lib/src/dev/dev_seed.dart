import 'dart:io';
import 'dart:math';

// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:serverpod/serverpod.dart' hide Order;

import '../common/store_time.dart';
import '../generated/protocol.dart';
import '../orders/pickup_code.dart';
import '../products/product_images.dart';
import '../promotions/promotion_rules.dart';

/// Datos de ejemplo para probar la app contra el servidor local: las
/// categorías de una bodega con sus productos, uno con promoción vigente por
/// 30 días y uno agotado. Las fotos van aparte, con [seedDevPhotos].
///
/// Completa lo que falta: agrega las categorías (por nombre) y los productos
/// (por SKU) que no están, y nunca toca uno que ya existe, aunque se haya
/// editado o dado de baja. Las categorías con su nombre de antes ("Lácteos",
/// "Snacks") se renombran. Correrlo dos veces no duplica nada. Devuelve
/// cuántos productos agregó. Lo usa `bin/seed_dev.dart`, que se niega fuera
/// de development.
Future<int> seedDevData(Session session, {DateTime Function()? now}) async {
  return session.db.transaction((transaction) async {
    Future<Category?> categoryNamed(String name) => Category.db.findFirstRow(
      session,
      where: (category) => category.name.equals(name),
      transaction: transaction,
    );

    for (final (before, after) in _renamedCategories) {
      final old = await categoryNamed(before);
      if (old != null && await categoryNamed(after) == null) {
        await Category.db.updateRow(
          session,
          old.copyWith(name: after),
          columns: (category) => [category.name],
          transaction: transaction,
        );
      }
    }

    final categories = {
      for (final category in await Category.db.find(
        session,
        transaction: transaction,
      ))
        category.name: category,
    };
    final skus = {
      for (final product in await Product.db.find(
        session,
        transaction: transaction,
      ))
        product.sku,
    };

    var created = 0;
    for (final MapEntry(key: name, value: products) in _catalog.entries) {
      final category = categories[name] ??= await Category.db.insertRow(
        session,
        Category(name: name),
        transaction: transaction,
      );
      for (final p in products) {
        if (skus.contains(p.sku)) continue;
        final product = await Product.db.insertRow(
          session,
          Product(
            name: p.name,
            description: p.description,
            sku: p.sku,
            priceCents: p.priceCents,
            currentStock: p.stock,
            minStock: 5,
            categoryId: category.id!,
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

/// Dónde están las fotos de los productos de ejemplo: una por SKU
/// (`ARR-5KG.jpg`), ya procesadas con [ProductImages.process]. Su origen y
/// licencia, en `CREDITS.md` de la misma carpeta.
const devPhotosFolder = 'assets/seed/products';

/// Les pone su foto de ejemplo a los productos del seed que no tienen una.
/// Nunca reemplaza una foto (subida o URL) que alguien ya puso. Correrlo de
/// nuevo no hace nada. Devuelve cuántas puso.
Future<int> seedDevPhotos(
  Session session, {
  String folder = devPhotosFolder,
  ProductImages? images,
}) async {
  final store = images ?? ProductImages();
  final skus = {
    for (final products in _catalog.values)
      for (final product in products) product.sku,
  };
  final withoutPhoto = await Product.db.find(
    session,
    where: (product) => product.sku.inSet(skus) & product.imageUrl.equals(null),
  );
  var added = 0;
  for (final product in withoutPhoto) {
    final file = File('$folder/${product.sku}.jpg');
    if (!file.existsSync()) continue;
    final url = await store.store(session, product.id!, file.readAsBytesSync());
    await Product.db.updateRow(
      session,
      product.copyWith(imageUrl: url),
      columns: (columns) => [columns.imageUrl],
    );
    added++;
  }
  return added;
}

/// Pedidos de ejemplo para el panel: 40 de un cliente de ejemplo, repartidos
/// en los últimos 30 días, siempre los mismos (semilla fija).
/// - Los dos más recientes están pendientes, los dos siguientes confirmados
///   y otros dos en camino; los demás, entregados (uno de cada ocho,
///   cancelado).
/// - Cobran el precio de hoy y no tocan el stock: son historia de ejemplo.
/// - Deja también algo para las alertas: el yogurt vence en 3 días y la leche
///   en 10 (si no tenían fecha), y la lejía queda bajo su mínimo.
///
/// El cliente (`seed-cliente-demo`) no es una cuenta de Firebase: no se puede
/// ingresar con él. Solo agrega si ese cliente todavía no tiene pedidos y ya
/// hay productos con stock. Devuelve cuántos pedidos creó.
Future<int> seedDevOrders(Session session, {DateTime Function()? now}) =>
    _seedOrders(session, (now ?? DateTime.now)().toUtc(), reset: false);

/// Vuelve a generar los pedidos de ejemplo con fechas hasta hoy, para que una
/// demo arranque como recién cargada: borra los del cliente de ejemplo
/// (primero sus items) y los crea de nuevo, y vuelve a fechar desde hoy los
/// vencimientos de ejemplo (yogurt y leche). No toca los pedidos de otras
/// cuentas, el resto de los productos ni el stock. Devuelve cuántos pedidos
/// creó.
Future<int> resetDevOrders(Session session, {DateTime Function()? now}) =>
    _seedOrders(session, (now ?? DateTime.now)().toUtc(), reset: true);

Future<int> _seedOrders(
  Session session,
  DateTime clock, {
  required bool reset,
}) async {
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
            address: 'Av. Arequipa 1234, Lince',
          ),
          transaction: transaction,
        );

    final previous = {
      for (final order in await Order.db.find(
        session,
        where: (order) => order.customerId.equals(customer.id),
        transaction: transaction,
      ))
        order.id!,
    };
    if (previous.isNotEmpty) {
      if (!reset) return 0;
      // Los items no se borran solos (onDelete=Restrict).
      await OrderItem.db.deleteWhere(
        session,
        where: (item) => item.orderId.inSet(previous),
        transaction: transaction,
      );
      await Order.db.deleteWhere(
        session,
        where: (order) => order.id.inSet(previous),
        transaction: transaction,
      );
    }

    const count = 40;
    final pickupCodes = <String>{};
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
      // Fijo, para que el panel siempre tenga de todo: los más recientes
      // esperan acción y los viejos ya terminaron. Uno de cada cuatro (y
      // los que se preparan o esperan) es de recojo en tienda.
      final recent = count - 1 - i;
      final status = switch (recent) {
        0 || 1 => OrderStatus.pendingConfirmation,
        2 || 3 => OrderStatus.confirmed,
        4 || 5 => OrderStatus.outForDelivery,
        6 => OrderStatus.preparing,
        7 => OrderStatus.readyForPickup,
        _ when i % 8 == 3 => OrderStatus.cancelled,
        _ => OrderStatus.delivered,
      };
      final pickup =
          recent == 3 ||
          status == OrderStatus.preparing ||
          status == OrderStatus.readyForPickup ||
          (recent > 7 && i % 4 == 1);
      String? pickupCode;
      if (pickup) {
        do {
          pickupCode = randomPickupCode();
        } while (!pickupCodes.add(pickupCode));
      }

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
          fulfillmentType: pickup
              ? FulfillmentType.pickup
              : FulfillmentType.delivery,
          totalCents: lines.fold(
            0,
            (sum, line) => sum + line.unitPrice * line.quantity,
          ),
          deliveryAddress: pickup
              ? null
              : customer.address ?? 'Av. Arequipa 1234, Lince',
          pickupCode: pickupCode,
          readyForPickupAt:
              pickup &&
                  (status == OrderStatus.readyForPickup ||
                      status == OrderStatus.delivered)
              ? createdAt.add(const Duration(hours: 1))
              : null,
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
      // Al reiniciar se vuelven a fechar: si no, vencen y salen de la alerta.
      if (product != null && (reset || product.expirationDate == null)) {
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

/// Las categorías que cambiaron de nombre: (antes, ahora).
const _renamedCategories = [
  ('Lácteos', 'Lácteos y huevos'),
  ('Snacks', 'Snacks y dulces'),
];

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
  'Lácteos y huevos': [
    _product(
      'Leche evaporada entera 400 g',
      'LEC-400',
      420,
      48,
      'Lata de 400 g.',
    ),
    _product('Yogurt de fresa 1 L', 'YOG-1L', 750, 15, 'Botella de 1 L.'),
    _product('Queso fresco 500 g', 'QUE-500', 1450, 10, 'Pieza de 500 g.'),
    _product(
      'Huevos rosados, 15 unidades',
      'HUE-15',
      1290,
      20,
      'Bandeja de 15 huevos.',
    ),
  ],
  'Carnes y embutidos': [
    _product(
      'Pechuga de pollo 1 kg',
      'POL-1KG',
      1890,
      12,
      'Pechuga sin hueso, 1 kg.',
    ),
    _product(
      'Hot dog de pollo, 10 unidades',
      'HOT-10',
      890,
      25,
      'Paquete de 10 salchichas.',
    ),
    _product('Jamonada 250 g', 'JAM-250', 690, 15, 'Tajada fina, 250 g.'),
  ],
  'Frutas y verduras': [
    _product('Plátano de seda 1 kg', 'PLA-1KG', 450, 30, 'Un kilo, aprox.'),
    _product('Papa amarilla 1 kg', 'PAP-1KG', 390, 40, 'Bolsa de 1 kg.'),
    _product('Cebolla roja 1 kg', 'CEB-1KG', 320, 35, 'Bolsa de 1 kg.'),
  ],
  'Panadería': [
    _product(
      'Pan francés, 10 unidades',
      'PAN-10',
      400,
      30,
      'Bolsa de 10 panes del día.',
    ),
    _product(
      'Pan de molde blanco 600 g',
      'MOL-600',
      790,
      18,
      'Bolsa de 600 g.',
    ),
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
  'Cuidado personal': [
    _product('Jabón de tocador, pack de 3', 'JAB-3', 650, 25, 'Tres barras.'),
    _product(
      'Papel higiénico, 4 rollos',
      'PHI-4',
      590,
      40,
      'Paquete de 4 rollos dobles.',
    ),
    _product('Shampoo 400 ml', 'SHA-400', 1590, 12, 'Frasco de 400 ml.'),
  ],
  'Snacks y dulces': [
    _product(
      'Galletas de soda, paquete de 6',
      'GAL-6',
      290,
      35,
      'Seis paquetes individuales.',
    ),
    _product(
      'Chocolate de leche 100 g',
      'CHO-100',
      450,
      30,
      'Tableta de 100 g.',
    ),
  ],
};
