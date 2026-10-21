import '../common/money.dart';
import 'fulfillment.dart';
import 'order_status.dart';

/// Un pedido de la cuenta, como lo manda el servidor (`orderJson` en
/// apps/server). Montos en céntimos.
class Order {
  const Order({
    required this.id,
    required this.status,
    required this.totalCents,
    required this.createdAt,
    required this.lines,
    this.fulfillmentType = FulfillmentType.delivery,
    this.deliveryAddress,
    this.pickupCode,
    this.readyForPickupAt,
    this.allowedNextStatuses = const [],
    this.priceChanges = const [],
  });

  /// Lanza [FormatException] si [json] no tiene la forma de un pedido.
  factory Order.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'status': final String status,
      'total': final String total,
      'createdAt': final String createdAt,
      'items': final List<Object?> items,
    }) {
      final statuses = OrderStatus.values.asNameMap();
      return Order(
        id: id,
        status:
            statuses[status] ??
            (throw FormatException('Estado desconocido', status)),
        // Sin el campo (un servidor anterior), a domicilio.
        fulfillmentType: switch (json['fulfillmentType']) {
          final String type =>
            FulfillmentType.values.asNameMap()[type] ??
                (throw FormatException('Tipo de entrega desconocido', type)),
          _ => FulfillmentType.delivery,
        },
        totalCents: parseCents(total),
        deliveryAddress: json['deliveryAddress'] as String?,
        pickupCode: json['pickupCode'] as String?,
        readyForPickupAt: switch (json['readyForPickupAt']) {
          final String at => DateTime.parse(at),
          _ => null,
        },
        createdAt: DateTime.parse(createdAt),
        lines: [for (final item in items) OrderLine.fromJson(item)],
        // Los que esta versión de la app no conoce, no se ofrecen.
        allowedNextStatuses: switch (json['allowedNextStatuses']) {
          final List<Object?> names => [
            for (final name in names) ?statuses[name],
          ],
          _ => const [],
        },
        // Solo al crearlo: lo que se cobró distinto de lo que mostraba el
        // carrito.
        priceChanges: switch (json['priceChanges']) {
          final List<Object?> changes => [
            for (final change in changes) PriceChange.fromJson(change),
          ],
          _ => const [],
        },
      );
    }
    throw FormatException('No es un pedido', json);
  }

  final String id;
  final OrderStatus status;
  final FulfillmentType fulfillmentType;
  final int totalCents;

  /// Solo a domicilio.
  final String? deliveryAddress;

  /// Solo en recojo: el código que el cliente muestra en caja. Lo reciben el
  /// dueño del pedido y el personal que ve los pedidos.
  final String? pickupCode;

  /// Cuándo quedó listo para recoger.
  final DateTime? readyForPickupAt;

  final DateTime createdAt;
  final List<OrderLine> lines;

  /// A qué estados puede pasar, según el flujo de su tipo de entrega. Lo
  /// calcula el servidor: el panel arma sus botones con esto.
  final List<OrderStatus> allowedNextStatuses;

  /// El estado como lo lee la persona ("Recogido" en recojo).
  String get statusLabel => fulfillmentType.labelOf(status);

  /// Los productos que se cobraron a otro precio que el del carrito (p. ej.
  /// terminó una promoción). Solo viene al crear el pedido.
  final List<PriceChange> priceChanges;
}

/// Un producto que se cobró distinto de lo que mostraba el carrito.
class PriceChange {
  const PriceChange({
    required this.productId,
    required this.name,
    required this.shownUnitPriceCents,
    required this.unitPriceCents,
  });

  factory PriceChange.fromJson(Object? json) => switch (json) {
    {
      'productId': final String productId,
      'name': final String name,
      'shownUnitPrice': final String shown,
      'unitPrice': final String unitPrice,
    } =>
      PriceChange(
        productId: productId,
        name: name,
        shownUnitPriceCents: parseCents(shown),
        unitPriceCents: parseCents(unitPrice),
      ),
    _ => throw FormatException('No es un cambio de precio', json),
  };

  final String productId;
  final String name;
  final int shownUnitPriceCents;
  final int unitPriceCents;
}

/// Una línea del pedido, con el precio que se cobró.
class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPriceCents,
  });

  factory OrderLine.fromJson(Object? json) => switch (json) {
    {
      'productId': final String productId,
      'quantity': final int quantity,
      'unitPrice': final String unitPrice,
      'product': {'name': final String name},
    } =>
      OrderLine(
        productId: productId,
        name: name,
        quantity: quantity,
        unitPriceCents: parseCents(unitPrice),
      ),
    _ => throw FormatException('No es una línea de pedido', json),
  };

  final String productId;
  final String name;
  final int quantity;
  final int unitPriceCents;

  int get totalCents => unitPriceCents * quantity;
}
