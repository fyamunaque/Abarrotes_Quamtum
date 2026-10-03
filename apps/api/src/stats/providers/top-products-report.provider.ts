import type { TopProductsReport } from '@abarrotes/shared-types';
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { SALE_STATUSES, utcBounds } from '../day-range';
import type { DayRange, ReportProvider } from '../report-provider';

export interface TopProductsRange extends DayRange {
  limit: number;
}

interface TopProductRow {
  productId: string;
  name: string;
  sku: string;
  quantity: number;
  revenue: string;
}

/** Productos más vendidos por unidades en los pedidos aceptados del rango. */
@Injectable()
export class TopProductsReportProvider implements ReportProvider<
  TopProductsRange,
  TopProductsReport
> {
  constructor(private readonly prisma: PrismaService) {}

  async getSummary(range: TopProductsRange): Promise<TopProductsReport> {
    const { start, end } = utcBounds(range);
    // A igual cantidad, primero el que más facturó; después, por nombre.
    const rows = await this.prisma.$queryRaw<TopProductRow[]>`
      SELECT p."id" AS "productId",
             p."name",
             p."sku",
             SUM(oi."quantity")::int AS quantity,
             SUM(oi."quantity" * oi."unitPrice")::text AS revenue
      FROM "OrderItem" oi
      JOIN "Order" o ON o."id" = oi."orderId"
      JOIN "Product" p ON p."id" = oi."productId"
      WHERE o."status"::text IN (${Prisma.join(SALE_STATUSES)})
        AND o."createdAt" >= ${start}::timestamp
        AND o."createdAt" < ${end}::timestamp
      GROUP BY p."id", p."name", p."sku"
      ORDER BY SUM(oi."quantity") DESC, SUM(oi."quantity" * oi."unitPrice") DESC, p."name"
      LIMIT ${range.limit}`;

    return {
      from: range.from,
      to: range.to,
      data: rows.map((row) => ({
        productId: row.productId,
        name: row.name,
        sku: row.sku,
        quantity: row.quantity,
        revenue: new Prisma.Decimal(row.revenue).toString(),
      })),
    };
  }
}
