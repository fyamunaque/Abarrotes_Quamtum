import { PrismaService } from '../prisma/prisma.service';
import { ProductStockRepository } from './product-stock.repository';

describe('ProductStockRepository', () => {
  const minStockField = { name: 'minStock' }; // referencia de campo de Prisma
  let findMany: jest.Mock;
  let repository: ProductStockRepository;

  beforeEach(() => {
    findMany = jest.fn().mockResolvedValue([]);
    repository = new ProductStockRepository({
      product: { findMany, fields: { minStock: minStockField } },
    } as unknown as PrismaService);
  });

  it('stock bajo: productos activos con currentStock <= minStock de la misma fila', async () => {
    await repository.findLowStock();

    expect(findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { active: true, currentStock: { lte: minStockField } },
      }),
    );
  });

  it('por vencer: activos, con stock, que vencen antes del límite, los más próximos primero', async () => {
    const before = new Date('2026-10-09T00:00:00Z');

    await repository.findExpiringBefore(before);

    expect(findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          active: true,
          currentStock: { gt: 0 },
          expirationDate: { lt: before },
        },
        orderBy: [{ expirationDate: 'asc' }, { name: 'asc' }],
      }),
    );
  });
});
