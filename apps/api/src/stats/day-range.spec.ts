import { BadRequestException } from '@nestjs/common';
import { resolveDayRange, utcBounds } from './day-range';

describe('resolveDayRange', () => {
  const today = '2026-10-03';

  it('sin parámetros, los últimos 30 días hasta hoy', () => {
    expect(resolveDayRange({}, today)).toEqual({
      from: '2026-09-04',
      to: '2026-10-03',
    });
  });

  it('con solo `to`, los 30 días que terminan ese día', () => {
    expect(resolveDayRange({ to: '2026-09-30' }, today)).toEqual({
      from: '2026-09-01',
      to: '2026-09-30',
    });
  });

  it('con solo `from`, hasta hoy', () => {
    expect(resolveDayRange({ from: '2026-10-01' }, today)).toEqual({
      from: '2026-10-01',
      to: today,
    });
  });

  it('acepta un solo día y hasta 366 días', () => {
    expect(resolveDayRange({ from: today, to: today }, today)).toEqual({
      from: today,
      to: today,
    });
    expect(() =>
      resolveDayRange({ from: '2025-10-03', to: '2026-10-03' }, today),
    ).not.toThrow();
  });

  it('rechaza rangos invertidos o de más de un año', () => {
    expect(() =>
      resolveDayRange({ from: '2026-10-05', to: '2026-10-01' }, today),
    ).toThrow(BadRequestException);
    expect(() =>
      resolveDayRange({ from: '2025-10-01', to: '2026-10-03' }, today),
    ).toThrow(BadRequestException);
  });
});

describe('utcBounds', () => {
  it('va del inicio de `from` al inicio del día siguiente a `to` en Lima, sin zona', () => {
    expect(utcBounds({ from: '2026-10-01', to: '2026-10-07' })).toEqual({
      start: '2026-10-01T05:00:00.000',
      end: '2026-10-08T05:00:00.000',
    });
  });
});
