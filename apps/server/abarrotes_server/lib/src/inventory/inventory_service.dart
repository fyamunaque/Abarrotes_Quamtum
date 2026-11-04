// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:serverpod/serverpod.dart' hide Order;

import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/pagination.dart';
import '../common/store_time.dart';
import '../generated/protocol.dart';

/// Un movimiento por registrar, tal como llega del dashboard. En entradas y
/// salidas [quantity] es positiva; en un ajuste es la corrección con signo.
typedef MovementInput = ({
  UuidValue productId,
  MovementType type,
  int quantity,
  String? reason,
});

/// De dónde sale un movimiento: de un pedido (su salida o, si se canceló, su
/// devolución) o registrado a mano en el panel.
enum MovementOrigin { orders, manual }

/// Movimientos de stock: la única forma de cambiar el currentStock de un
/// producto fuera de los pedidos.
class InventoryService {
  const InventoryService();

  /// Registra el movimiento y actualiza el stock en una sola transacción. La
  /// fila del producto queda bloqueada hasta el final, así dos movimientos
  /// simultáneos no leen el mismo stock. Devuelve el movimiento con su
  /// usuario y el producto ya con el stock nuevo.
  ///
  /// Con [transaction], el movimiento forma parte de esa transacción (p. ej.
  /// la de cancelar un pedido) en vez de abrir una propia. [orderId], el
  /// pedido que lo origina (su salida o su devolución).
  Future<InventoryMovement> record(
    Session session,
    MovementInput input, {
    required User by,
    UuidValue? orderId,
    Transaction? transaction,
  }) {
    if (transaction != null) {
      return _record(session, input, by, orderId, transaction);
    }
    return session.db.transaction(
      (transaction) => _record(session, input, by, orderId, transaction),
    );
  }

  Future<InventoryMovement> _record(
    Session session,
    MovementInput input,
    User by,
    UuidValue? orderId,
    Transaction transaction,
  ) async {
    final product = await Product.db.findById(
      session,
      input.productId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (product == null) {
      throw const ApiException.badRequest('El producto indicado no existe');
    }

    final stock = product.currentStock + _delta(input);
    if (stock < 0) {
      throw ApiException.conflict(
        'Stock insuficiente: ${product.name} tiene ${product.currentStock} '
        'unidad${product.currentStock == 1 ? '' : 'es'}',
      );
    }
    await Product.db.updateRow(
      session,
      product.copyWith(currentStock: stock),
      columns: (product) => [product.currentStock],
      transaction: transaction,
    );
    final movement = await InventoryMovement.db.insertRow(
      session,
      InventoryMovement(
        type: input.type,
        quantity: input.quantity,
        reason: input.reason,
        productId: product.id!,
        userId: by.id!,
        orderId: orderId,
      ),
      transaction: transaction,
    );
    return movement.copyWith(
      product: product.copyWith(currentStock: stock),
      user: by,
    );
  }

  /// Historial de movimientos, del más reciente al más antiguo. Con
  /// [productId], solo los de ese producto (404 si no existe); con
  /// [origin], solo los de pedidos o los manuales; con [categoryId], los de
  /// sus productos. [search] busca en el nombre o el SKU del producto y, si
  /// es un número, también el N.º del pedido. [from] y [to] son días de la
  /// tienda (hora de Lima), ambos incluidos.
  Future<(List<InventoryMovement>, int)> list(
    Session session,
    PageQuery page, {
    UuidValue? productId,
    MovementOrigin? origin,
    UuidValue? categoryId,
    String? search,
    String? from,
    String? to,
  }) async {
    if (productId != null &&
        await Product.db.findById(session, productId) == null) {
      throw const ApiException(404, 'Producto no encontrado');
    }
    if (from != null && to != null && from.compareTo(to) > 0) {
      throw const ApiException.badRequest('from no puede ser posterior a to');
    }
    final number = search == null ? null : int.tryParse(search);

    Expression where(InventoryMovementTable movement) {
      Expression filter = Constant.bool(true);
      if (productId != null) filter &= movement.productId.equals(productId);
      switch (origin) {
        case MovementOrigin.orders:
          filter &= movement.orderId.notEquals(null);
        case MovementOrigin.manual:
          filter &= movement.orderId.equals(null);
        case null:
      }
      if (categoryId != null) {
        filter &= movement.product.categoryId.equals(categoryId);
      }
      if (search != null) {
        final pattern = '%${escapeLike(search)}%';
        Expression matches =
            movement.product.name.ilike(pattern) |
            movement.product.sku.ilike(pattern);
        if (number != null) matches |= movement.order.number.equals(number);
        filter &= matches;
      }
      if (from != null) filter &= movement.createdAt >= storeDayStart(from);
      if (to != null) {
        filter &= movement.createdAt < storeDayStart(addDays(to, 1));
      }
      return filter;
    }

    final movements = await InventoryMovement.db.find(
      session,
      where: where,
      // Un pedido registra todas sus salidas a la vez: el id desempata para
      // que la paginación no repita ni salte movimientos con la misma fecha.
      orderByList: (movement) => [
        movement.createdAt.desc(),
        movement.id.desc(),
      ],
      limit: page.limit,
      offset: page.offset,
      include: InventoryMovement.include(
        product: Product.include(),
        user: User.include(),
        order: Order.include(),
      ),
    );
    final total = await InventoryMovement.db.count(session, where: where);
    return (movements, total);
  }

  /// Cuánto cambia el stock: entra, sale, o la corrección del ajuste.
  static int _delta(MovementInput input) => switch (input.type) {
    MovementType.incoming => input.quantity,
    MovementType.outgoing => -input.quantity,
    MovementType.adjustment => input.quantity,
  };
}
