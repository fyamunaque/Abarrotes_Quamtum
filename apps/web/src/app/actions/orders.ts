'use server';

import type { Order } from '@abarrotes/shared-types';
import { ApiError, readApiError } from '@/lib/api';
import { parseOrderRequest } from '@/lib/orders';
import { fetchWithSession } from '@/lib/session';

export type PlaceOrderResult =
  | { ok: true; order: Pick<Order, 'id' | 'total' | 'status'> }
  | { ok: false; error: string; sessionExpired?: boolean };

/** POST /orders a nombre del usuario de la sesión. Precios y total los pone la API. */
export async function placeOrder(input: unknown): Promise<PlaceOrderResult> {
  const request = parseOrderRequest(input);
  if (!request) {
    return { ok: false, error: 'Revisa tu carrito y la dirección de entrega.' };
  }

  let response: Response | null;
  try {
    response = await fetchWithSession('/orders', {
      method: 'POST',
      body: JSON.stringify(request),
    });
  } catch (error) {
    if (error instanceof ApiError) return { ok: false, error: error.message };
    throw error;
  }

  if (!response) {
    return {
      ok: false,
      error: 'Tu sesión expiró. Vuelve a ingresar para confirmar el pedido.',
      sessionExpired: true,
    };
  }
  if (!response.ok) {
    return { ok: false, error: await readApiError(response) };
  }

  const order = (await response.json()) as Order;
  return { ok: true, order: { id: order.id, total: order.total, status: order.status } };
}
