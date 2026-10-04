import '../../generated/protocol.dart';
import 'order_state_handler.dart';

/// Recién creado: la tienda lo confirma o lo cancela.
class PendingConfirmationState extends OrderStateHandler {
  const PendingConfirmationState();

  @override
  OrderStatus get status => OrderStatus.pendingConfirmation;

  @override
  List<OrderStatus> get nextStatuses => const [
    OrderStatus.confirmed,
    OrderStatus.cancelled,
  ];
}
