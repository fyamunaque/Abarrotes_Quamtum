import {
  activePromotionWhere,
  promotionStatus,
  promotionStatusWhere,
  toDayPeriod,
  toStoredPeriod,
} from './promotion-rules';

describe('reglas de promociones', () => {
  // Promoción del 1 al 7 de octubre (días de Lima): del 1, 05:00 UTC al 8, 05:00 UTC.
  const stored = toStoredPeriod({
    startDate: '2026-10-01',
    endDate: '2026-10-07',
  });

  it('guarda el primer día a las 00:00 de Lima y el último como límite exclusivo', () => {
    expect(stored).toEqual({
      startDate: new Date('2026-10-01T05:00:00.000Z'),
      endDate: new Date('2026-10-08T05:00:00.000Z'),
    });
    expect(toDayPeriod(stored)).toEqual({
      startDate: '2026-10-01',
      endDate: '2026-10-07',
    });
  });

  it.each([
    ['2026-09-30T23:00:00Z', 'SCHEDULED'], // 18:00 del 30 en Lima
    ['2026-10-01T05:00:00Z', 'ACTIVE'], // 00:00 del 1 en Lima: empieza
    ['2026-10-08T04:59:59Z', 'ACTIVE'], // 23:59 del 7 en Lima: último momento
    ['2026-10-08T05:00:00Z', 'EXPIRED'], // 00:00 del 8 en Lima
  ])('a las %s está %s', (instant, status) => {
    expect(
      promotionStatus({ active: true, ...stored }, new Date(instant)),
    ).toBe(status);
  });

  it('apagada está DISABLED aunque esté dentro de sus fechas', () => {
    expect(
      promotionStatus(
        { active: false, ...stored },
        new Date('2026-10-03T12:00:00Z'),
      ),
    ).toBe('DISABLED');
  });

  it('"vigente" es encendida y con start <= ahora < end', () => {
    const now = new Date('2026-10-03T12:00:00Z');
    expect(activePromotionWhere(now)).toEqual({
      active: true,
      startDate: { lte: now },
      endDate: { gt: now },
    });
    expect(promotionStatusWhere('ACTIVE', now)).toEqual(
      activePromotionWhere(now),
    );
    expect(promotionStatusWhere('SCHEDULED', now)).toEqual({
      active: true,
      startDate: { gt: now },
    });
    expect(promotionStatusWhere('EXPIRED', now)).toEqual({
      active: true,
      endDate: { lte: now },
    });
    expect(promotionStatusWhere('DISABLED', now)).toEqual({ active: false });
  });
});
