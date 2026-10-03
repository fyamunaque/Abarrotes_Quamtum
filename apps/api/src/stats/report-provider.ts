/**
 * Estrategia de reporte. Cada tipo de reporte es una clase independiente que solo sabe
 * calcular el suyo (ver providers/). El controller y los reportes compuestos dependen de
 * esta interfaz, inyectada por token (stats.tokens.ts), y no de las clases concretas:
 * cambiar cómo se calcula un reporte no toca a quien lo usa.
 */
export interface ReportProvider<TRange, TData> {
  getSummary(range: TRange): Promise<TData>;
}

/** Rango de días de calendario de la tienda, ambos incluidos: "2026-10-01". */
export interface DayRange {
  from: string;
  to: string;
}

/** Fuente de la hora actual: inyectable para poder fijarla en los tests. */
export interface Clock {
  now(): Date;
}

export const systemClock: Clock = { now: () => new Date() };
