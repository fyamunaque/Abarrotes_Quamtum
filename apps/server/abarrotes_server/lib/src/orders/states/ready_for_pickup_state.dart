import '../../generated/protocol.dart';
import '../pickup_code.dart';
import 'order_state_handler.dart';

/// En espera de recojo (solo recojo en tienda): el cliente lo recoge en caja
/// con su código, o se cancela. Al entrar guarda cuándo quedó listo.
class ReadyForPickupState extends OrderStateHandler {
  const ReadyForPickupState(super.flow);

  @override
  OrderStatus get status => OrderStatus.readyForPickup;

  /// Para entregarlo, quien atiende en caja ingresa el código que muestra el
  /// cliente.
  @override
  String? exitProblem(Order order, OrderStatus next, {String? pickupCode}) {
    if (next != OrderStatus.delivered) return null;
    final given = normalizePickupCode(pickupCode ?? '');
    if (given.isEmpty) {
      return 'Falta el código de recojo: pídeselo al cliente';
    }
    if (given != order.pickupCode) return 'El código de recojo no coincide';
    return null;
  }

  @override
  Order onEnter(Order order, DateTime now) =>
      order.copyWith(readyForPickupAt: now);
}
