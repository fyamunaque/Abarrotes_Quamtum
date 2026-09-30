export const API_UNAVAILABLE_MESSAGE =
  'No pudimos conectar con la tienda. Intenta de nuevo en unos minutos.';

/**
 * Mensaje para el usuario a partir de un error de NestJS:
 * `{ statusCode, message: "..." | ["...", "..."] }`.
 */
export function apiErrorMessage(status: number, body: unknown): string {
  const message =
    typeof body === 'object' && body !== null && 'message' in body
      ? (body as { message: unknown }).message
      : undefined;

  if (typeof message === 'string' && message.trim()) return message;
  if (Array.isArray(message)) {
    const parts = message.filter((m): m is string => typeof m === 'string');
    if (parts.length > 0) return parts.join('\n');
  }

  if (status === 401) return 'Tu sesión expiró. Vuelve a ingresar.';
  if (status === 403) return 'No tienes permisos para esta acción.';
  if (status === 404) return 'No encontramos lo que buscabas.';
  if (status >= 500) return API_UNAVAILABLE_MESSAGE;
  return `Ocurrió un error (${status}).`;
}
