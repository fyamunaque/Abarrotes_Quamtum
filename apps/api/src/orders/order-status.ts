import { OrderStatus } from '@prisma/client';

/**
 * Nombre de cada estado en los mensajes de error. Las transiciones permitidas viven en
 * las clases de states/ (patrón State): PENDING_CONFIRMATION → CONFIRMED →
 * OUT_FOR_DELIVERY → DELIVERED, y se puede cancelar mientras no se haya entregado.
 */
export const ORDER_STATUS_LABELS: Record<OrderStatus, string> = {
  PENDING_CONFIRMATION: 'pendiente de confirmación',
  CONFIRMED: 'confirmado',
  OUT_FOR_DELIVERY: 'en camino',
  DELIVERED: 'entregado',
  CANCELLED: 'cancelado',
};
