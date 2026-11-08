import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/pagination.dart';
import '../common/shopper.dart';
import '../generated/protocol.dart';
import '../promotions/promotion_pricing.dart';
import 'product_images.dart';

/// Productos del catálogo. Cada producto se devuelve con su categoría y la
/// mejor promoción vigente que puede usar quien mira (en `promotions`, a lo
/// sumo una): un cliente nunca ve una promoción que no es para él.
///
/// Cuando la foto de un producto cambia o se quita, la que tenía se borra si
/// era una subida ([ProductImages]).
class ProductsService {
  ProductsService({
    required this._pricing,
    ProductImages? images,
    DateTime Function()? now,
  }) : _images = images ?? ProductImages(),
       _now = now ?? DateTime.now;

  final PromotionPricing _pricing;
  final ProductImages _images;
  final DateTime Function() _now;

  /// Por nombre. [includeInactive] es solo para admin y staff: decide la ruta.
  /// [onSale] deja los que tienen una promoción que [shopper] puede usar.
  Future<(List<Product>, int)> list(
    Session session,
    PageQuery page, {
    Shopper shopper = Shopper.anonymous,
    UuidValue? categoryId,
    String? search,
    bool includeInactive = false,
    bool onSale = false,
  }) async {
    final now = _now().toUtc();
    Expression where(ProductTable product) {
      Expression filter = Constant.bool(true);
      if (categoryId != null) filter &= product.categoryId.equals(categoryId);
      if (!includeInactive) filter &= product.active.equals(true);
      if (onSale) {
        filter &= product.promotions.any(
          (promotion) => _pricing.eligibleWhere(promotion, now, shopper),
        );
      }
      if (search != null) {
        final pattern = '%${escapeLike(search)}%';
        filter &= (product.name.ilike(pattern) | product.sku.ilike(pattern));
      }
      return filter;
    }

    final products = await Product.db.find(
      session,
      where: where,
      orderByList: (product) => [product.name.asc(), product.id.asc()],
      limit: page.limit,
      offset: page.offset,
      include: _include(now, shopper),
    );
    final total = await Product.db.count(session, where: where);
    return (products, total);
  }

  /// Lo que más pide [customerId]: los productos de sus pedidos no
  /// cancelados de los últimos 180 días, sin los regalos ni los dados de
  /// baja. Primero el que está en más pedidos; si empatan, el pedido más
  /// reciente, y después el nombre. Con el precio de [shopper].
  Future<List<Product>> frequent(
    Session session, {
    required UuidValue customerId,
    Shopper shopper = Shopper.anonymous,
    int limit = 20,
  }) async {
    final now = _now().toUtc();
    final ids = await _frequentIds(session, customerId, now, limit);
    return _inOrder(session, ids, now, shopper);
  }

  /// Lo más vendido de la tienda en unidades en los últimos 30 días, en
  /// pedidos no cancelados: sin los regalos, los dados de baja ni los
  /// agotados. Con [customerId], sin los que ya salen en sus Frecuentes. Si
  /// así no queda ninguno (una tienda sin ventas recientes), lo más nuevo
  /// con stock, para que la pestaña no quede vacía.
  Future<List<Product>> suggested(
    Session session, {
    UuidValue? customerId,
    Shopper shopper = Shopper.anonymous,
    int limit = 20,
  }) async {
    final now = _now().toUtc();
    final exclude = customerId == null
        ? const <String>[]
        : await _frequentIds(session, customerId, now, limit);
    final rows = await session.db.unsafeQuery(
      '''
      SELECT oi."productId"::text AS id
      FROM order_items oi
      JOIN orders o ON o.id = oi."orderId"
      JOIN products p ON p.id = oi."productId"
      WHERE o.status <> 'cancelled'
        AND o."createdAt" >= @since::timestamp
        AND NOT oi."isGift"
        AND p.active
        AND p."currentStock" > 0
        AND NOT (oi."productId" = ANY(@exclude::uuid[]))
      GROUP BY oi."productId", p.name
      ORDER BY SUM(oi.quantity) DESC, p.name
      LIMIT @limit
      ''',
      parameters: QueryParameters.named({
        'since': now.subtract(const Duration(days: 30)),
        'exclude': exclude,
        'limit': limit,
      }),
    );
    final ids = [for (final row in rows) row.toColumnMap()['id'] as String];
    if (ids.isNotEmpty) return _inOrder(session, ids, now, shopper);
    final excluded = <UuidValue>{
      for (final id in exclude) UuidValue.fromString(id),
    };
    return Product.db.find(
      session,
      where: (product) {
        var filter = product.active.equals(true) & (product.currentStock > 0);
        if (excluded.isNotEmpty) filter &= product.id.notInSet(excluded);
        return filter;
      },
      orderByList: (product) => [product.createdAt.desc(), product.name.asc()],
      limit: limit,
      include: _include(now, shopper),
    );
  }

