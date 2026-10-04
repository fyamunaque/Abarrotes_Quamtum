import { OrderStatus } from '@prisma/client';
import { OrderState } from './order-state';

/** Recién creado: la tienda lo confirma o lo cancela. */
export class PendingConfirmationState extends OrderState {
  readonly status = OrderStatus.PENDING_CONFIRMATION;
  readonly nextStatuses = [OrderStatus.CONFIRMED, OrderStatus.CANCELLED];
}
