/// Estados de un pedido, con los nombres del servidor (`OrderStatus` en
/// apps/server) y los textos de la web.
enum OrderStatus {
  pendingConfirmation(
    'Pendiente de confirmación',
    'Pendiente',
    'Volver a pendiente',
  ),
  confirmed('Confirmado', 'Confirmado', 'Confirmar'),
  outForDelivery('En camino', 'En camino', 'Marcar en camino'),
  delivered('Entregado', 'Entregado', 'Marcar entregado'),
  cancelled('Cancelado', 'Cancelado', 'Cancelar pedido');

  const OrderStatus(this.label, this.stepLabel, this.actionLabel);

  final String label;

  /// El texto corto bajo cada paso del seguimiento.
  final String stepLabel;

  /// El botón que lleva un pedido a este estado (en el panel).
  final String actionLabel;

  /// A qué estados puede pasar, como en el servidor (patrón State en
  /// apps/server/…/orders/states/). Vacío si es final. El servidor valida
  /// igual: esto solo decide qué botones mostrar.
  List<OrderStatus> get nextStatuses => switch (this) {
    pendingConfirmation => const [confirmed, cancelled],
    confirmed => const [outForDelivery, cancelled],
    outForDelivery => const [delivered, cancelled],
    delivered || cancelled => const [],
  };

  /// Los pasos del seguimiento, en orden. Cancelado no es un paso: corta el
  /// camino en cualquier punto antes de la entrega.
  static const steps = [
    pendingConfirmation,
    confirmed,
    outForDelivery,
    delivered,
  ];
}
