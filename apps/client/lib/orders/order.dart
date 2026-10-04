import '../common/money.dart';
import 'order_status.dart';

/// Un pedido de la cuenta, como lo manda el servidor (el `Order` de
/// packages/shared-types). Montos en céntimos.
class Order {
  const Order({
    required this.id,
    required this.status,
    required this.totalCents,
    required this.deliveryAddress,
    required this.createdAt,
    required this.lines,
  });

  /// Lanza [FormatException] si [json] no tiene la forma de un pedido.
  factory Order.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'status': final String status,
      'total': final String total,
      'deliveryAddress': final String deliveryAddress,
      'createdAt': final String createdAt,
      'items': final List<Object?> items,
    }) {
      return Order(
        id: id,
        status:
            OrderStatus.values.asNameMap()[status] ??
            (throw FormatException('Estado desconocido', status)),
        totalCents: parseCents(total),
        deliveryAddress: deliveryAddress,
        createdAt: DateTime.parse(createdAt),
        lines: [for (final item in items) OrderLine.fromJson(item)],
      );
    }
    throw FormatException('No es un pedido', json);
  }

  final String id;
  final OrderStatus status;
  final int totalCents;
  final String deliveryAddress;
  final DateTime createdAt;
  final List<OrderLine> lines;
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
