import '../../generated/protocol.dart';
import 'order_state_handler.dart';

/// Preparando (solo recojo en tienda): queda listo para recoger o se cancela.
class PreparingState extends OrderStateHandler {
  const PreparingState(super.flow);

  @override
  OrderStatus get status => OrderStatus.preparing;
}
