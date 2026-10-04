import type { ExpiringProductsReport } from '@abarrotes/shared-types';
import { Inject, Injectable } from '@nestjs/common';
import { ProductStockRepository } from '../../inventory/product-stock.repository';
import { Clock, CLOCK } from '../../common/clock';
import type { ReportProvider } from '../report-provider';
import {
  addDays,
  daysBetween,
  storeDay,
  utcMidnight,
} from '../../common/store-time';

export interface ExpiringRange {
  days: number;
}

/**
 * Productos activos con stock que vencen de hoy a hoy + `days`, incluidos los que ya
 * vencieron y siguen en el inventario (son los más urgentes). La consulta es la de
 * inventory (ProductStockRepository); este reporte calcula el rango en hora de Lima y los
 * días que faltan. La fecha de vencimiento se guarda sin hora (medianoche UTC) y se
 * compara como día de calendario.
 */
@Injectable()
export class ExpiringProductsReportProvider implements ReportProvider<
  ExpiringRange,
  ExpiringProductsReport
> {
  constructor(
    private readonly stock: ProductStockRepository,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  async getSummary({ days }: ExpiringRange): Promise<ExpiringProductsReport> {
    const today = storeDay(this.clock.now());
    const until = addDays(today, days);

    // Hasta `until` incluido: el límite es la medianoche UTC del día siguiente.
    const products = await this.stock.findExpiringBefore(
      utcMidnight(addDays(until, 1)),
    );

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
