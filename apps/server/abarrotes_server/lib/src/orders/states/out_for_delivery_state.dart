import '../../generated/protocol.dart';
import 'order_state_handler.dart';

/// En camino (solo a domicilio): se entrega o, si no se pudo entregar, se
/// cancela.
class OutForDeliveryState extends OrderStateHandler {
  const OutForDeliveryState(super.flow);

  @override
  OrderStatus get status => OrderStatus.outForDelivery;
}
