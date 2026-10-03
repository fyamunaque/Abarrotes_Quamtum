import { PrismaService } from '../../prisma/prisma.service';
import { SalesReportProvider } from './sales-report.provider';

describe('SalesReportProvider', () => {
  let queryRaw: jest.Mock;
  let provider: SalesReportProvider;

  beforeEach(() => {
    queryRaw = jest.fn().mockResolvedValue([
      { day: '2026-09-29', orders: 2, total: '20.50' },
      { day: '2026-10-01', orders: 1, total: '13.20' },
    ]);
    provider = new SalesReportProvider({
      $queryRaw: queryRaw,
    } as unknown as PrismaService);
  });

  it('devuelve un punto por día, con 0 en los días sin ventas', async () => {
    const report = await provider.getSummary({
      from: '2026-09-28',
      to: '2026-10-01',
    });

    expect(report.daily).toEqual([
      { date: '2026-09-28', total: '0', orders: 0 },
      { date: '2026-09-29', total: '20.5', orders: 2 },
      { date: '2026-09-30', total: '0', orders: 0 },
      { date: '2026-10-01', total: '13.2', orders: 1 },
    ]);
  });

  it('calcula el total, los pedidos y el ticket promedio redondeado', async () => {
    const report = await provider.getSummary({
      from: '2026-09-28',
      to: '2026-10-01',
    });

    expect(report).toMatchObject({
      from: '2026-09-28',
      to: '2026-10-01',
      timeZone: 'America/Lima',
      total: '33.7',
      orders: 3,
      averageTicket: '11.23', // 33.70 / 3 = 11.2333…
    });
  });

  it('sin ventas, el ticket promedio es 0', async () => {
    queryRaw.mockResolvedValue([]);

    const report = await provider.getSummary({
      from: '2026-10-01',
      to: '2026-10-01',
    });

    expect(report).toMatchObject({ total: '0', orders: 0, averageTicket: '0' });
  });

  it('consulta el rango en hora de Lima y solo los pedidos aceptados', async () => {
    await provider.getSummary({ from: '2026-10-01', to: '2026-10-07' });

    const [strings, ...values] = queryRaw.mock.calls[0] as [
      TemplateStringsArray,
      ...unknown[],
    ];
    const sql = strings.join('?');
    expect(sql).toContain('FROM "Order"');
    expect(values).toContain('America/Lima');
    expect(values).toContain('2026-10-01T05:00:00.000');
    expect(values).toContain('2026-10-08T05:00:00.000');
    expect(JSON.stringify(values)).toContain(
      '"CONFIRMED","OUT_FOR_DELIVERY","DELIVERED"',
    );
    expect(JSON.stringify(values)).not.toContain('PENDING_CONFIRMATION');
    expect(JSON.stringify(values)).not.toContain('CANCELLED');
  });
});
