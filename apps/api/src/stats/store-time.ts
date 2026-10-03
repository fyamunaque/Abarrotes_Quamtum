/**
 * Días de calendario en la hora de la tienda. Un pedido de las 22:00 de Lima ya es el
 * día siguiente en UTC: las estadísticas agrupan por día de Lima, como lo ve la tienda.
 * Los días se representan como "AAAA-MM-DD", que además se ordenan bien como texto.
 */
export const STORE_TIME_ZONE = 'America/Lima';

const DAY_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;
const MS_PER_DAY = 86_400_000;

// en-CA formatea las fechas como AAAA-MM-DD.
const dayFormatter = new Intl.DateTimeFormat('en-CA', {
  timeZone: STORE_TIME_ZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});
const offsetFormatter = new Intl.DateTimeFormat('en-US', {
  timeZone: STORE_TIME_ZONE,
  timeZoneName: 'longOffset',
});

/** Día de la tienda en que cae un instante. */
export function storeDay(instant: Date): string {
  return dayFormatter.format(instant);
}

/** Medianoche UTC de un día: así se guardan las fechas sin hora (p. ej. el vencimiento). */
export function utcMidnight(day: string): Date {
  const match = DAY_PATTERN.exec(day);
  if (!match) throw new Error(`Día inválido: ${day}`);
  return new Date(Date.UTC(+match[1], +match[2] - 1, +match[3]));
}

/** Instante en que empieza un día en la tienda (00:00 de Lima = 05:00 UTC). */
export function storeDayStart(day: string): Date {
  const midnight = utcMidnight(day);
  // El desfase se mide a mediodía de ese día, lejos de cualquier cambio de horario.
  const noon = new Date(midnight.getTime() + MS_PER_DAY / 2);
  return new Date(midnight.getTime() - offsetMinutes(noon) * 60_000);
}

/** true si es un día real con formato AAAA-MM-DD ("2026-02-30" no lo es). */
export function isValidDay(day: string): boolean {
  return (
    DAY_PATTERN.test(day) && utcMidnight(day).toISOString().slice(0, 10) === day
  );
}

export function addDays(day: string, amount: number): string {
  return new Date(utcMidnight(day).getTime() + amount * MS_PER_DAY)
    .toISOString()
    .slice(0, 10);
}

/** Días de `from` a `to` (negativo si `to` es anterior). */
export function daysBetween(from: string, to: string): number {
  return Math.round(
    (utcMidnight(to).getTime() - utcMidnight(from).getTime()) / MS_PER_DAY,
  );
}

/** Todos los días de `from` a `to`, ambos incluidos. */
export function eachDay(from: string, to: string): string[] {
  const count = daysBetween(from, to) + 1;
  return Array.from({ length: Math.max(count, 0) }, (_, i) => addDays(from, i));
}

/** Lunes de la semana de ese día. */
export function startOfWeek(day: string): string {
  const weekday = utcMidnight(day).getUTCDay(); // 0 = domingo
  return addDays(day, -((weekday + 6) % 7));
}

export function startOfMonth(day: string): string {
  return `${day.slice(0, 8)}01`;
}

/** Desfase de la tienda respecto a UTC en minutos (Lima: -300). */
function offsetMinutes(instant: Date): number {
  const name = offsetFormatter
    .formatToParts(instant)
    .find((part) => part.type === 'timeZoneName')?.value;
  const match = /GMT([+-])(\d{2}):(\d{2})/.exec(name ?? '');
  if (!match) return 0; // "GMT" a secas: sin desfase
  const minutes = +match[2] * 60 + +match[3];
  return match[1] === '-' ? -minutes : minutes;
}
