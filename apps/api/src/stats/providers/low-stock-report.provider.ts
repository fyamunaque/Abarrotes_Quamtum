import type { LowStockProduct, LowStockReport } from '@abarrotes/shared-types';
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import type { ReportProvider } from '../report-provider';

/**
 * Productos activos con currentStock <= minStock. Primero los más críticos: los que
 * tienen menos stock en proporción a su mínimo (agotados antes que casi en el mínimo).
 */
@Injectable()
export class LowStockReportProvider implements ReportProvider<
  void,
  LowStockReport
> {
  constructor(private readonly prisma: PrismaService) {}

  async getSummary(): Promise<LowStockReport> {
    const products = await this.prisma.product.findMany({
      // Compara dos columnas de la misma fila (referencia de campo de Prisma).
      where: {
        active: true,
        currentStock: { lte: this.prisma.product.fields.minStock },
      },
      select: {
        id: true,
        name: true,
        sku: true,
        currentStock: true,
        minStock: true,
        category: { select: { name: true } },
      },
    });

    const data: LowStockProduct[] = products.map((product) => ({
      id: product.id,
      name: product.name,
      sku: product.sku,
      category: product.category.name,
      currentStock: product.currentStock,
      minStock: product.minStock,
      shortage: product.minStock - product.currentStock,
    }));

    data.sort(
      (a, b) =>
        stockRatio(a) - stockRatio(b) ||
        b.shortage - a.shortage ||
        a.name.localeCompare(b.name, 'es'),
    );
    return { data };
  }
}

/** Qué fracción del mínimo queda: 0 si está agotado o si el mínimo es 0. */
function stockRatio({ currentStock, minStock }: LowStockProduct): number {
  return minStock > 0 ? currentStock / minStock : 0;
}
