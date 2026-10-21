import '../../generated/protocol.dart';
import 'fulfillment_flow.dart';

/// Recojo en tienda: la tienda lo confirma, lo prepara, queda en espera y el
/// cliente lo recoge en caja con su código. Nunca sale a reparto.
class PickupFlow extends FulfillmentFlow {
  const PickupFlow();

  @override
  FulfillmentType get type => FulfillmentType.pickup;

  @override
  String get description => 'de recojo en tienda';

  @override
  String get otherStepsNote => 'no sale a reparto';

  @override
  List<OrderStatus> get steps => const [
    OrderStatus.pendingConfirmation,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.readyForPickup,
    OrderStatus.delivered,
  ];

  /// Un pedido de recojo entregado es uno que el cliente recogió.
  @override
  String labelOf(OrderStatus status) =>
      status == OrderStatus.delivered ? 'recogido' : super.labelOf(status);
}
