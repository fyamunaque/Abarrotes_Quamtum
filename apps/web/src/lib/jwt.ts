/**
 * Segundos que le quedan a un JWT según su `exp`, para que la cookie expire junto con
 * el token. No verifica la firma: eso lo hace la API en cada petición.
 */
export function secondsUntilExpiry(token: string, nowSeconds = Date.now() / 1000): number | null {
  const payload = token.split('.')[1];
  if (!payload) return null;
  try {
    const { exp } = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as {
      exp?: unknown;
    };
    if (typeof exp !== 'number') return null;
    return Math.max(0, Math.floor(exp - nowSeconds));
  } catch {
    return null;
  }
}
