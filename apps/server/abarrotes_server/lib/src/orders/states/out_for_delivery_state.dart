import '../../generated/protocol.dart';
import 'order_state_handler.dart';

/// En camino: se entrega o, si no se pudo entregar, se cancela.
class OutForDeliveryState extends OrderStateHandler {
  const OutForDeliveryState();

  @override
  OrderStatus get status => OrderStatus.outForDelivery;

  @override
  List<OrderStatus> get nextStatuses => const [
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];
}
