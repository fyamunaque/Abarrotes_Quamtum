import '../../generated/protocol.dart';
import 'delivery_flow.dart';
import 'pickup_flow.dart';

/// Patrón Strategy: el camino de un pedido según cómo llega al cliente. Cada
/// tipo de entrega define sus pasos y, con ellos, a qué estados puede pasar
/// un pedido. Los estados (`states/`) le preguntan al flujo en vez de tener
/// las transiciones fijas, y las rutas mandan [allowedNext] a las apps: así
/// ningún frontend las escribe a mano.
abstract class FulfillmentFlow {
  const FulfillmentFlow();

  FulfillmentType get type;

  /// Los pasos en orden, del primero (pendiente) al último (entregado).
  /// Cancelado no es un paso: corta el camino antes de la entrega.
  List<OrderStatus> get steps;

  /// Cómo se llama el tipo en los mensajes ("de recojo en tienda").
  String get description;

  /// Por qué los estados de otros flujos no le corresponden ("no sale a
  /// reparto"), para el 400.
  String get otherStepsNote;

  /// A qué estados puede pasar un pedido en [status]: el paso siguiente y,
  /// mientras no esté entregado, cancelado. Vacío si es un estado final o si
  /// [status] no es de este flujo.
  List<OrderStatus> allowedNext(OrderStatus status) {
    final i = steps.indexOf(status);
    if (i < 0 || i == steps.length - 1) return const [];
    return [steps[i + 1], OrderStatus.cancelled];
  }

  /// Si un pedido de este tipo puede llegar a estar en [status].
  bool passesThrough(OrderStatus status) =>
      status == OrderStatus.cancelled || steps.contains(status);

  /// Cómo se nombra [status] en los mensajes: "entregado", o "recogido" en
  /// recojo.
  String labelOf(OrderStatus status) => orderStatusLabel(status);
}

/// El flujo del [type] de entrega.
FulfillmentFlow fulfillmentFlowOf(FulfillmentType type) => switch (type) {
  FulfillmentType.delivery => const DeliveryFlow(),
  FulfillmentType.pickup => const PickupFlow(),
};

/// Nombre de cada estado en los mensajes de error.
String orderStatusLabel(OrderStatus status) => switch (status) {
  OrderStatus.pendingConfirmation => 'pendiente de confirmación',
  OrderStatus.confirmed => 'confirmado',
  OrderStatus.outForDelivery => 'en camino',
  OrderStatus.delivered => 'entregado',
  OrderStatus.cancelled => 'cancelado',
  OrderStatus.preparing => 'preparando',
  OrderStatus.readyForPickup => 'en espera de recojo',
};
