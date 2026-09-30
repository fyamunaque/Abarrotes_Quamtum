import 'server-only';

import type { AuthResponse } from '@abarrotes/shared-types';
import { cookies } from 'next/headers';
import { apiFetch } from './api';
import {
  ACCESS_COOKIE,
  decodeSessionUser,
  REFRESH_COOKIE,
  sessionCookies,
  type SessionUser,
  USER_COOKIE,
} from './session-cookies';

export type { SessionUser } from './session-cookies';

// Los tokens viven en cookies httpOnly (ver session-cookies.ts). Next.js los lee en el
// servidor y los reenvía a la API; el navegador nunca los ve ni llama a la API.

/** Solo en Server Actions o Route Handlers (únicos lugares donde se pueden escribir cookies). */
export async function saveSession(auth: AuthResponse): Promise<void> {
  const store = await cookies();
  for (const cookie of sessionCookies(auth)) {
    store.set(cookie.name, cookie.value, cookie.options);
  }
}

export async function clearSession(): Promise<void> {
  const store = await cookies();
  store.delete(ACCESS_COOKIE);
  store.delete(REFRESH_COOKIE);
  store.delete(USER_COOKIE);
}

/** Hay sesión mientras quede refresh token (el access token se renueva solo). */
export async function getSessionUser(): Promise<SessionUser | null> {
  const store = await cookies();
  const encoded = store.get(USER_COOKIE)?.value;
  if (!store.has(REFRESH_COOKIE) || !encoded) return null;
  return decodeSessionUser(encoded);
}

function withBearer(init: RequestInit, token: string): RequestInit {
  const headers = new Headers(init.headers);
  headers.set('Authorization', `Bearer ${token}`);
  // Nunca cachear respuestas autenticadas: son de un usuario, no de todos.
  return { ...init, headers, cache: 'no-store' };
}

/**
 * Para Server Components: llama a la API con el access token actual. No lo renueva
 * (un Server Component no puede escribir cookies); de eso se encarga proxy.ts antes
 * de renderizar. Devuelve `null` si no hay token.
 */
export async function fetchAsUser(path: string, init: RequestInit = {}): Promise<Response | null> {
  const token = (await cookies()).get(ACCESS_COOKIE)?.value;
  return token ? apiFetch(path, withBearer(init, token)) : null;
}

async function refreshAccessToken(): Promise<string | null> {
  const store = await cookies();
  const refreshToken = store.get(REFRESH_COOKIE)?.value;
  if (!refreshToken) return null;

  const response = await apiFetch('/auth/refresh', {
    method: 'POST',
    body: JSON.stringify({ refreshToken }),
  });
  if (!response.ok) {
    // Refresh rechazado (vencido o usuario dado de baja): la sesión terminó.
    if (response.status === 401) await clearSession();
    return null;
  }
  const auth = (await response.json()) as AuthResponse;
  await saveSession(auth);
  return auth.accessToken;
}

/**
 * Para Server Actions: llama a la API con el access token y, si venció, lo renueva y
 * reintenta una vez. Devuelve `null` si no hay sesión válida.
 */
export async function fetchWithSession(
  path: string,
  init: RequestInit = {},
): Promise<Response | null> {
  const store = await cookies();
  const token = store.get(ACCESS_COOKIE)?.value ?? (await refreshAccessToken());
  if (!token) return null;

  const response = await apiFetch(path, withBearer(init, token));
  if (response.status !== 401) return response;

  const renewed = await refreshAccessToken();
  return renewed ? apiFetch(path, withBearer(init, renewed)) : null;
}
