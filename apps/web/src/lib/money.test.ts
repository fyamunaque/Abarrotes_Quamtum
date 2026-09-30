import { describe, expect, it } from 'vitest';
import { formatCents, formatMoney, toCents } from './money';

describe('montos', () => {
  it('convierte los montos de la API a céntimos', () => {
    expect(toCents('4.5')).toBe(450);
    expect(toCents('4.35')).toBe(435);
    expect(toCents('12')).toBe(1200);
    expect(toCents('99999999.99')).toBe(9999999999);
  });

  it('rechaza montos que no son números', () => {
    expect(() => toCents('abc')).toThrow();
  });

  it('muestra soles con dos decimales', () => {
    // \s cubre el espacio no separable que usa Intl entre "S/" y el número.
    expect(formatMoney('4.5')).toMatch(/^S\/\s4\.50$/);
    expect(formatCents(2340)).toMatch(/^S\/\s23\.40$/);
  });
});
