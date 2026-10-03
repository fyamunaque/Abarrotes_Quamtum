import type { ExpiringProductsReport } from '@abarrotes/shared-types';
import { Inject, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { Clock, ReportProvider } from '../report-provider';
import { CLOCK } from '../stats.tokens';
import { addDays, daysBetween, storeDay, utcMidnight } from '../store-time';

export interface ExpiringRange {
  days: number;
}

/**
 * Productos activos con stock que vencen de hoy a hoy + `days`, incluidos los que ya
 * vencieron y siguen en el inventario (son los más urgentes). La fecha de vencimiento se
 * guarda sin hora (medianoche UTC) y se compara como día de calendario.
 */
@Injectable()
export class ExpiringProductsReportProvider implements ReportProvider<
  ExpiringRange,
  ExpiringProductsReport
> {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  async getSummary({ days }: ExpiringRange): Promise<ExpiringProductsReport> {
    const today = storeDay(this.clock.now());
    const until = addDays(today, days);

    const products = await this.prisma.product.findMany({
      where: {
        active: true,
        currentStock: { gt: 0 },
        expirationDate: { lt: utcMidnight(addDays(until, 1)) },
      },
      select: {
        id: true,
        name: true,
        sku: true,
        currentStock: true,
        expirationDate: true,
      },
      orderBy: [{ expirationDate: 'asc' }, { name: 'asc' }],
    });

    return {
      days,
      until,
      data: products.map((product) => {
        // El filtro `lt` excluye los productos sin fecha de vencimiento.
        const expirationDate = product
          .expirationDate!.toISOString()
          .slice(0, 10);
        return {
          id: product.id,
          name: product.name,
          sku: product.sku,
          currentStock: product.currentStock,
          expirationDate,
          daysLeft: daysBetween(today, expirationDate),
        };
      }),
    };
  }
}
