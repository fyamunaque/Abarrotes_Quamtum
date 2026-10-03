import {
  addDays,
  daysBetween,
  eachDay,
  isValidDay,
  startOfMonth,
  startOfWeek,
  storeDay,
  storeDayStart,
} from './store-time';

describe('store-time (días de Lima)', () => {
  it('un instante de la noche de Lima ya es el día siguiente en UTC', () => {
    // 22:00 del 1 de octubre en Lima = 03:00 UTC del 2.
    expect(storeDay(new Date('2026-10-02T03:00:00Z'))).toBe('2026-10-01');
    expect(storeDay(new Date('2026-10-02T05:00:00Z'))).toBe('2026-10-02');
  });

  it('el día de la tienda empieza a las 05:00 UTC', () => {
    expect(storeDayStart('2026-10-01').toISOString()).toBe(
      '2026-10-01T05:00:00.000Z',
    );
  });

  it('suma días cruzando fin de mes y de año', () => {
    expect(addDays('2026-09-30', 1)).toBe('2026-10-01');
    expect(addDays('2026-12-31', 1)).toBe('2027-01-01');
    expect(addDays('2026-03-01', -1)).toBe('2026-02-28');
    expect(daysBetween('2026-09-28', '2026-10-04')).toBe(6);
    expect(daysBetween('2026-10-04', '2026-09-28')).toBe(-6);
  });

  it('enumera los días de un rango, ambos incluidos', () => {
    expect(eachDay('2026-09-29', '2026-10-02')).toEqual([
      '2026-09-29',
      '2026-09-30',
      '2026-10-01',
      '2026-10-02',
    ]);
    expect(eachDay('2026-10-02', '2026-10-01')).toEqual([]);
  });

  it('la semana empieza el lunes y el mes el día 1', () => {
    expect(startOfWeek('2026-10-04')).toBe('2026-09-28'); // domingo
    expect(startOfWeek('2026-09-28')).toBe('2026-09-28'); // lunes
    expect(startOfWeek('2026-10-01')).toBe('2026-09-28'); // jueves
    expect(startOfMonth('2026-10-17')).toBe('2026-10-01');
  });

  it('solo acepta días reales con formato AAAA-MM-DD', () => {
    expect(isValidDay('2026-02-28')).toBe(true);
    expect(isValidDay('2028-02-29')).toBe(true);
    expect(isValidDay('2026-02-29')).toBe(false);
    expect(isValidDay('2026-13-01')).toBe(false);
    expect(isValidDay('2026-1-5')).toBe(false);
    expect(isValidDay('2026-10-01T00:00:00Z')).toBe(false);
  });
});
