import '../../generated/protocol.dart';
import 'order_state_handler.dart';

/// Estado final: el pedido ya se entregó, o el cliente lo recogió (no puede
/// volver, p. ej., a confirmado).
class DeliveredState extends OrderStateHandler {
  const DeliveredState(super.flow);

  @override
  OrderStatus get status => OrderStatus.delivered;
}
