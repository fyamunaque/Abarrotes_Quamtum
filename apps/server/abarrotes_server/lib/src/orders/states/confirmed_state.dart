import '../../generated/protocol.dart';
import 'order_state_handler.dart';

/// Aceptado por la tienda: sale a reparto o se cancela.
class ConfirmedState extends OrderStateHandler {
  const ConfirmedState();

  @override
  OrderStatus get status => OrderStatus.confirmed;

  @override
  List<OrderStatus> get nextStatuses => const [
    OrderStatus.outForDelivery,
    OrderStatus.cancelled,
  ];
}
