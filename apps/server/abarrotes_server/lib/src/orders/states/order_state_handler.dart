import '../../generated/protocol.dart';

/// Patrón State: cada estado del pedido es una clase que sabe a qué estados
/// puede pasar. Para cambiar el flujo se toca solo la clase del estado
/// afectado, sin un switch central de transiciones. Los handlers no guardan
/// datos del pedido, así que son constantes.
abstract class OrderStateHandler {
  const OrderStateHandler();

  OrderStatus get status;

  /// Estados a los que puede avanzar; vacío si es un estado final.
  List<OrderStatus> get nextStatuses;

  bool canTransitionTo(OrderStatus next) => nextStatuses.contains(next);

  /// Por qué no puede pasar a [next], en palabras de la tienda (para el 400).
  String rejectionReason(OrderStatus next) {
    final current = orderStatusLabel(status);
    if (next == status) return 'El pedido ya está $current';
    if (nextStatuses.isEmpty) {
      return 'Un pedido $current ya no puede cambiar de estado';
    }
    final options = nextStatuses.map(orderStatusLabel).join(' o ');
    return 'Un pedido $current no puede pasar a ${orderStatusLabel(next)}: '
        'solo puede pasar a $options';
  }
}

/// Nombre de cada estado en los mensajes de error.
String orderStatusLabel(OrderStatus status) => switch (status) {
  OrderStatus.pendingConfirmation => 'pendiente de confirmación',
  OrderStatus.confirmed => 'confirmado',
  OrderStatus.outForDelivery => 'en camino',
  OrderStatus.delivered => 'entregado',
  OrderStatus.cancelled => 'cancelado',
};
