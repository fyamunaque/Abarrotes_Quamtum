import 'server-only';

import type {
  Category,
  ListProductsQuery,
  Paginated,
  Product,
} from '@abarrotes/shared-types';
import { API_UNAVAILABLE_MESSAGE, apiErrorMessage } from './api-errors';
import { API_URL } from './api-url';

/** Segundos que se reutiliza una respuesta del catálogo antes de volver a pedirla. */
const CATALOG_REVALIDATE_SECONDS = 30;

/** Etiqueta del caché del catálogo: el admin la invalida (updateTag) al guardar cambios. */
export const CATALOG_CACHE_TAG = 'catalog';

export class ApiError extends Error {
  constructor(
    message: string,
    readonly status: number,
  ) {
    super(message);
  }
}

export async function apiFetch(path: string, init: RequestInit = {}): Promise<Response> {
  const headers = new Headers(init.headers);
  headers.set('Accept', 'application/json');
  if (init.body) headers.set('Content-Type', 'application/json');

  try {
    return await fetch(`${API_URL}${path}`, { ...init, headers });
  } catch {
    // fetch solo lanza si no hubo respuesta (API caída, DNS, red).
    throw new ApiError(API_UNAVAILABLE_MESSAGE, 503);
  }
}

export async function readApiError(response: Response): Promise<string> {
  const body: unknown = await response.json().catch(() => null);
  return apiErrorMessage(response.status, body);
}

async function getJson<T>(path: string): Promise<T> {
  // Sin token a propósito: estas respuestas se cachean y las comparten todos los visitantes.
  const response = await apiFetch(path, {
    next: { revalidate: CATALOG_REVALIDATE_SECONDS, tags: [CATALOG_CACHE_TAG] },
  });
  if (!response.ok) {
    throw new ApiError(await readApiError(response), response.status);
  }
  return (await response.json()) as T;
}

export function getCategories(): Promise<Category[]> {
  return getJson('/categories');
}

export function getProducts(query: ListProductsQuery): Promise<Paginated<Product>> {
  const params = new URLSearchParams();
  if (query.categoryId) params.set('categoryId', query.categoryId);
  if (query.search) params.set('search', query.search);
  if (query.page) params.set('page', String(query.page));
  if (query.limit) params.set('limit', String(query.limit));
  return getJson(`/products?${params}`);
}

/** `null` si no existe o está inactivo (la API responde 404 a quien no es staff). */
export async function getProduct(id: string): Promise<Product | null> {
  try {
    return await getJson<Product>(`/products/${encodeURIComponent(id)}`);
  } catch (error) {
    if (error instanceof ApiError && (error.status === 404 || error.status === 400)) {
      return null;
    }
    throw error;
  }
}
