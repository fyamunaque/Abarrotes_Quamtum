import '../../generated/protocol.dart';
import 'order_state_handler.dart';

/// Aceptado por la tienda: según el flujo, sale a reparto o se prepara para
/// recoger; o se cancela.
class ConfirmedState extends OrderStateHandler {
  const ConfirmedState(super.flow);

  @override
  OrderStatus get status => OrderStatus.confirmed;
}
