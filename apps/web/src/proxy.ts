import type { AuthResponse } from '@abarrotes/shared-types';
import { type NextRequest, NextResponse } from 'next/server';
import { API_URL } from '@/lib/api-url';
import {
  ACCESS_COOKIE,
  REFRESH_COOKIE,
  sessionCookies,
  USER_COOKIE,
} from '@/lib/session-cookies';

function redirectToLogin(request: NextRequest): NextResponse {
  const url = new URL('/ingresar', request.url);
  url.searchParams.set('next', request.nextUrl.pathname + request.nextUrl.search);
  return NextResponse.redirect(url);
}

/**
 * Dos trabajos, ambos baratos (ver `config.matcher`, fuera de estos casos no corre):
 *
 * 1. Renueva el access token vencido antes de renderizar. Los Server Components (páginas
 *    del admin) no pueden escribir cookies, así que sin esto verían la sesión cerrada
 *    cada 15 minutos.
 * 2. Chequeo optimista de /admin: sin sesión, redirige al login con un 307 real. El
 *    control de verdad lo hacen el layout de /admin y la API (rol y 403).
 */
export async function proxy(request: NextRequest) {
  const isAdmin = request.nextUrl.pathname.startsWith('/admin');
  const refreshToken = request.cookies.get(REFRESH_COOKIE)?.value;
  if (!refreshToken) {
    return isAdmin ? redirectToLogin(request) : NextResponse.next();
  }
  if (request.cookies.has(ACCESS_COOKIE)) {
    return NextResponse.next();
  }

  let refreshed: Response;
  try {
    refreshed = await fetch(`${API_URL}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({ refreshToken }),
    });
  } catch {
    // API caída: la página mostrará su propio error.
    return NextResponse.next();
  }

  if (!refreshed.ok) {
    if (refreshed.status !== 401) return NextResponse.next();
    // Refresh rechazado: la sesión terminó. Se borra en esta petición y en el navegador.
    request.cookies.delete(REFRESH_COOKIE);
    request.cookies.delete(USER_COOKIE);
    const response = isAdmin
      ? redirectToLogin(request)
      : NextResponse.next({ request: { headers: request.headers } });
    response.cookies.delete(REFRESH_COOKIE);
    response.cookies.delete(USER_COOKIE);
    return response;
  }

  const cookies = sessionCookies((await refreshed.json()) as AuthResponse);
  // En la petición actual, para que la página que se está por renderizar vea el token…
  for (const cookie of cookies) request.cookies.set(cookie.name, cookie.value);
  const response = NextResponse.next({ request: { headers: request.headers } });
  // …y en la respuesta, para que el navegador lo guarde.
  for (const cookie of cookies) response.cookies.set(cookie.name, cookie.value, cookie.options);
  return response;
}

export const config = {
  // Literales: Next.js analiza este objeto al compilar, no puede usar constantes importadas.
  matcher: [
    {
      // Hay sesión pero venció el access token: renovarlo.
      source: '/((?!_next/static|_next/image|favicon.ico).*)',
      has: [{ type: 'cookie', key: 'abarrotes_refresh' }],
      missing: [{ type: 'cookie', key: 'abarrotes_access' }],
    },
    {
      // /admin sin sesión: al login.
      source: '/admin/:path*',
      missing: [{ type: 'cookie', key: 'abarrotes_refresh' }],
    },
  ],
};
