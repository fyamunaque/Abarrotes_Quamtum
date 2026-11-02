// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:serverpod/serverpod.dart' hide Order;

import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/pagination.dart';
import '../common/shopper.dart';
import '../common/store_time.dart';
import '../generated/protocol.dart' hide AuditLogRepository;
import '../inventory/inventory_service.dart';
import '../promotions/promotion_engine.dart';
import '../promotions/promotion_pricing.dart';
import '../staff/audit_log_repository.dart';
import 'order_number.dart';
import 'order_status_notifier.dart';
import 'pickup_code.dart';
import 'states/order_states.dart';

/// Una línea del pedido tal como la manda el cliente. Los precios los pone el
/// servidor: [shownUnitPriceCents] es el que mostraba el carrito, y solo se
/// compara (nunca se cobra).
typedef OrderLineInput = ({
  UuidValue productId,
  int quantity,
  int? shownUnitPriceCents,
  int? shownLineTotalCents,
});

/// Un producto que se cobra distinto de lo que mostraba el carrito: por el
/// total de su línea (si el carrito lo mandó) o por el precio unitario
/// (las apps de antes).
typedef PriceChange = ({
  UuidValue productId,
  String name,
  int? shownUnitPriceCents,
  int? unitPriceCents,
  int? shownLineTotalCents,
  int? lineTotalCents,
});

/// El pedido creado, los precios que cambiaron respecto del carrito y los
/// avisos del cobro (p. ej. un regalo sin stock).
typedef PlacedOrder = ({
  Order order,
  List<PriceChange> priceChanges,
  List<String> notices,
});

/// En qué va un pedido, para que el cliente filtre los suyos: en curso (ni
/// entregado ni cancelado), entregado (o recogido) o cancelado.
enum OrderProgress { active, delivered, cancelled }

const _finished = {OrderStatus.delivered, OrderStatus.cancelled};

