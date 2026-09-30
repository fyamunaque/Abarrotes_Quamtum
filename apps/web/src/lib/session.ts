import 'server-only';

import type { AuthResponse } from '@abarrotes/shared-types';
import { cookies } from 'next/headers';
import { apiFetch } from './api';
import { secondsUntilExpiry } from './jwt';

// Los tokens viven en cookies httpOnly: el JavaScript de la página no puede leerlos,
// así que un script inyectado (XSS) no puede robar la sesión. Next.js los lee en el
// servidor y los reenvía a la API.
const ACCESS_COOKIE = 'abarrotes_access';
const REFRESH_COOKIE = 'abarrotes_refresh';
const USER_COOKIE = 'abarrotes_user';

const FALLBACK_ACCESS_SECONDS = 15 * 60;
const FALLBACK_REFRESH_SECONDS = 7 * 24 * 60 * 60;

const cookieOptions = {
  httpOnly: true,
  sameSite: 'lax',
  secure: process.env.NODE_ENV === 'production',
  path: '/',
} as const;

/** Datos para mostrar (saludo, dirección por defecto). No sirven para autorizar nada. */
export interface SessionUser {
  name: string;
  email: string;
  address: string | null;
}

/** Solo en Server Actions o Route Handlers (únicos lugares donde se pueden escribir cookies). */
export async function saveSession(auth: AuthResponse): Promise<void> {
  const store = await cookies();
  const refreshMaxAge = secondsUntilExpiry(auth.refreshToken) ?? FALLBACK_REFRESH_SECONDS;
  const user: SessionUser = {
    name: auth.user.name,
    email: auth.user.email,
    address: auth.user.address,
  };

  store.set(ACCESS_COOKIE, auth.accessToken, {
    ...cookieOptions,
    maxAge: secondsUntilExpiry(auth.accessToken) ?? FALLBACK_ACCESS_SECONDS,
  });
  store.set(REFRESH_COOKIE, auth.refreshToken, { ...cookieOptions, maxAge: refreshMaxAge });
  // base64url: el nombre o la dirección pueden traer caracteres no válidos en una cookie.
  store.set(USER_COOKIE, Buffer.from(JSON.stringify(user)).toString('base64url'), {
    ...cookieOptions,
    maxAge: refreshMaxAge,
  });
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
  try {
    return JSON.parse(Buffer.from(encoded, 'base64url').toString('utf8')) as SessionUser;
  } catch {
    return null;
  }
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
 * Llama a la API con el access token de la sesión. Si venció, lo renueva y reintenta
 * una vez. Devuelve `null` si no hay sesión válida. Solo en Server Actions.
 */
export async function fetchWithSession(
  path: string,
  init: RequestInit = {},
): Promise<Response | null> {
  const store = await cookies();
  const send = (token: string) => {
    const headers = new Headers(init.headers);
    headers.set('Authorization', `Bearer ${token}`);
    return apiFetch(path, { ...init, headers, cache: 'no-store' });
  };

  const token = store.get(ACCESS_COOKIE)?.value ?? (await refreshAccessToken());
  if (!token) return null;

  const response = await send(token);
  if (response.status !== 401) return response;

  const renewed = await refreshAccessToken();
  return renewed ? send(renewed) : null;
}
