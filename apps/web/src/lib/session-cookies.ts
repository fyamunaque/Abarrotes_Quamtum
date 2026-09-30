import type { AuthResponse, UserRole } from '@abarrotes/shared-types';
import { secondsUntilExpiry } from './jwt';

// Compartido por lib/session.ts (páginas y Server Actions) y proxy.ts, que escriben las
// cookies con APIs distintas pero con los mismos nombres y opciones.

export const ACCESS_COOKIE = 'abarrotes_access';
export const REFRESH_COOKIE = 'abarrotes_refresh';
export const USER_COOKIE = 'abarrotes_user';

const FALLBACK_ACCESS_SECONDS = 15 * 60;
const FALLBACK_REFRESH_SECONDS = 7 * 24 * 60 * 60;

/** Datos para mostrar y para decidir qué menú ver. No autorizan nada: eso lo hace la API. */
export interface SessionUser {
  name: string;
  email: string;
  address: string | null;
  role: UserRole;
}

export interface CookieToSet {
  name: string;
  value: string;
  options: {
    httpOnly: true;
    sameSite: 'lax';
    secure: boolean;
    path: '/';
    maxAge: number;
  };
}

function options(maxAge: number): CookieToSet['options'] {
  return {
    // httpOnly: el JavaScript de la página no puede leerlas (un XSS no roba la sesión).
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    maxAge,
  };
}

/** Cookies de sesión a partir de la respuesta de login, registro o refresh. */
export function sessionCookies(auth: AuthResponse): CookieToSet[] {
  const refreshMaxAge = secondsUntilExpiry(auth.refreshToken) ?? FALLBACK_REFRESH_SECONDS;
  const user: SessionUser = {
    name: auth.user.name,
    email: auth.user.email,
    address: auth.user.address,
    role: auth.user.role,
  };
  return [
    {
      name: ACCESS_COOKIE,
      value: auth.accessToken,
      options: options(secondsUntilExpiry(auth.accessToken) ?? FALLBACK_ACCESS_SECONDS),
    },
    { name: REFRESH_COOKIE, value: auth.refreshToken, options: options(refreshMaxAge) },
    { name: USER_COOKIE, value: encodeSessionUser(user), options: options(refreshMaxAge) },
  ];
}

// base64url: el nombre o la dirección pueden traer caracteres no válidos en una cookie.
export function encodeSessionUser(user: SessionUser): string {
  return Buffer.from(JSON.stringify(user)).toString('base64url');
}

export function decodeSessionUser(value: string): SessionUser | null {
  try {
    const user = JSON.parse(Buffer.from(value, 'base64url').toString('utf8')) as Partial<SessionUser>;
    if (typeof user.name !== 'string' || typeof user.email !== 'string') return null;
    return {
      name: user.name,
      email: user.email,
      address: user.address ?? null,
      // Cookies anteriores a este campo: se tratan como cliente.
      role: user.role ?? 'CUSTOMER',
    };
  } catch {
    return null;
  }
}

export function isStaffRole(role: UserRole): boolean {
  return role === 'ADMIN' || role === 'STAFF';
}
