import { OrderStatus } from '@prisma/client';
import { ORDER_STATUS_LABELS } from '../order-status';

/**
 * Patrón State: cada estado del pedido es una clase que sabe a qué estados puede pasar.
 * Para cambiar el flujo se toca solo la clase del estado afectado, sin un switch central.
 */
export interface OrderStateHandler {
  readonly status: OrderStatus;
  canTransitionTo(next: OrderStatus): boolean;
  /** Por qué no puede pasar a `next`, en palabras de la tienda (para el 400). */
  rejectionReason(next: OrderStatus): string;
}

/** Lo común a todos los estados: cada uno solo declara su nombre y sus siguientes estados. */
export abstract class OrderState implements OrderStateHandler {
  abstract readonly status: OrderStatus;
  /** Estados a los que puede avanzar; vacío si es un estado final. */
  abstract readonly nextStatuses: readonly OrderStatus[];

  canTransitionTo(next: OrderStatus): boolean {
    return this.nextStatuses.includes(next);
  }

  rejectionReason(next: OrderStatus): string {
    const current = ORDER_STATUS_LABELS[this.status];
    if (next === this.status) {
      return `El pedido ya está ${current}`;
    }
    if (this.nextStatuses.length === 0) {
      return `Un pedido ${current} ya no puede cambiar de estado`;
    }
    const options = this.nextStatuses
      .map((status) => ORDER_STATUS_LABELS[status])
      .join(' o ');
    return `Un pedido ${current} no puede pasar a ${ORDER_STATUS_LABELS[next]}: solo puede pasar a ${options}`;
  }
}
