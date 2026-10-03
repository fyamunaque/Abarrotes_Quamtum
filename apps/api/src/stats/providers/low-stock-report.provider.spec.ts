import { PrismaService } from '../../prisma/prisma.service';
import { LowStockReportProvider } from './low-stock-report.provider';

function product(sku: string, currentStock: number, minStock: number) {
  return {
    id: `id-${sku}`,
    name: `Producto ${sku}`,
    sku,
    currentStock,
    minStock,
    category: { name: 'Abarrotes' },
  };
}

describe('LowStockReportProvider', () => {
  const minStockField = { name: 'minStock' }; // referencia de campo de Prisma
  let findMany: jest.Mock;
  let provider: LowStockReportProvider;

  beforeEach(() => {
    findMany = jest
      .fn()
      .mockResolvedValue([
        product('CASI', 9, 10),
        product('AGOTADO', 0, 5),
        product('MITAD', 10, 20),
        product('SIN-MINIMO', 0, 0),
      ]);
    provider = new LowStockReportProvider({
      product: { findMany, fields: { minStock: minStockField } },
    } as unknown as PrismaService);
  });

  it('compara currentStock con minStock de la misma fila, solo en productos activos', async () => {
    await provider.getSummary();

    expect(findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { active: true, currentStock: { lte: minStockField } },
      }),
    );
  });

  it('pone primero los más críticos y calcula lo que falta para el mínimo', async () => {
    const { data } = await provider.getSummary();

    expect(data.map((p) => p.sku)).toEqual([
      'AGOTADO', // 0 % del mínimo, faltan 5
      'SIN-MINIMO', // 0 % (mínimo 0), faltan 0
      'MITAD', // 50 %
      'CASI', // 90 %
    ]);
    expect(data[0]).toEqual({
      id: 'id-AGOTADO',
      name: 'Producto AGOTADO',
      sku: 'AGOTADO',
      category: 'Abarrotes',
      currentStock: 0,
      minStock: 5,
      shortage: 5,
    });
  });
});
