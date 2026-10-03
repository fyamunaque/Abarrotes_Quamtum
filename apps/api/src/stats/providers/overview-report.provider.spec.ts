import type { SalesReport } from '@abarrotes/shared-types';
import type { DayRange, ReportProvider } from '../report-provider';
import type { OrdersByStatus } from './order-status-report.provider';
import { OverviewReportProvider } from './overview-report.provider';

describe('OverviewReportProvider', () => {
  const byStatus: OrdersByStatus = {
    PENDING_CONFIRMATION: 2,
    CONFIRMED: 1,
    OUT_FOR_DELIVERY: 0,
    DELIVERED: 5,
    CANCELLED: 1,
  };

  // Reportes falsos: el overview solo conoce la interfaz ReportProvider.
  const sales: ReportProvider<DayRange, SalesReport> = {
    getSummary: jest.fn(({ from, to }: DayRange) =>
      Promise.resolve({
        from,
        to,
        timeZone: 'America/Lima',
        total: '10',
        orders: 2,
        averageTicket: '5',
        daily: [{ date: to, total: '10', orders: 2 }],
      }),
    ),
  };
  const orderStatus: ReportProvider<void, OrdersByStatus> = {
    getSummary: jest.fn(() => Promise.resolve(byStatus)),
  };

  it('pide las ventas de hoy, de la semana desde el lunes y del mes, en hora de Lima', async () => {
    // Domingo 4 de octubre, 21:30 en Lima (lunes 5, 02:30 en UTC).
    const now = new Date('2026-10-05T02:30:00Z');
    const provider = new OverviewReportProvider(sales, orderStatus, {
      now: () => now,
    });

    const overview = await provider.getSummary();

    expect(sales.getSummary).toHaveBeenCalledWith({
      from: '2026-10-04',
      to: '2026-10-04',
    });
    expect(sales.getSummary).toHaveBeenCalledWith({
      from: '2026-09-28',
      to: '2026-10-04',
    });
    expect(sales.getSummary).toHaveBeenCalledWith({
      from: '2026-10-01',
      to: '2026-10-04',
    });
    expect(overview).toEqual({
      timeZone: 'America/Lima',
      generatedAt: '2026-10-05T02:30:00.000Z',
      today: {
        from: '2026-10-04',
        to: '2026-10-04',
        total: '10',
        orders: 2,
        averageTicket: '5',
      },
      week: {
        from: '2026-09-28',
        to: '2026-10-04',
        total: '10',
        orders: 2,
        averageTicket: '5',
      },
      month: {
        from: '2026-10-01',
        to: '2026-10-04',
        total: '10',
        orders: 2,
        averageTicket: '5',
      },
      ordersByStatus: byStatus,
    });
  });
});
