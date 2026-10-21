// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:serverpod/serverpod.dart' hide Order;

import '../common/http_json.dart';
import '../common/pagination.dart';
import '../common/shopper.dart';
import '../common/store_time.dart';
import '../generated/protocol.dart';
import '../inventory/inventory_service.dart';
import '../promotions/promotion_pricing.dart';
import 'states/order_states.dart';

/// Una línea del pedido tal como la manda el cliente. Los precios los pone el
/// servidor: [shownUnitPriceCents] es el que mostraba el carrito, y solo se
/// compara (nunca se cobra).
typedef OrderLineInput = ({
  UuidValue productId,
  int quantity,
  int? shownUnitPriceCents,
});

/// Un producto que se cobra distinto de lo que mostraba el carrito.
typedef PriceChange = ({
  UuidValue productId,
  String name,
  int shownUnitPriceCents,
  int unitPriceCents,
});

/// El pedido creado y los precios que cambiaron respecto del carrito.
typedef PlacedOrder = ({Order order, List<PriceChange> priceChanges});

/// Pedidos: los del cliente (crear y ver los suyos) y los del dashboard
/// (listado y cambios de estado).
class OrdersService {
  OrdersService({
    required this._pricing,
    this._inventory = const InventoryService(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PromotionPricing _pricing;
  final InventoryService _inventory;
  final DateTime Function() _now;

  /// Crea el pedido de [customer] en `pendingConfirmation` y descuenta el
  /// stock, todo en una transacción: si un producto no está disponible o no
  /// alcanza, no se guarda nada.
  ///
  /// Cobra por producto la mejor promoción vigente que [shopper] puede usar
  /// (la más barata) o, si no hay, el precio normal. Si el carrito mostraba
  /// otro precio, va en `priceChanges`. Las líneas del mismo producto se
  /// juntan. Cada salida queda en el historial de inventario a nombre del
  /// cliente.
  ///
  /// Los productos se bloquean (FOR UPDATE) al leerlos, en orden por id y
  /// antes de escribir nada: dos pedidos a la vez se ordenan ahí. Si se
  /// bloquearan recién al descontar el stock, cada uno ya tendría la fila
  /// tomada por la clave foránea de sus líneas y se trabarían (deadlock).
  Future<PlacedOrder> create(
    Session session, {
    required User customer,
    required Shopper shopper,
    required String deliveryAddress,
    required List<OrderLineInput> lines,
  }) {
    final quantities = <UuidValue, int>{};
    final shownPrices = <UuidValue, int>{};
    for (final line in lines) {
      quantities.update(
        line.productId,
        (quantity) => quantity + line.quantity,
        ifAbsent: () => line.quantity,
      );
      if (line.shownUnitPriceCents case final shown?) {
        shownPrices.putIfAbsent(line.productId, () => shown);
      }
    }
    final productIds = quantities.keys.toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()));

    return session.db.transaction((transaction) async {
      final now = _now().toUtc();
      final products = {
        for (final product in await Product.db.find(
          session,
          where: (product) => product.id.inSet(productIds.toSet()),
          orderBy: (product) => product.id,
          include: Product.include(
            promotions: _pricing.bestFor(now, shopper),
          ),
          lockMode: LockMode.forUpdate,
          transaction: transaction,
        ))
          product.id!: product,
      };

      // Inexistentes (por id) o dados de baja (por nombre).
      final unavailable = [
        for (final id in productIds)
          if (products[id]?.active != true) products[id]?.name ?? id.toString(),
      ];
      if (unavailable.isNotEmpty) {
        throw ApiException.badRequest(
          'Ya no están disponibles: ${unavailable.join(', ')}',
        );
      }

      int unitPrice(Product product) =>
          product.promotions?.firstOrNull?.promoPriceCents ??
          product.priceCents;
      final total = productIds.fold<int>(
        0,
        (sum, id) => sum + unitPrice(products[id]!) * quantities[id]!,
      );
      final priceChanges = [
        for (final id in productIds)
          if (shownPrices[id] case final shown?
              when shown != unitPrice(products[id]!))
            (
              productId: id,
              name: products[id]!.name,
              shownUnitPriceCents: shown,
              unitPriceCents: unitPrice(products[id]!),
            ),
      ];

      final order = await Order.db.insertRow(
        session,
        Order(
          status: OrderStatus.pendingConfirmation,
          totalCents: total,
          deliveryAddress: deliveryAddress,
          createdAt: now,
          updatedAt: now,
          customerId: customer.id!,
        ),
        transaction: transaction,
      );
      await OrderItem.db.insert(session, [
        for (final id in productIds)
          OrderItem(
            quantity: quantities[id]!,
            unitPriceCents: unitPrice(products[id]!),
            orderId: order.id!,
            productId: id,
          ),
      ], transaction: transaction);

      // Si un producto no alcanza, inventory responde 409 y la transacción
      // deshace también el pedido.
      for (final id in productIds) {
        await _inventory.record(
          session,
          (
            productId: id,
            type: MovementType.outgoing,
            quantity: quantities[id]!,
            reason: 'Pedido ${order.id}',
          ),
          by: customer,
          transaction: transaction,
        );
      }

      final placed = await Order.db.findById(
        session,
        order.id!,
        include: _customerInclude,
        transaction: transaction,
      );
      return (order: placed!, priceChanges: priceChanges);
    });
  }

  /// Los pedidos de [customer], paginados, los más recientes primero.
  Future<(List<Order>, int)> mine(
    Session session,
    User customer,
    PageQuery page,
  ) async {
    Expression where(OrderTable order) => order.customerId.equals(customer.id!);

    final orders = await Order.db.find(
      session,
      where: where,
      orderByList: (order) => [order.createdAt.desc(), order.id.desc()],
      limit: page.limit,
      offset: page.offset,
      include: _customerInclude,
    );
    final total = await Order.db.count(session, where: where);
    return (orders, total);
  }

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

  /// Para el cliente: las líneas con su producto.
  static final _customerInclude = Order.include(
    items: OrderItem.includeList(
      orderBy: (item) => item.id,
      include: OrderItem.include(product: Product.include()),
    ),
  );

  /// Para el dashboard: además, quién hizo el pedido.
  static final _include = Order.include(
    customer: User.include(),
    items: OrderItem.includeList(
      orderBy: (item) => item.id,
      include: OrderItem.include(product: Product.include()),
    ),
  );
}
