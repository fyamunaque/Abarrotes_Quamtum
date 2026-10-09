import '../../generated/protocol.dart';
import 'cancelled_state.dart';
import 'confirmed_state.dart';
import 'delivered_state.dart';
import 'order_state_handler.dart';
import 'out_for_delivery_state.dart';
import 'pending_confirmation_state.dart';

export 'order_state_handler.dart';

/// El handler del estado en que está un pedido. El switch es exhaustivo: si
/// se agrega un estado al enum, el servidor no compila hasta que tenga su
/// clase (y CLAUDE.md pide actualizar los tres frontends).
OrderStateHandler orderStateOf(OrderStatus status) => switch (status) {
  OrderStatus.pendingConfirmation => const PendingConfirmationState(),
  OrderStatus.confirmed => const ConfirmedState(),
  OrderStatus.outForDelivery => const OutForDeliveryState(),
  OrderStatus.delivered => const DeliveredState(),
  OrderStatus.cancelled => const CancelledState(),
};
