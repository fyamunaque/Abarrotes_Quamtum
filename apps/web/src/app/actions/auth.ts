'use server';

import type { LoginRequest, RegisterRequest } from '@abarrotes/shared-types';
import { redirect } from 'next/navigation';
import { ApiError, apiFetch, readApiError } from '@/lib/api';
import { safeRedirectPath } from '@/lib/navigation';
import { clearSession, saveSession } from '@/lib/session';

export interface AuthFormState {
  error: string | null;
  /** Valores a conservar en el formulario tras un error (nunca la contraseña). */
  values?: Record<string, string>;
}

const MIN_PASSWORD_LENGTH = 8; // Igual que POST /auth/register.

function text(formData: FormData, name: string): string {
  const value = formData.get(name);
  return typeof value === 'string' ? value.trim() : '';
}

/** Llama a login o registro y guarda la sesión. Devuelve el error o `null` si salió bien. */
async function authenticate(
  path: '/auth/login' | '/auth/register',
  body: LoginRequest | RegisterRequest,
): Promise<string | null> {
  try {
    const response = await apiFetch(path, { method: 'POST', body: JSON.stringify(body) });
    if (!response.ok) return await readApiError(response);
    await saveSession(await response.json());
    return null;
  } catch (error) {
    if (error instanceof ApiError) return error.message;
    throw error;
  }
}

export async function login(_prev: AuthFormState, formData: FormData): Promise<AuthFormState> {
  const email = text(formData, 'email');
  const password = formData.get('password');
  const values = { email };

  if (!email || typeof password !== 'string' || !password) {
    return { error: 'Ingresa tu email y contraseña.', values };
  }

  const error = await authenticate('/auth/login', { email, password });
  if (error) return { error, values };
  redirect(safeRedirectPath(formData.get('next')));
}

export async function register(
  _prev: AuthFormState,
  formData: FormData,
): Promise<AuthFormState> {
  const values = {
    name: text(formData, 'name'),
    email: text(formData, 'email'),
    phone: text(formData, 'phone'),
    address: text(formData, 'address'),
  };
  const password = formData.get('password');

  if (!values.name || !values.email) {
    return { error: 'Ingresa tu nombre y email.', values };
  }
  if (typeof password !== 'string' || password.length < MIN_PASSWORD_LENGTH) {
    return {
      error: `La contraseña debe tener al menos ${MIN_PASSWORD_LENGTH} caracteres.`,
      values,
    };
  }

  const error = await authenticate('/auth/register', {
    name: values.name,
    email: values.email,
    password,
    ...(values.phone ? { phone: values.phone } : {}),
    ...(values.address ? { address: values.address } : {}),
  });
  if (error) return { error, values };
  redirect(safeRedirectPath(formData.get('next')));
}

export async function logout(): Promise<void> {
  // Los tokens son stateless en la API: cerrar sesión es borrarlos del navegador.
  await clearSession();
  redirect('/');
}
