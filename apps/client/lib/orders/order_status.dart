/// Estados de un pedido, con los nombres del servidor (`OrderStatus` en
/// apps/server) y los textos de la app. A qué estados puede pasar cada pedido
/// no está aquí: lo manda el servidor en `allowedNextStatuses`, según el
/// flujo de su tipo de entrega.
enum OrderStatus {
  pendingConfirmation(
    'Pendiente de confirmación',
    'Por confirmar',
    'Volver a pendiente',
  ),
  confirmed('Confirmado', 'Confirmado', 'Confirmar'),

  /// Solo recojo en tienda.
  preparing('Preparando', 'Preparando', 'Empezar a preparar'),

  /// Solo recojo en tienda: el cliente ya puede pasar a recogerlo.
  readyForPickup(
    'En espera de recojo',
    'En espera de recojo',
    'Listo para recoger',
  ),

  /// Solo a domicilio.
  outForDelivery('En camino', 'En camino', 'Marcar en camino'),
  delivered('Entregado', 'Entregado', 'Marcar entregado'),
  cancelled('Cancelado', 'Cancelado', 'Cancelar pedido');

  const OrderStatus(this.label, this.stepLabel, this.actionLabel);

  final String label;

  /// El texto corto bajo cada paso del seguimiento.
  final String stepLabel;

  /// El botón que lleva un pedido a este estado (en el panel).
  final String actionLabel;
}
