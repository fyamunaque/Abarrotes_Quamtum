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
import { cache } from 'react';
import { ApiError, readApiError } from './api';
import { fetchAsUser } from './session';
import { isStaffRole } from './session-cookies';

// Capa de acceso a datos del dashboard. Las lecturas van con el token del usuario y
// sin caché; la API vuelve a verificar el rol en cada una (403).
//
// El control de acceso vive aquí y no solo en app/admin/layout.tsx: en Next.js el layout
// y la página se renderizan en paralelo, así que un layout que muestra "No tienes
// acceso" no impide que la página se ejecute y consulte la API.

/** Usuario según la API (rol actual incluido), o `null` si no hay sesión válida. */
export const getCurrentUser = cache(async (): Promise<PublicUser | null> => {
  const response = await fetchAsUser('/auth/me');
  if (!response || response.status === 401) return null;
  if (!response.ok) throw new ApiError(await readApiError(response), response.status);
  return (await response.json()) as PublicUser;
});

/**
 * El usuario si es ADMIN o STAFF; si no, `null`. Cada página del admin lo llama antes de
 * leer datos. `cache`: layout y página comparten una sola consulta a /auth/me.
 */
export const getStaffUser = cache(async (): Promise<PublicUser | null> => {
  const user = await getCurrentUser();
  return user && isStaffRole(user.role) ? user : null;
});

async function getAsUser<T>(path: string, returnTo: string): Promise<T> {
  // Red de seguridad por si una página olvidó llamar a getStaffUser().
  if (!(await getStaffUser())) {
    throw new Error('Lectura del admin sin verificar el rol: llama a getStaffUser() antes.');
  }
  const response = await fetchAsUser(path);
  if (!response || response.status === 401) {
    redirect(`/ingresar?next=${encodeURIComponent(returnTo)}`);
  }
  if (!response.ok) {
    throw new ApiError(await readApiError(response), response.status);
  }
  return (await response.json()) as T;
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
