import 'package:serverpod/serverpod.dart';

import '../common/http_json.dart';
import '../common/pagination.dart';
import '../generated/protocol.dart';

/// Un movimiento por registrar, tal como llega del dashboard. En entradas y
/// salidas [quantity] es positiva; en un ajuste es la corrección con signo.
typedef MovementInput = ({
  UuidValue productId,
  MovementType type,
  int quantity,
  String? reason,
});

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
  /// la de cancelar un pedido) en vez de abrir una propia.
  Future<InventoryMovement> record(
    Session session,
    MovementInput input, {
    required User by,
    Transaction? transaction,
  }) {
    if (transaction != null) return _record(session, input, by, transaction);
    return session.db.transaction(
      (transaction) => _record(session, input, by, transaction),
    );
  }

  Future<InventoryMovement> _record(
    Session session,
    MovementInput input,
    User by,
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
      ),
      transaction: transaction,
    );
    return movement.copyWith(
      product: product.copyWith(currentStock: stock),
      user: by,
    );
  }

  /// Historial de movimientos, del más reciente al más antiguo. Con
  /// [productId], solo los de ese producto (404 si no existe).
  Future<(List<InventoryMovement>, int)> list(
    Session session,
    PageQuery page, {
    UuidValue? productId,
  }) async {
    if (productId != null &&
        await Product.db.findById(session, productId) == null) {
      throw const ApiException(404, 'Producto no encontrado');
    }

    Expression where(InventoryMovementTable movement) => productId == null
        ? Constant.bool(true)
        : movement.productId.equals(productId);

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
