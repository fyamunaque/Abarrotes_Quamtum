import type { PromotionStatus } from '@abarrotes/shared-types';
import { Prisma } from '@prisma/client';
import { addDays, storeDay, storeDayStart } from '../common/store-time';

/**
 * Reglas de las promociones, compartidas por promotions, products (mostrar el precio) y
 * orders (cobrarlo): la definición de "vigente" vive solo aquí.
 *
 * Fechas: la API recibe y devuelve días de la tienda (hora de Lima), ambos incluidos. Se
 * guardan como instantes: startDate = 00:00 del primer día y endDate = 00:00 del día
 * siguiente al último (límite exclusivo). Así "vigente" es start <= ahora < end.
 */

/** Promociones encendidas cuyo periodo incluye `now`. */
export function activePromotionWhere(now: Date): Prisma.PromotionWhereInput {
  return { active: true, startDate: { lte: now }, endDate: { gt: now } };
}

/** El estado se deduce de la fecha y del interruptor `active`; no se guarda. */
export function promotionStatus(
  promotion: { active: boolean; startDate: Date; endDate: Date },
  now: Date,
): PromotionStatus {
  if (!promotion.active) return 'DISABLED';
  if (now < promotion.startDate) return 'SCHEDULED';
  if (now >= promotion.endDate) return 'EXPIRED';
  return 'ACTIVE';
}

/** Filtro de Prisma para listar las promociones que hoy tienen ese estado. */
export function promotionStatusWhere(
  status: PromotionStatus,
  now: Date,
): Prisma.PromotionWhereInput {
  switch (status) {
    case 'DISABLED':
      return { active: false };
    case 'SCHEDULED':
      return { active: true, startDate: { gt: now } };
    case 'EXPIRED':
      return { active: true, endDate: { lte: now } };
    case 'ACTIVE':
      return activePromotionWhere(now);
  }
}

/** Días de la tienda (ambos incluidos) → instantes que se guardan. */
export function toStoredPeriod(period: { startDate: string; endDate: string }) {
  return {
    startDate: storeDayStart(period.startDate),
    endDate: storeDayStart(addDays(period.endDate, 1)),
  };
}

/** Instantes guardados → días de la tienda (ambos incluidos). */
export function toDayPeriod(period: { startDate: Date; endDate: Date }) {
  return {
    startDate: storeDay(period.startDate),
    endDate: addDays(storeDay(period.endDate), -1),
  };
}
