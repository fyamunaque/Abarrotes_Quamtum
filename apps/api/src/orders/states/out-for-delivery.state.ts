import { OrderStatus } from '@prisma/client';
import { OrderState } from './order-state';

/** En camino: se entrega o, si no se pudo entregar, se cancela. */
export class OutForDeliveryState extends OrderState {
  readonly status = OrderStatus.OUT_FOR_DELIVERY;
  readonly nextStatuses = [OrderStatus.DELIVERED, OrderStatus.CANCELLED];
}
