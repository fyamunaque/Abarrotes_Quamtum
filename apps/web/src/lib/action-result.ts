/** Resultado de una Server Action que no redirige: la UI muestra `error` si falla. */
export type ActionResult = { ok: true } | { ok: false; error: string };

export const SESSION_EXPIRED_MESSAGE = 'Tu sesión expiró. Recarga la página e ingresa de nuevo.';
