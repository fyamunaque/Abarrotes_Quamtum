import '../../generated/protocol.dart';
import '../fulfillment/fulfillment_flow.dart';
import 'cancelled_state.dart';
import 'confirmed_state.dart';
import 'delivered_state.dart';
import 'order_state_handler.dart';
import 'out_for_delivery_state.dart';
import 'pending_confirmation_state.dart';
import 'preparing_state.dart';
import 'ready_for_pickup_state.dart';

export '../fulfillment/fulfillment_flow.dart';
export 'order_state_handler.dart';

/// El handler del estado [status], con el [flow] del tipo de entrega del
/// pedido. El switch es exhaustivo: si se agrega un estado al enum, el
/// servidor no compila hasta que tenga su clase (y CLAUDE.md pide actualizar
/// la app Flutter).
OrderStateHandler orderStateOf(OrderStatus status, FulfillmentFlow flow) =>
    switch (status) {
      OrderStatus.pendingConfirmation => PendingConfirmationState(flow),
      OrderStatus.confirmed => ConfirmedState(flow),
      OrderStatus.outForDelivery => OutForDeliveryState(flow),
      OrderStatus.preparing => PreparingState(flow),
      OrderStatus.readyForPickup => ReadyForPickupState(flow),
      OrderStatus.delivered => DeliveredState(flow),
      OrderStatus.cancelled => CancelledState(flow),
    };

/// El handler del estado de [order], con el flujo de su tipo de entrega.
OrderStateHandler orderStateOfOrder(Order order) =>
    orderStateOf(order.status, fulfillmentFlowOf(order.fulfillmentType));
