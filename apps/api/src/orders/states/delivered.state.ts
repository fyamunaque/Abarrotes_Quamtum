import { OrderStatus } from '@prisma/client';
import { OrderState } from './order-state';

/** Estado final: el pedido ya se entregó. */
export class DeliveredState extends OrderState {
  readonly status = OrderStatus.DELIVERED;
  readonly nextStatuses: readonly OrderStatus[] = [];
}
