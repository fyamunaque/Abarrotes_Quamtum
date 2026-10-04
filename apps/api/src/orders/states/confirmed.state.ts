import { OrderStatus } from '@prisma/client';
import { OrderState } from './order-state';

/** Aceptado por la tienda: sale a reparto o se cancela. */
export class ConfirmedState extends OrderState {
  readonly status = OrderStatus.CONFIRMED;
  readonly nextStatuses = [OrderStatus.OUT_FOR_DELIVERY, OrderStatus.CANCELLED];
}
