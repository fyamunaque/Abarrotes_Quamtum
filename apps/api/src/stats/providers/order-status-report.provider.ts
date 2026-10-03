import { Injectable } from '@nestjs/common';
import { OrderStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import type { ReportProvider } from '../report-provider';

export type OrdersByStatus = Record<OrderStatus, number>;

/** Cantidad de pedidos en cada estado, de cualquier fecha. Los estados sin pedidos van en 0. */
@Injectable()
export class OrderStatusReportProvider implements ReportProvider<
  void,
  OrdersByStatus
> {
  constructor(private readonly prisma: PrismaService) {}

  async getSummary(): Promise<OrdersByStatus> {
    const groups = await this.prisma.order.groupBy({
      by: ['status'],
      _count: { _all: true },
    });

    const counts = Object.fromEntries(
      Object.values(OrderStatus).map((status) => [status, 0]),
    ) as OrdersByStatus;
    for (const group of groups) counts[group.status] = group._count._all;
    return counts;
  }
}
