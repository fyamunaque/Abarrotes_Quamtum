import '../../generated/protocol.dart';
import 'order_state_handler.dart';

/// Estado final: el pedido ya se entregó (no puede volver, p. ej., a
/// confirmado).
class DeliveredState extends OrderStateHandler {
  const DeliveredState();

  @override
  OrderStatus get status => OrderStatus.delivered;

  @override
  List<OrderStatus> get nextStatuses => const [];
}
