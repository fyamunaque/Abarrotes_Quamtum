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

export function orderStatusLabel(status: string): string {
  return ORDER_STATUS_LABELS[status as OrderStatus] ?? status;
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
