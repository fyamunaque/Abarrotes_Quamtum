import { BadRequestException } from '@nestjs/common';
import { OrderStatus } from '@prisma/client';
import type { DayRange } from './report-provider';
import { addDays, daysBetween, storeDayStart } from './store-time';

/**
 * Pedidos que cuentan como venta: los que la tienda aceptó. Los pendientes todavía pueden
 * rechazarse y los cancelados devuelven el stock.
 */
export const SALE_STATUSES: readonly OrderStatus[] = [
  OrderStatus.CONFIRMED,
  OrderStatus.OUT_FOR_DELIVERY,
  OrderStatus.DELIVERED,
];

export const DEFAULT_RANGE_DAYS = 30;
export const MAX_RANGE_DAYS = 366;

/**
 * Rango de un query `?from=&to=`: sin `to`, hasta hoy; sin `from`, los 30 días que
 * terminan en `to`. Rechaza rangos invertidos o de más de un año.
 */
export function resolveDayRange(
  query: { from?: string; to?: string },
  today: string,
): DayRange {
  const to = query.to ?? today;
  const from = query.from ?? addDays(to, -(DEFAULT_RANGE_DAYS - 1));
  const days = daysBetween(from, to) + 1;

  if (days < 1) {
    throw new BadRequestException('from no puede ser posterior a to');
  }
  if (days > MAX_RANGE_DAYS) {
    throw new BadRequestException(
      `El rango no puede superar ${MAX_RANGE_DAYS} días`,
    );
  }
  return { from, to };
}

/**
 * Límites del rango para comparar con `createdAt` en SQL: [inicio de `from`, inicio
 * del día siguiente a `to`) en la hora de la tienda. Van como texto sin zona horaria
 * para compararlos con la columna `timestamp` (UTC) sin que intervenga la zona de la
 * sesión de PostgreSQL.
 */
export function utcBounds({ from, to }: DayRange): {
  start: string;
  end: string;
} {
  const sql = (instant: Date) => instant.toISOString().replace('Z', '');
  return {
    start: sql(storeDayStart(from)),
    end: sql(storeDayStart(addDays(to, 1))),
  };
}
