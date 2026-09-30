import type { CreateOrderRequest, OrderStatus } from '@abarrotes/shared-types';
import { MAX_QUANTITY_PER_PRODUCT } from './cart';
import { isUuid } from './navigation';

/** Debe cubrir todos los estados de OrderStatus (el tipo Record lo obliga). */
export const ORDER_STATUS_LABELS: Record<OrderStatus, string> = {
  PENDING_CONFIRMATION: 'Pendiente de confirmación',
  CONFIRMED: 'Confirmado',
  OUT_FOR_DELIVERY: 'En camino',
  DELIVERED: 'Entregado',
  CANCELLED: 'Cancelado',
};

export const ORDER_STATUSES = Object.keys(ORDER_STATUS_LABELS) as OrderStatus[];

export function isOrderStatus(value: unknown): value is OrderStatus {
  // hasOwn y no `in`: `in` aceptaría 'toString' y otros heredados de Object.prototype.
  return typeof value === 'string' && Object.hasOwn(ORDER_STATUS_LABELS, value);
}

export function orderStatusLabel(status: string): string {
  return isOrderStatus(status) ? ORDER_STATUS_LABELS[status] : status;
}

/**
 * Cambios permitidos. Copia de apps/api/src/orders/order-status.ts, que es la que
 * manda: aquí solo decide qué botones mostrar.
 */
export const ORDER_STATUS_TRANSITIONS: Record<OrderStatus, readonly OrderStatus[]> = {
  PENDING_CONFIRMATION: ['CONFIRMED', 'CANCELLED'],
  CONFIRMED: ['OUT_FOR_DELIVERY', 'CANCELLED'],
  OUT_FOR_DELIVERY: ['DELIVERED', 'CANCELLED'],
  DELIVERED: [],
  CANCELLED: [],
};

/** Texto del botón que lleva un pedido a cada estado. */
export const ORDER_STATUS_ACTION_LABELS: Record<OrderStatus, string> = {
  PENDING_CONFIRMATION: 'Volver a pendiente',
  CONFIRMED: 'Confirmar',
  OUT_FOR_DELIVERY: 'Marcar en camino',
  DELIVERED: 'Marcar entregado',
  CANCELLED: 'Cancelar pedido',
};

export function nextOrderStatuses(status: OrderStatus): readonly OrderStatus[] {
  return ORDER_STATUS_TRANSITIONS[status];
}

const MAX_ITEMS = 100;
const MAX_ADDRESS_LENGTH = 255;

/**
 * Una Server Action es un endpoint público: cualquiera puede llamarla con cualquier
 * cosa. Antes de reenviar a la API se comprueba la forma del pedido (la API vuelve a
 * validar todo, incluidos stock y precios).
 */
export function parseOrderRequest(input: unknown): CreateOrderRequest | null {
  if (typeof input !== 'object' || input === null) return null;
  const { deliveryAddress, items } = input as Record<string, unknown>;

  if (typeof deliveryAddress !== 'string') return null;
  const address = deliveryAddress.trim();
  if (!address || address.length > MAX_ADDRESS_LENGTH) return null;

  if (!Array.isArray(items) || items.length === 0 || items.length > MAX_ITEMS) {
    return null;
  }

  const parsedItems = [];
  for (const item of items) {
    if (typeof item !== 'object' || item === null) return null;
    const { productId, quantity } = item as Record<string, unknown>;
    if (typeof productId !== 'string' || !isUuid(productId)) return null;
    if (
      typeof quantity !== 'number' ||
      !Number.isInteger(quantity) ||
      quantity < 1 ||
      quantity > MAX_QUANTITY_PER_PRODUCT
    ) {
      return null;
    }
    parsedItems.push({ productId, quantity });
  }

  return { deliveryAddress: address, items: parsedItems };
}
