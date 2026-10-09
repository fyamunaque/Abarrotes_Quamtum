import '../common/money.dart';
import 'order_status.dart';

/// Un pedido de la cuenta, como lo manda el servidor (`orderJson` en
/// apps/server). Montos en céntimos.
class Order {
  const Order({
    required this.id,
    required this.status,
    required this.totalCents,
    required this.deliveryAddress,
    required this.createdAt,
    required this.lines,
    this.priceChanges = const [],
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
  final int totalCents;
  final String deliveryAddress;
  final DateTime createdAt;
  final List<OrderLine> lines;

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
