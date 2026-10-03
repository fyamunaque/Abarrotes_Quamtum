import { PrismaService } from '../../prisma/prisma.service';
import { TopProductsReportProvider } from './top-products-report.provider';

describe('TopProductsReportProvider', () => {
  it('devuelve los más vendidos con cantidad e ingresos, y aplica el límite', async () => {
    const queryRaw = jest.fn().mockResolvedValue([
      {
        productId: 'p1',
        name: 'Arroz extra 1 kg',
        sku: 'ARZ',
        quantity: 12,
        revenue: '54.00',
      },
      {
        productId: 'p2',
        name: 'Leche 400 g',
        sku: 'LCH',
        quantity: 5,
        revenue: '21.00',
      },
    ]);
    const provider = new TopProductsReportProvider({
      $queryRaw: queryRaw,
    } as unknown as PrismaService);

    const report = await provider.getSummary({
      from: '2026-09-04',
      to: '2026-10-03',
      limit: 2,
    });

    expect(report).toEqual({
      from: '2026-09-04',
      to: '2026-10-03',
      data: [
        {
          productId: 'p1',
          name: 'Arroz extra 1 kg',
          sku: 'ARZ',
          quantity: 12,
          revenue: '54',
        },
        {
          productId: 'p2',
          name: 'Leche 400 g',
          sku: 'LCH',
          quantity: 5,
          revenue: '21',
        },
      ],
    });
    const [strings, ...values] = queryRaw.mock.calls[0] as [
      TemplateStringsArray,
      ...unknown[],
    ];
    expect(strings.join('?')).toMatch(/LIMIT \?$/);
    expect(values.at(-1)).toBe(2);
    expect(values).toContain('2026-09-04T05:00:00.000');
    expect(values).toContain('2026-10-04T05:00:00.000');
  });
});
