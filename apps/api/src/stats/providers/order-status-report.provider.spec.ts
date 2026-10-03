import { PrismaService } from '../../prisma/prisma.service';
import { OrderStatusReportProvider } from './order-status-report.provider';

describe('OrderStatusReportProvider', () => {
  it('cuenta los pedidos por estado e incluye en 0 los estados sin pedidos', async () => {
    const groupBy = jest.fn().mockResolvedValue([
      { status: 'PENDING_CONFIRMATION', _count: { _all: 4 } },
      { status: 'DELIVERED', _count: { _all: 10 } },
    ]);
    const provider = new OrderStatusReportProvider({
      order: { groupBy },
    } as unknown as PrismaService);

    await expect(provider.getSummary()).resolves.toEqual({
      PENDING_CONFIRMATION: 4,
      CONFIRMED: 0,
      OUT_FOR_DELIVERY: 0,
      DELIVERED: 10,
      CANCELLED: 0,
    });
    expect(groupBy).toHaveBeenCalledWith({
      by: ['status'],
      _count: { _all: true },
    });
  });
});
