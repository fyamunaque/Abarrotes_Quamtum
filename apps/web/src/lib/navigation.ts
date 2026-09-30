const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function isUuid(value: string | undefined): value is string {
  return value !== undefined && UUID.test(value);
}

/**
 * Destino de `?next=` tras iniciar sesión. Solo rutas internas: `//evil.com` o
 * `https://...` redirigirían fuera del sitio (open redirect).
 */
export function safeRedirectPath(value: unknown, fallback = '/'): string {
  if (typeof value !== 'string') return fallback;
  if (!value.startsWith('/') || value.startsWith('//') || value.startsWith('/\\')) {
    return fallback;
  }
  return value;
}

/** Primer valor de un search param (`?a=1&a=2` llega como array). */
export function firstParam(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

export function parsePage(value: string | undefined): number {
  const page = Number(value);
  return Number.isInteger(page) && page > 1 ? page : 1;
}

export interface CatalogFilters {
  categoryId?: string;
  search?: string;
  page?: number;
}

/** URL del catálogo con filtros en español: `/?categoria=...&q=...&pagina=2`. */
export function catalogHref({ categoryId, search, page }: CatalogFilters): string {
  const params = new URLSearchParams();
  if (categoryId) params.set('categoria', categoryId);
  if (search) params.set('q', search);
  if (page && page > 1) params.set('pagina', String(page));
  const query = params.toString();
  return query ? `/?${query}` : '/';
}
