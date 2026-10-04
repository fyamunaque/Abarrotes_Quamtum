import { OrderStatus } from '@prisma/client';
import { CancelledState } from './cancelled.state';
import { ConfirmedState } from './confirmed.state';
import { DeliveredState } from './delivered.state';
import type { OrderStateHandler } from './order-state';
import { OutForDeliveryState } from './out-for-delivery.state';
import { PendingConfirmationState } from './pending-confirmation.state';

export type { OrderStateHandler } from './order-state';

/**
 * Un handler por estado. Al ser un Record de OrderStatus, si se agrega un estado al enum
 * la API no compila hasta que tenga su clase (y CLAUDE.md pide actualizar los tres frontends).
 * Los handlers no guardan datos del pedido, así que basta una instancia de cada uno.
 */
const ORDER_STATES: Record<OrderStatus, OrderStateHandler> = {
  [OrderStatus.PENDING_CONFIRMATION]: new PendingConfirmationState(),
  [OrderStatus.CONFIRMED]: new ConfirmedState(),
  [OrderStatus.OUT_FOR_DELIVERY]: new OutForDeliveryState(),
  [OrderStatus.DELIVERED]: new DeliveredState(),
  [OrderStatus.CANCELLED]: new CancelledState(),
};

/** El handler del estado en que está un pedido. */
export function orderStateOf(status: OrderStatus): OrderStateHandler {
  return ORDER_STATES[status];
}
