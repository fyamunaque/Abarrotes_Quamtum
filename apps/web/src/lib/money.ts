import type { Money } from '@abarrotes/shared-types';

const solesFormat = new Intl.NumberFormat('es-PE', {
  style: 'currency',
  currency: 'PEN',
});

/**
 * La API manda los montos como string (`"4.5"`). Se trabaja en céntimos enteros para
 * que sumar precios no acumule errores de coma flotante.
 */
export function toCents(amount: Money): number {
  const value = Number(amount);
  if (!Number.isFinite(value)) {
    throw new Error(`Monto inválido: ${amount}`);
  }
  return Math.round(value * 100);
}

/** `S/ 4.50` */
export function formatCents(cents: number): string {
  return solesFormat.format(cents / 100);
}

export function formatMoney(amount: Money): string {
  return formatCents(toCents(amount));
}