  Future<List<String>> _frequentIds(
    Session session,
    UuidValue customerId,
    DateTime now,
    int limit,
  ) async {
    final rows = await session.db.unsafeQuery(
      '''
      SELECT oi."productId"::text AS id
      FROM order_items oi
      JOIN orders o ON o.id = oi."orderId"
      JOIN products p ON p.id = oi."productId"
      WHERE o."customerId" = @customer::uuid
        AND o.status <> 'cancelled'
        AND o."createdAt" >= @since::timestamp
        AND NOT oi."isGift"
        AND p.active
      GROUP BY oi."productId", p.name
      ORDER BY COUNT(DISTINCT o.id) DESC, MAX(o."createdAt") DESC, p.name
      LIMIT @limit
      ''',
      parameters: QueryParameters.named({
        'customer': customerId.toString(),
        'since': now.subtract(const Duration(days: 180)),
        'limit': limit,
      }),
    );
    return [for (final row in rows) row.toColumnMap()['id'] as String];
  }

  /// Los productos de [ids], en ese orden, con el precio de [shopper].
  Future<List<Product>> _inOrder(
    Session session,
    List<String> ids,
    DateTime now,
    Shopper shopper,
  ) async {
    if (ids.isEmpty) return const [];
    final found = await Product.db.find(
      session,
      where: (product) => product.id.inSet(<UuidValue>{
        for (final id in ids) UuidValue.fromString(id),
      }),
      include: _include(now, shopper),
    );
    final byId = {for (final product in found) product.id.toString(): product};
    return [for (final id in ids) ?byId[id]];
  }

  /// Un producto inactivo solo lo ven admin y staff ([includeInactive]).
  Future<Product> get(
    Session session,
    UuidValue id, {
    Shopper shopper = Shopper.anonymous,
    bool includeInactive = false,
  }) async {
    final product = await Product.db.findById(
      session,
      id,
      include: _include(_now().toUtc(), shopper),
    );
    if (product == null || (!product.active && !includeInactive)) {
      throw const ApiException(404, _notFound);
    }
    return product;
  }

  Future<Product> create(Session session, Product product) async {
    await _assertCategoryExists(session, product.categoryId);
    await _assertSkuIsFree(session, product.sku);
    final created = await _write(
      product.sku,
      () => Product.db.insertRow(session, product),
    );
    return get(session, created.id!, includeInactive: true);
  }

  /// Aplica [changes] al producto actual. El stock no se edita aquí: los
  /// cambios de stock pasan por inventory, que registra el movimiento.
  Future<Product> update(
    Session session,
    UuidValue id,
    Product Function(Product current) changes,
  ) async {
    final current = await get(session, id, includeInactive: true);
    final updated = changes(current).copyWith(
      currentStock: current.currentStock,
    );
    if (updated.categoryId != current.categoryId) {
      await _assertCategoryExists(session, updated.categoryId);
    }
    if (updated.sku != current.sku) {
      await _assertSkuIsFree(session, updated.sku);
    }
    await _write(updated.sku, () => Product.db.updateRow(session, updated));
    if (updated.imageUrl != current.imageUrl) {
      await _images.delete(session, current.imageUrl);
    }
    return get(session, id, includeInactive: true);
  }

  /// Le pone al producto [id] la foto [jpeg], ya procesada con
  /// [ProductImages.process]; la que tenía se borra si era una subida.
  Future<Product> setImage(
    Session session,
    UuidValue id,
    Uint8List jpeg,
  ) async {
    // Que exista (o 404) antes de guardar nada.
    await get(session, id, includeInactive: true);
    final url = await _images.store(session, id, jpeg);
    try {
      return await update(
        session,
        id,
        (product) => product.copyWith(imageUrl: url),
      );
    } catch (_) {
      await _images.delete(session, url);
      rethrow;
    }
  }

  /// La foto subida [file] del producto [productId] (JPEG), o null si no
  /// existe.
  Future<Uint8List?> image(Session session, String productId, String file) =>
      _images.read(session, productId, file);

  /// Baja lógica (active = false). No se borra porque los pedidos, los
  /// movimientos de inventario y las promociones lo referencian.
  Future<Product> deactivate(Session session, UuidValue id) =>
      update(session, id, (product) => product.copyWith(active: false));

  Future<void> _assertCategoryExists(Session session, UuidValue id) async {
    if (await Category.db.findById(session, id) == null) {
      throw const ApiException.badRequest('La categoría indicada no existe');
    }
  }

  Future<void> _assertSkuIsFree(Session session, String sku) async {
    final existing = await Product.db.findFirstRow(
      session,
      where: (product) => product.sku.equals(sku),
    );
    if (existing != null) throw _skuTaken(sku);
  }

  /// Escribe, traduciendo las carreras que las validaciones previas no ven.
  Future<Product> _write(String sku, Future<Product> Function() write) async {
    try {
      return await write();
    } on DatabaseUniqueViolationException {
      throw _skuTaken(sku);
    } on DatabaseForeignKeyViolationException {
      throw const ApiException.badRequest('La categoría indicada no existe');
    }
  }

  static ApiException _skuTaken(String sku) =>
      ApiException.conflict('Ya existe un producto con el SKU $sku');

  ProductInclude _include(DateTime now, Shopper shopper) => Product.include(
    category: Category.include(),
    promotions: _pricing.eligibleFor(now, shopper),
  );

  static const _notFound = 'Producto no encontrado';
}
