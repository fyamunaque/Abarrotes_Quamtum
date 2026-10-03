import type { SalesPoint, SalesReport } from '@abarrotes/shared-types';
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { SALE_STATUSES, utcBounds } from '../day-range';
import type { DayRange, ReportProvider } from '../report-provider';
import { eachDay, STORE_TIME_ZONE } from '../store-time';

interface DailySalesRow {
  day: string;
  orders: number;
  total: string;
}

/** Ventas de un rango de días: totales y un punto por día, también los días sin ventas. */
@Injectable()
export class SalesReportProvider implements ReportProvider<
  DayRange,
  SalesReport
> {
  constructor(private readonly prisma: PrismaService) {}

  async getSummary(range: DayRange): Promise<SalesReport> {
    const { start, end } = utcBounds(range);
    // Agrupa en la base por día de la tienda: createdAt se guarda en UTC sin zona.
    const rows = await this.prisma.$queryRaw<DailySalesRow[]>`
      SELECT to_char(("createdAt" AT TIME ZONE 'UTC') AT TIME ZONE ${STORE_TIME_ZONE}, 'YYYY-MM-DD') AS day,
             COUNT(*)::int AS orders,
             SUM("total")::text AS total
      FROM "Order"
      WHERE "status"::text IN (${Prisma.join(SALE_STATUSES)})
        AND "createdAt" >= ${start}::timestamp
        AND "createdAt" < ${end}::timestamp
      GROUP BY day
      ORDER BY day`;

    const byDay = new Map(rows.map((row) => [row.day, row]));
    const daily: SalesPoint[] = eachDay(range.from, range.to).map((date) => {
      const row = byDay.get(date);
      return {
        date,
        total: row ? new Prisma.Decimal(row.total).toString() : '0',
        orders: row?.orders ?? 0,
      };
    });

    const total = rows.reduce(
      (sum, row) => sum.plus(row.total),
      new Prisma.Decimal(0),
    );
    const orders = rows.reduce((sum, row) => sum + row.orders, 0);

    return {
      from: range.from,
      to: range.to,
      timeZone: STORE_TIME_ZONE,
      total: total.toString(),
      orders,
      averageTicket:
        orders > 0 ? total.div(orders).toDecimalPlaces(2).toString() : '0',
      daily,
    };
  }
}
