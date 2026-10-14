import '../../generated/protocol.dart';
import '../fulfillment/fulfillment_flow.dart';

/// Patrón State: cada estado del pedido es una clase. A qué estados puede
/// pasar lo decide el flujo de su tipo de entrega ([flow], un Strategy de
/// `fulfillment/`), que recibe por constructor; cada estado suma lo suyo al
/// salir ([exitProblem]) o al entrar ([onEnter]). No guardan datos del
/// pedido ni hacen E/S: el servicio los consulta dentro de su transacción.
abstract class OrderStateHandler {
  const OrderStateHandler(this.flow);

  final FulfillmentFlow flow;

  OrderStatus get status;

  /// Estados a los que puede avanzar; vacío si es un estado final.
  List<OrderStatus> get nextStatuses => flow.allowedNext(status);

  bool canTransitionTo(OrderStatus next) => nextStatuses.contains(next);

  /// Por qué no puede pasar a [next], en palabras de la tienda (para el 400).
  String rejectionReason(OrderStatus next) {
    final current = flow.labelOf(status);
    if (next == status) return 'El pedido ya está $current';
    if (nextStatuses.isEmpty) {
      return 'Un pedido $current ya no puede cambiar de estado';
    }
    if (!flow.passesThrough(next)) {
      return 'Un pedido ${flow.description} no puede pasar a '
          '${flow.labelOf(next)}: ${flow.otherStepsNote}';
    }
    final options = nextStatuses.map(flow.labelOf).join(' o ');
    return 'Un pedido $current no puede pasar a ${flow.labelOf(next)}: '
        'solo puede pasar a $options';
  }

  /// Lo que impide salir de este estado hacia [next] aunque el flujo lo
  /// permita (p. ej. entregar un pedido de recojo sin su código), o null si
  /// puede.
  String? exitProblem(Order order, OrderStatus next, {String? pickupCode}) =>
      null;

  /// [order] al entrar a este estado, con lo que el estado guarda (p. ej.
  /// cuándo quedó listo para recoger).
  Order onEnter(Order order, DateTime now) => order;
}
