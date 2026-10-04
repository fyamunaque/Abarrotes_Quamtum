import { ProductStockRepository } from '../../inventory/product-stock.repository';
import { ExpiringProductsReportProvider } from './expiring-products-report.provider';

describe('ExpiringProductsReportProvider', () => {
  // 22:00 del 1 de octubre en Lima: en UTC ya es el 2, pero para la tienda "hoy" es el 1.
  const now = new Date('2026-10-02T03:00:00Z');
  let findExpiringBefore: jest.Mock;
  let provider: ExpiringProductsReportProvider;

  beforeEach(() => {
    // La consulta vive en ProductStockRepository (ver su spec).
    findExpiringBefore = jest.fn().mockResolvedValue([
      {
        id: 'p1',
        name: 'Yogur',
        sku: 'YOG',
        currentStock: 3,
        expirationDate: new Date('2026-09-29T00:00:00Z'),
      },
      {
        id: 'p2',
        name: 'Leche',
        sku: 'LCH',
        currentStock: 12,
        expirationDate: new Date('2026-10-01T00:00:00Z'),
      },
      {
        id: 'p3',
        name: 'Pan',
        sku: 'PAN',
        currentStock: 8,
        expirationDate: new Date('2026-10-08T00:00:00Z'),
      },
    ]);
    provider = new ExpiringProductsReportProvider(
      { findExpiringBefore } as unknown as ProductStockRepository,
      { now: () => now },
    );
  });

  it('pide a inventory lo que vence hasta hoy + días, contando "hoy" en hora de Lima', async () => {
    const report = await provider.getSummary({ days: 7 });

    expect(report.until).toBe('2026-10-08');
    // Hasta el 8 incluido: la fecha se guarda a medianoche UTC.
    expect(findExpiringBefore).toHaveBeenCalledWith(
      new Date('2026-10-09T00:00:00Z'),
    );
  });

  it('calcula los días que faltan: 0 vence hoy y negativo ya venció', async () => {
    const report = await provider.getSummary({ days: 7 });

    expect(report.days).toBe(7);
    expect(
      report.data.map((p) => [p.sku, p.expirationDate, p.daysLeft]),
    ).toEqual([
      ['YOG', '2026-09-29', -2],
      ['LCH', '2026-10-01', 0],
      ['PAN', '2026-10-08', 7],
    ]);
  });
});
