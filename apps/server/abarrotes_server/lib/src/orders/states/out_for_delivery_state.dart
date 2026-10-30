import '../../generated/protocol.dart';
import '../pickup_code.dart';
import 'order_state_handler.dart';

/// En camino (solo a domicilio): se entrega o, si no se pudo entregar, se
/// cancela.
class OutForDeliveryState extends OrderStateHandler {
  const OutForDeliveryState(super.flow);

  @override
  OrderStatus get status => OrderStatus.outForDelivery;

  /// Para entregarlo, el repartidor ingresa el código que le da el cliente
  /// (si el pedido lo tiene: los de antes no). Sin él, solo quien administra
  /// la tienda ([withoutCode], con un motivo).
  @override
  String? exitProblem(
    Order order,
    OrderStatus next, {
    String? code,
    bool withoutCode = false,
  }) {
    if (next != OrderStatus.delivered) return null;
    if (order.deliveryCode == null || withoutCode) return null;
    final given = normalizePickupCode(code ?? '');
    if (given.isEmpty) {
      return 'Falta el código de entrega: pídeselo al cliente';
    }
    if (given != order.deliveryCode) return 'El código de entrega no coincide';
    return null;
  }
}
