import '../../generated/protocol.dart';
import 'order_state_handler.dart';

/// Recién creado: la tienda lo confirma o lo cancela.
class PendingConfirmationState extends OrderStateHandler {
  const PendingConfirmationState(super.flow);

  @override
  OrderStatus get status => OrderStatus.pendingConfirmation;
}
