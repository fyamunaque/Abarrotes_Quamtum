import 'package:serverpod/serverpod.dart';

import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/pagination.dart';
import '../generated/protocol.dart';
import '../promotions/promotion_rules.dart';

/// Productos del catálogo. Cada producto se devuelve con su categoría y su
/// promoción vigente: como las promociones encendidas de un producto no se
/// cruzan en el tiempo, hay a lo sumo una (en `promotions`).
class ProductsService {
  ProductsService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// Por nombre. [includeInactive] es solo para admin y staff: decide la ruta.
  Future<(List<Product>, int)> list(
    Session session,
    PageQuery page, {
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
          (promotion) => activePromotionWhere(promotion, now),
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
      include: _include(now),
    );
    final total = await Product.db.count(session, where: where);
    return (products, total);
  }

  /// Un producto inactivo solo lo ven admin y staff ([includeInactive]).
  Future<Product> get(
    Session session,
    UuidValue id, {
    bool includeInactive = false,
  }) async {
    final product = await Product.db.findById(
      session,
      id,
      include: _include(_now().toUtc()),
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
    return get(session, id, includeInactive: true);
  }

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

  static ProductInclude _include(DateTime now) => Product.include(
    category: Category.include(),
    promotions: Promotion.includeList(
      where: (promotion) => activePromotionWhere(promotion, now),
      limit: 1,
    ),
  );

  static const _notFound = 'Producto no encontrado';
}
