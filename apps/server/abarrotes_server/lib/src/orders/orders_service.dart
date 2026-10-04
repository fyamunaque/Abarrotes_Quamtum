// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:serverpod/serverpod.dart' hide Order;

import '../common/http_json.dart';
import '../common/pagination.dart';
import '../common/store_time.dart';
import '../generated/protocol.dart';
import '../inventory/inventory_service.dart';
import 'states/order_states.dart';

/// Pedidos vistos desde el dashboard: listado y cambios de estado.
class OrdersService {
  OrdersService({
    this._inventory = const InventoryService(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final InventoryService _inventory;
  final DateTime Function() _now;

  /// Paginado, los más recientes primero. [from] y [to] son días de la tienda
  /// (hora de Lima), ambos incluidos; cualquiera puede faltar.
  Future<(List<Order>, int)> list(
    Session session,
    PageQuery page, {
    OrderStatus? status,
    String? from,
    String? to,
  }) async {
    if (from != null && to != null && from.compareTo(to) > 0) {
      throw const ApiException.badRequest('from no puede ser posterior a to');
    }
    Expression where(OrderTable order) {
      Expression filter = Constant.bool(true);
      if (status != null) filter &= order.status.equals(status);
      if (from != null) filter &= order.createdAt >= storeDayStart(from);
      if (to != null) {
        filter &= order.createdAt < storeDayStart(addDays(to, 1));
      }
      return filter;
    }

    final orders = await Order.db.find(
      session,
      where: where,
      orderByList: (order) => [order.createdAt.desc(), order.id.desc()],
      limit: page.limit,
      offset: page.offset,
      include: _include,
    );
    final total = await Order.db.count(session, where: where);
    return (orders, total);
  }

  /// Cambia el estado si el estado actual lo permite (patrón State, ver
  /// states/). Al cancelar, devuelve al inventario el stock que descontó el
  /// pedido, a nombre de [by]. Todo pasa en una transacción con la fila del
  /// pedido bloqueada: si dos personas lo cambian a la vez, la segunda espera
  /// y se valida contra el estado ya cambiado (así el stock nunca se devuelve
  /// dos veces).
  Future<Order> changeStatus(
    Session session,
    UuidValue id,
    OrderStatus next, {
    required User by,
  }) {
    return session.db.transaction((transaction) async {
      final order = await Order.db.findById(
        session,
        id,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (order == null) {
        throw const ApiException(404, 'Pedido no encontrado');
      }

      final current = orderStateOf(order.status);
      if (!current.canTransitionTo(next)) {
        throw ApiException.badRequest(current.rejectionReason(next));
      }

      await Order.db.updateRow(
        session,
        order.copyWith(status: next, updatedAt: _now().toUtc()),
        columns: (order) => [order.status, order.updatedAt],
        transaction: transaction,
      );
      if (next == OrderStatus.cancelled) {
        await _returnStock(session, order, by, transaction);
      }

      return (await Order.db.findById(
        session,
        id,
        include: _include,
        transaction: transaction,
      ))!;
    });
  }

  /// Una entrada de inventario por cada línea del pedido. Van por producto en
  /// orden fijo para que dos cancelaciones simultáneas bloqueen las filas en
  /// el mismo orden y no se traben.
  Future<void> _returnStock(
    Session session,
    Order order,
    User by,
    Transaction transaction,
  ) async {
    final items = await OrderItem.db.find(
      session,
      where: (item) => item.orderId.equals(order.id),
      orderBy: (item) => item.productId,
      transaction: transaction,
    );
    for (final item in items) {
      await _inventory.record(
        session,
        (
          productId: item.productId,
          type: MovementType.incoming,
          quantity: item.quantity,
          reason: 'Cancelación del pedido ${order.id}',
        ),
        by: by,
        transaction: transaction,
      );
    }
  }

  /// Para el dashboard: las líneas con su producto y quién hizo el pedido.
  static final _include = Order.include(
    customer: User.include(),
    items: OrderItem.includeList(
      orderBy: (item) => item.id,
      include: OrderItem.include(product: Product.include()),
    ),
  );
}
