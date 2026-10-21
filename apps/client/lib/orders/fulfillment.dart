import 'order_status.dart';

/// Cómo llega un pedido al cliente, con los nombres del servidor
/// (`FulfillmentType` en apps/server). Los pasos son solo para dibujar el
/// seguimiento: a qué estado puede pasar un pedido lo dice el servidor
/// (`Order.allowedNextStatuses`).
enum FulfillmentType {
  delivery('A domicilio', [
    OrderStatus.pendingConfirmation,
    OrderStatus.confirmed,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ]),
  pickup('Recojo en tienda', [
    OrderStatus.pendingConfirmation,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.readyForPickup,
    OrderStatus.delivered,
  ]);

  const FulfillmentType(this.label, this.steps);

  final String label;

  /// Los pasos del seguimiento, en orden. Cancelado no es un paso: corta el
  /// camino en cualquier punto antes de la entrega.
  final List<OrderStatus> steps;

  /// En recojo, un pedido entregado es uno que el cliente recogió.
  bool _picked(OrderStatus status) =>
      this == pickup && status == OrderStatus.delivered;

  String labelOf(OrderStatus status) =>
      _picked(status) ? 'Recogido' : status.label;

  String stepLabelOf(OrderStatus status) =>
      _picked(status) ? 'Recogido' : status.stepLabel;

  String actionLabelOf(OrderStatus status) =>
      _picked(status) ? 'Marcar recogido' : status.actionLabel;
}
