import { ProductStockRepository } from '../../inventory/product-stock.repository';
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
  // La consulta vive en ProductStockRepository (ver su spec): aquí solo se ordena.
  const findLowStock = jest
    .fn()
    .mockResolvedValue([
      product('CASI', 9, 10),
      product('AGOTADO', 0, 5),
      product('MITAD', 10, 20),
      product('SIN-MINIMO', 0, 0),
    ]);
  const provider = new LowStockReportProvider({
    findLowStock,
  } as unknown as ProductStockRepository);

  it('usa la consulta de stock bajo de inventory', async () => {
    await provider.getSummary();

    expect(findLowStock).toHaveBeenCalledTimes(1);
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
