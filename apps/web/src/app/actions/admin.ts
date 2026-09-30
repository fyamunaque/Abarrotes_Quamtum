'use server';

import type { OrderStatus } from '@abarrotes/shared-types';
import { revalidatePath, updateTag } from 'next/cache';
import { redirect } from 'next/navigation';
import { type ActionResult, SESSION_EXPIRED_MESSAGE } from '@/lib/action-result';
import { ApiError, CATALOG_CACHE_TAG, readApiError } from '@/lib/api';
import { isUuid } from '@/lib/navigation';
import { isOrderStatus } from '@/lib/orders';
import {
  parseCreateProductForm,
  parseUpdateProductForm,
  type ProductField,
  productFormValues,
} from '@/lib/product-form';
import { fetchWithSession } from '@/lib/session';

// Estas acciones son endpoints públicos: cualquiera podría llamarlas. No hace falta
// revisar el rol aquí porque reenvían el token del usuario y la API responde 403 a
// quien no sea ADMIN/STAFF.

export interface ProductFormState {
  error: string | null;
  fieldErrors: Partial<Record<ProductField, string>>;
  values?: Record<string, string>;
}

type SendResult = { ok: true } | { ok: false; error: string; status?: number };

async function send(path: string, method: string, body?: unknown): Promise<SendResult> {
  let response: Response | null;
  try {
    response = await fetchWithSession(path, {
      method,
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  } catch (error) {
    if (error instanceof ApiError) return { ok: false, error: error.message };
    throw error;
  }
  if (!response) return { ok: false, error: SESSION_EXPIRED_MESSAGE };
  if (!response.ok) {
    return { ok: false, error: await readApiError(response), status: response.status };
  }
  return { ok: true };
}

function toResult(result: SendResult): ActionResult {
  return result.ok ? result : { ok: false, error: result.error };
}

export async function changeOrderStatus(
  orderId: string,
  status: OrderStatus,
): Promise<ActionResult> {
  if (!isUuid(orderId) || !isOrderStatus(status)) {
    return { ok: false, error: 'Pedido o estado inválido.' };
  }
  const result = await send(`/orders/${orderId}/status`, 'PATCH', { status });
  if (result.ok) {
    revalidatePath('/admin/pedidos');
    // Cancelar devuelve stock: el catálogo público tiene que verlo.
    if (status === 'CANCELLED') updateTag(CATALOG_CACHE_TAG);
  }
  return toResult(result);
}

/** Desactivar es la baja lógica de la API (DELETE); reactivar es un PATCH. */
export async function setProductActive(
  productId: string,
  active: boolean,
): Promise<ActionResult> {
  if (!isUuid(productId)) return { ok: false, error: 'Producto inválido.' };
  const result = active
    ? await send(`/products/${productId}`, 'PATCH', { active: true })
    : await send(`/products/${productId}`, 'DELETE');
  if (result.ok) {
    revalidatePath('/admin/productos');
    updateTag(CATALOG_CACHE_TAG);
  }
  return toResult(result);
}

function saveFailed(result: Extract<SendResult, { ok: false }>, values: Record<string, string>): ProductFormState {
  // 409 = SKU repetido: se marca en el campo.
  return result.status === 409
    ? { error: null, fieldErrors: { sku: result.error }, values }
    : { error: result.error, fieldErrors: {}, values };
}

export async function createProduct(
  _prev: ProductFormState,
  formData: FormData,
): Promise<ProductFormState> {
  const values = productFormValues(formData);
  const parsed = parseCreateProductForm(formData);
  if (!parsed.ok) {
    return { error: 'Revisa los campos marcados.', fieldErrors: parsed.fieldErrors, values };
  }

  const result = await send('/products', 'POST', parsed.data);
  if (!result.ok) return saveFailed(result, values);

  updateTag(CATALOG_CACHE_TAG);
  revalidatePath('/admin/productos');
  redirect('/admin/productos?guardado=1');
}

export async function updateProduct(
  productId: string,
  _prev: ProductFormState,
  formData: FormData,
): Promise<ProductFormState> {
  const values = productFormValues(formData);
  if (!isUuid(productId)) return { error: 'Producto inválido.', fieldErrors: {}, values };
  const parsed = parseUpdateProductForm(formData);
  if (!parsed.ok) {
    return { error: 'Revisa los campos marcados.', fieldErrors: parsed.fieldErrors, values };
  }

  const result = await send(`/products/${productId}`, 'PATCH', parsed.data);
  if (!result.ok) return saveFailed(result, values);

  updateTag(CATALOG_CACHE_TAG);
  revalidatePath('/admin/productos');
  redirect('/admin/productos?guardado=1');
}