/// Pedidos: los del cliente (crear y ver los suyos) y los del dashboard
/// (listado y cambios de estado). A domicilio o con recojo en tienda: el
/// camino de cada uno lo deciden su flujo y sus estados (`fulfillment/` y
/// `states/`).
class OrdersService {
  OrdersService({
    required this._pricing,
    this._inventory = const InventoryService(),
    this._pickupCode = randomPickupCode,
    this._notifier = const NoOrderStatusNotifier(),
    this._audit = const DbAuditLogRepository(),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PromotionPricing _pricing;
  final InventoryService _inventory;
  final PickupCodeGenerator _pickupCode;
  final OrderStatusNotifier _notifier;

  /// La bitácora del equipo: ahí queda un pedido entregado sin su código.
  final AuditLogRepository _audit;
  final DateTime Function() _now;

  /// Cuántos códigos se prueban antes de rendirse: con mil millones
  /// posibles, el segundo ya casi nunca hace falta.
  static const _codeAttempts = 10;

  /// Crea el pedido de [customer] en `pendingConfirmation` y descuenta el
  /// stock, todo en una transacción: si un producto no está disponible o no
  /// alcanza, no se guarda nada.
  ///
  /// A domicilio lleva [deliveryAddress] (las rutas la exigen); con recojo en
  /// tienda no lleva dirección y se le genera su código, único en la tabla.
  ///
  /// Cobra con las promociones vigentes que [shopper] puede usar
  /// (`PromotionPricing.price`: se acumulan, con regalos a S/ 0). Si el
  /// carrito mostraba otro total de línea (u otro precio unitario, en las
  /// apps de antes), va en `priceChanges`. Las líneas del mismo producto se
  /// juntan. Cada salida, regalos incluidos, queda en el historial de
  /// inventario a nombre del cliente.
  ///
  /// Los productos (los comprados y los de regalo) se bloquean (FOR UPDATE)
  /// al leerlos, en orden por id y
  /// antes de escribir nada: dos pedidos a la vez se ordenan ahí. Si se
  /// bloquearan recién al descontar el stock, cada uno ya tendría la fila
  /// tomada por la clave foránea de sus líneas y se trabarían (deadlock).
  Future<PlacedOrder> create(
    Session session, {
    required User customer,
    required Shopper shopper,
    required FulfillmentType fulfillmentType,
    String? deliveryAddress,
    required List<OrderLineInput> lines,
  }) async {
    final pickup = fulfillmentType == FulfillmentType.pickup;
    if (!pickup && deliveryAddress == null) {
      throw ArgumentError.notNull('deliveryAddress');
    }
    final quantities = <UuidValue, int>{};
    final shownPrices = <UuidValue, int>{};
    final shownLineTotals = <UuidValue, int>{};
    for (final line in lines) {
      quantities.update(
        line.productId,
        (quantity) => quantity + line.quantity,
        ifAbsent: () => line.quantity,
      );
      if (line.shownUnitPriceCents case final shown?) {
        shownPrices.putIfAbsent(line.productId, () => shown);
      }
      if (line.shownLineTotalCents case final shown?) {
        shownLineTotals.putIfAbsent(line.productId, () => shown);
      }
    }
    try {
      return await _create(
        session,
        customer: customer,
        shopper: shopper,
        fulfillmentType: fulfillmentType,
        deliveryAddress: pickup ? null : deliveryAddress,
        quantities: quantities,
        shownPrices: shownPrices,
        shownLineTotals: shownLineTotals,
      );
    } on DatabaseUniqueViolationException {
      // Dos pedidos de recojo sacaron el mismo código a la vez: el índice
      // único de pickupCode deja pasar uno solo.
      throw const ApiException.conflict(
        'No se pudo reservar el código de recojo: vuelve a intentarlo',
      );
    }
  }

  Future<PlacedOrder> _create(
    Session session, {
    required User customer,
    required Shopper shopper,
    required FulfillmentType fulfillmentType,
    required String? deliveryAddress,
    required Map<UuidValue, int> quantities,
    required Map<UuidValue, int> shownPrices,
    required Map<UuidValue, int> shownLineTotals,
  }) {
    final productIds = quantities.keys.toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()));

    return session.db.transaction((transaction) async {
      final now = _now().toUtc();
      final giftIds = await _pricing.giftProductIds(
        session,
        productIds.toSet(),
        shopper,
        transaction: transaction,
      );
      final products = {
        for (final product in await Product.db.find(
          session,
          where: (product) =>
              product.id.inSet(<UuidValue>{...productIds, ...giftIds}),
          orderBy: (product) => product.id,
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

      final cart = await _pricing.price(
        session,
        [
          for (final id in productIds)
            (
              productId: id,
              name: products[id]!.name,
              listUnitPriceCents: products[id]!.priceCents,
              quantity: quantities[id]!,
            ),
        ],
        shopper,
        transaction: transaction,
      );
      final bought = {
        for (final line in cart.lines)
          if (!line.isGift) line.productId: line,
      };
      final priceChanges = <PriceChange>[
        for (final id in productIds)
          if (shownLineTotals[id] case final shown?
              when shown != bought[id]!.lineTotalCents)
            (
              productId: id,
              name: products[id]!.name,
              shownUnitPriceCents: null,
              unitPriceCents: null,
              shownLineTotalCents: shown,
              lineTotalCents: bought[id]!.lineTotalCents,
            )
          else if (shownLineTotals[id] == null)
            if (shownPrices[id] case final shown?
                when shown != bought[id]!.unitPriceCents)
              (
                productId: id,
                name: products[id]!.name,
                shownUnitPriceCents: shown,
                unitPriceCents: bought[id]!.unitPriceCents,
                shownLineTotalCents: null,
                lineTotalCents: null,
              ),
      ];

      final order = await Order.db.insertRow(
        session,
        Order(
          number: await nextOrderNumber(session, transaction),
          status: OrderStatus.pendingConfirmation,
          fulfillmentType: fulfillmentType,
          totalCents: cart.totalCents,
          subtotalCents: cart.subtotalCents,
          discountCents: cart.discountCents,
          deliveryAddress: deliveryAddress,
          pickupCode: fulfillmentType == FulfillmentType.pickup
              ? await _freeCode(session, transaction, (o) => o.pickupCode)
              : null,
          deliveryCode: fulfillmentType == FulfillmentType.delivery
              ? await _freeCode(session, transaction, (o) => o.deliveryCode)
              : null,
          createdAt: now,
          updatedAt: now,
          customerId: customer.id!,
        ),
        transaction: transaction,
      );
      await OrderItem.db.insert(session, [
        for (final line in cart.lines)
          OrderItem(
            quantity: line.quantity,
            unitPriceCents: line.unitPriceCents,
            listUnitPriceCents: line.listUnitPriceCents,
            lineTotalCents: line.lineTotalCents,
            isGift: line.isGift,
            promotions: line.promotions,
            orderId: order.id!,
            productId: line.productId,
          ),
      ], transaction: transaction);

      // Si un producto no alcanza, inventory responde 409 y la transacción
      // deshace también el pedido. Los regalos ya vienen limitados al stock.
      for (final line in cart.lines) {
        await _inventory.record(
          session,
          (
            productId: line.productId,
            type: MovementType.outgoing,
            quantity: line.quantity,
            reason: 'Pedido ${order.id}',
          ),
          by: customer,
          orderId: order.id,
          transaction: transaction,
        );
      }

      final placed = await Order.db.findById(
        session,
        order.id!,
        include: _customerInclude,
        transaction: transaction,
      );
      return (
        order: placed!,
        priceChanges: priceChanges,
        notices: cart.notices,
      );
    });
  }

  /// Cómo se cobraría el carrito [lines] para [shopper], sin guardar nada
  /// ni tocar el stock: lo que muestra el carrito antes de pedir. Los
  /// productos que no existen o están de baja no entran y van en los
  /// avisos. Devuelve también los productos (comprados y de regalo), para
  /// mostrarlos.
  Future<({PricedCart cart, Map<UuidValue, Product> products})> quote(
    Session session, {
    required Shopper shopper,
    required List<({UuidValue productId, int quantity})> lines,
  }) async {
    final quantities = <UuidValue, int>{};
    for (final line in lines) {
      quantities.update(
        line.productId,
        (quantity) => quantity + line.quantity,
        ifAbsent: () => line.quantity,
      );
    }
    final found = {
      for (final product in await Product.db.find(
        session,
        where: (product) => product.id.inSet(quantities.keys.toSet()),
      ))
        product.id!: product,
    };
    final notices = [
      for (final id in quantities.keys)
        if (found[id] case final product? when !product.active)
          'Ya no está disponible: ${product.name}'
        else if (found[id] == null)
          'Uno de los productos ya no existe',
    ];
    final available = [
      for (final MapEntry(key: id, value: quantity) in quantities.entries)
        if (found[id] case final product? when product.active)
          (
            productId: id,
            name: product.name,
            listUnitPriceCents: product.priceCents,
            quantity: quantity,
          ),
    ];
    final priced = await _pricing.price(session, available, shopper);
    final giftIds = {
      for (final line in priced.lines)
        if (line.isGift && !found.containsKey(line.productId)) line.productId,
    };
    final products = {
      ...found,
      if (giftIds.isNotEmpty)
        for (final gift in await Product.db.find(
          session,
          where: (product) => product.id.inSet(giftIds),
        ))
          gift.id!: gift,
    };
    return (
      cart: PricedCart(
        lines: priced.lines,
        notices: [...notices, ...priced.notices],
      ),
      products: products,
    );
  }

  /// Un código (de recojo o de entrega, según [column]) que ningún pedido
  /// tiene todavía en esa columna.
  Future<String> _freeCode(
    Session session,
    Transaction transaction,
    ColumnString Function(OrderTable order) column,
  ) async {
    for (var attempt = 0; attempt < _codeAttempts; attempt++) {
      final code = _pickupCode();
      final taken = await Order.db.count(
        session,
        where: (order) => column(order).equals(code),
        transaction: transaction,
      );
      if (taken == 0) return code;
    }
    throw const ApiException.conflict(
      'No se pudo generar el código del pedido: vuelve a intentarlo',
    );
  }

  /// Los pedidos de [customer], paginados, los más recientes primero. Con
  /// [search], los de ese N.º (si es un número) o con un producto que lo
  /// contiene en el nombre, sin importar mayúsculas; con [progress], los en
  /// curso, los entregados o los cancelados; con [fulfillmentType], los de
  /// ese tipo. [from] y [to] son días de la tienda, ambos incluidos.
  Future<(List<Order>, int)> mine(
    Session session,
    User customer,
    PageQuery page, {
    String? search,
    OrderProgress? progress,
    FulfillmentType? fulfillmentType,
    String? from,
    String? to,
  }) async {
    if (from != null && to != null && from.compareTo(to) > 0) {
      throw const ApiException.badRequest('from no puede ser posterior a to');
    }
    final number = search == null ? null : int.tryParse(search);
    Expression where(OrderTable order) {
      Expression filter = order.customerId.equals(customer.id!);
      filter &= switch (progress) {
        OrderProgress.active => order.status.notInSet(_finished),
        OrderProgress.delivered => order.status.equals(OrderStatus.delivered),
        OrderProgress.cancelled => order.status.equals(OrderStatus.cancelled),
        null => Constant.bool(true),
      };
      if (fulfillmentType != null) {
        filter &= order.fulfillmentType.equals(fulfillmentType);
      }
      if (search != null) {
        final pattern = '%${escapeLike(search)}%';
        Expression matches = order.items.any(
          (item) => item.product.name.ilike(pattern),
        );
        if (number != null) matches |= order.number.equals(number);
        filter &= matches;
      }
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
    FulfillmentType? fulfillmentType,
    String? from,
    String? to,
    int? number,
  }) async {
    if (from != null && to != null && from.compareTo(to) > 0) {
      throw const ApiException.badRequest('from no puede ser posterior a to');
    }
    Expression where(OrderTable order) {
      Expression filter = Constant.bool(true);
      if (status != null) filter &= order.status.equals(status);
      if (fulfillmentType != null) {
        filter &= order.fulfillmentType.equals(fulfillmentType);
      }
      if (from != null) filter &= order.createdAt >= storeDayStart(from);
      if (to != null) {
        filter &= order.createdAt < storeDayStart(addDays(to, 1));
      }
      if (number != null) filter &= order.number.equals(number);
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

  /// Cambia el estado si el flujo del pedido lo permite y el estado actual
  /// deja salir (patrón State con el flujo como Strategy, ver states/ y
  /// fulfillment/): un pedido de recojo o a domicilio se entrega con su
  /// código ([code], el que da el cliente) o, a domicilio, con
  /// [withoutCodeReason] (quien administra la tienda: la ruta lo revisa), que
  /// queda en el pedido y en la bitácora del equipo. El
  /// estado nuevo guarda lo suyo (p. ej. cuándo quedó listo para recoger).
  /// Al cancelar, devuelve al inventario el stock que descontó el pedido, a
  /// nombre de [by]. Todo pasa en una transacción con la fila del pedido
  /// bloqueada: si dos personas lo cambian a la vez, la segunda espera y se
  /// valida contra el estado ya cambiado (así el stock nunca se devuelve dos
  /// veces).
  ///
  /// Ya guardado el cambio, avisa al cliente (ver [OrderStatusNotifier]): sin
  /// esperar, y si el aviso falla, el cambio de estado queda igual.
  Future<Order> changeStatus(
    Session session,
    UuidValue id,
    OrderStatus next, {
    required User by,
    String? code,
    String? withoutCodeReason,
  }) async {
    final changed = await _changeStatus(
      session,
      id,
      next,
      by: by,
      code: code,
      withoutCodeReason: withoutCodeReason,
    );
    try {
      _notifier.statusChanged(changed);
    } on Object catch (error) {
      session.log(
        'No se pudo avisar del pedido ${changed.id}: $error',
        level: LogLevel.warning,
      );
    }
    return changed;
  }

  Future<Order> _changeStatus(
    Session session,
    UuidValue id,
    OrderStatus next, {
    required User by,
    String? code,
    String? withoutCodeReason,
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

      final current = orderStateOfOrder(order);
      if (!current.canTransitionTo(next)) {
        throw ApiException.badRequest(current.rejectionReason(next));
      }
      final withoutCode = withoutCodeReason != null;
      if (withoutCode &&
          (order.fulfillmentType != FulfillmentType.delivery ||
              next != OrderStatus.delivered)) {
        throw const ApiException.badRequest(
          'Sin código solo se entrega un pedido a domicilio',
        );
      }
      if (current.exitProblem(
            order,
            next,
            code: code,
            withoutCode: withoutCode,
          )
          case final problem?) {
        throw ApiException.badRequest(problem);
      }

      final now = _now().toUtc();
      final entered =
          orderStateOf(
            next,
            current.flow,
          ).onEnter(
            order.copyWith(
              status: next,
              updatedAt: now,
              deliveredWithoutCodeReason: withoutCode
                  ? withoutCodeReason
                  : order.deliveredWithoutCodeReason,
            ),
            now,
          );
      await Order.db.updateRow(
        session,
        entered,
        columns: (order) => [
          order.status,
          order.updatedAt,
          order.readyForPickupAt,
          order.deliveredWithoutCodeReason,
        ],
        transaction: transaction,
      );
      if (withoutCode) {
        final customer = await User.db.findById(
          session,
          order.customerId,
          transaction: transaction,
        );
        await _audit.record(
          session,
          action: AuditAction.orderDeliveredWithoutCode,
          actorUserId: by.id,
          targetEmail: customer?.email,
          details: {'order': order.number, 'reason': withoutCodeReason},
          transaction: transaction,
        );
      }
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
        orderId: order.id,
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
