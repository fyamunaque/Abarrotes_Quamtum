import { OrderStatus } from '@prisma/client';

/**
 * Cambios de estado permitidos. El flujo normal es
 * PENDING_CONFIRMATION → CONFIRMED → OUT_FOR_DELIVERY → DELIVERED; se puede cancelar
 * mientras el pedido no se haya entregado. DELIVERED y CANCELLED son finales.
 */
export const ORDER_STATUS_TRANSITIONS: Record<
  OrderStatus,
  readonly OrderStatus[]
> = {
  PENDING_CONFIRMATION: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
  CONFIRMED: [OrderStatus.OUT_FOR_DELIVERY, OrderStatus.CANCELLED],
  OUT_FOR_DELIVERY: [OrderStatus.DELIVERED, OrderStatus.CANCELLED],
  DELIVERED: [],
  CANCELLED: [],
};

export const ORDER_STATUS_LABELS: Record<OrderStatus, string> = {
  PENDING_CONFIRMATION: 'pendiente de confirmación',
  CONFIRMED: 'confirmado',
  OUT_FOR_DELIVERY: 'en camino',
  DELIVERED: 'entregado',
  CANCELLED: 'cancelado',
};

export function canTransition(from: OrderStatus, to: OrderStatus): boolean {
  return ORDER_STATUS_TRANSITIONS[from].includes(to);
}
