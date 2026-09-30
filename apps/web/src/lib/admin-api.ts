import 'server-only';

import type {
  AdminOrder,
  ListOrdersQuery,
  ListProductsQuery,
  Paginated,
  Product,
  PublicUser,
} from '@abarrotes/shared-types';
import { redirect } from 'next/navigation';
import { ApiError, readApiError } from './api';
import { fetchAsUser } from './session';

// Lecturas del dashboard: van con el token del usuario y sin caché. La API es la que
// decide si el rol alcanza (403 si no).

async function getAsUser<T>(path: string, returnTo: string): Promise<T> {
  const response = await fetchAsUser(path);
  if (!response || response.status === 401) {
    redirect(`/ingresar?next=${encodeURIComponent(returnTo)}`);
  }
  if (!response.ok) {
    throw new ApiError(await readApiError(response), response.status);
  }
  return (await response.json()) as T;
}

/** Usuario según la API (rol actual incluido), o `null` si no hay sesión válida. */
export async function getCurrentUser(): Promise<PublicUser | null> {
  const response = await fetchAsUser('/auth/me');
  if (!response || response.status === 401) return null;
  if (!response.ok) throw new ApiError(await readApiError(response), response.status);
  return (await response.json()) as PublicUser;
}

export function listOrders(query: ListOrdersQuery): Promise<Paginated<AdminOrder>> {
  const params = new URLSearchParams();
  if (query.status) params.set('status', query.status);
  if (query.page) params.set('page', String(query.page));
  if (query.limit) params.set('limit', String(query.limit));
  return getAsUser(`/orders?${params}`, '/admin/pedidos');
}

/** Incluye productos inactivos (la API solo los muestra a ADMIN/STAFF). */
export function listProductsForAdmin(query: ListProductsQuery): Promise<Paginated<Product>> {
  const params = new URLSearchParams({ includeInactive: 'true' });
  if (query.categoryId) params.set('categoryId', query.categoryId);
  if (query.search) params.set('search', query.search);
  if (query.page) params.set('page', String(query.page));
  if (query.limit) params.set('limit', String(query.limit));
  return getAsUser(`/products?${params}`, '/admin/productos');
}

export async function getProductForAdmin(id: string): Promise<Product | null> {
  try {
    return await getAsUser<Product>(`/products/${encodeURIComponent(id)}`, `/admin/productos/${id}`);
  } catch (error) {
    if (error instanceof ApiError && (error.status === 404 || error.status === 400)) return null;
    throw error;
  }
}
