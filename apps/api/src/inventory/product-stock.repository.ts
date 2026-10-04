import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

/**
 * Consultas de stock de productos. Es el único lugar de la API que sabe qué es "stock
 * bajo" o "por vencer": inventory lo exporta y stats lo reutiliza.
 */
@Injectable()
export class ProductStockRepository {
  constructor(private readonly prisma: PrismaService) {}

  /** Productos activos con currentStock <= minStock (compara dos columnas de la misma fila). */
  findLowStock() {
    return this.prisma.product.findMany({
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
  }

  /**
   * Productos activos con stock cuya fecha de vencimiento es anterior a `before`,
   * incluidos los ya vencidos. Los que no tienen fecha de vencimiento quedan fuera.
   */
  findExpiringBefore(before: Date) {
    return this.prisma.product.findMany({
      where: {
        active: true,
        currentStock: { gt: 0 },
        expirationDate: { lt: before },
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
  }
}
