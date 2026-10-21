import '../../generated/protocol.dart';
import 'order_state_handler.dart';

/// Estado final: el stock ya se devolvió al cancelar.
class CancelledState extends OrderStateHandler {
  const CancelledState(super.flow);

  @override
  OrderStatus get status => OrderStatus.cancelled;
}
