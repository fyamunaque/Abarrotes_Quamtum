/// Estados de un pedido, con los nombres del servidor (`OrderStatus` en
/// apps/server) y los textos de la web.
enum OrderStatus {
  pendingConfirmation('Pendiente de confirmación', 'Pendiente'),
  confirmed('Confirmado', 'Confirmado'),
  outForDelivery('En camino', 'En camino'),
  delivered('Entregado', 'Entregado'),
  cancelled('Cancelado', 'Cancelado');

  const OrderStatus(this.label, this.stepLabel);

  final String label;

  /// El texto corto bajo cada paso del seguimiento.
  final String stepLabel;

  /// Los pasos del seguimiento, en orden. Cancelado no es un paso: corta el
  /// camino en cualquier punto antes de la entrega.
  static const steps = [
    pendingConfirmation,
    confirmed,
    outForDelivery,
    delivered,
  ];
}
