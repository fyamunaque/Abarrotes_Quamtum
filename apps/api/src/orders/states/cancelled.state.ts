import { OrderStatus } from '@prisma/client';
import { OrderState } from './order-state';

/** Estado final: el stock ya se devolvió al cancelar. */
export class CancelledState extends OrderState {
  readonly status = OrderStatus.CANCELLED;
  readonly nextStatuses: readonly OrderStatus[] = [];
}
