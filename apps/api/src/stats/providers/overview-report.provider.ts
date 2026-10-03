import type {
  SalesReport,
  SalesSummary,
  StatsOverview,
} from '@abarrotes/shared-types';
import { Inject, Injectable } from '@nestjs/common';
import type { Clock, DayRange, ReportProvider } from '../report-provider';
import { CLOCK, ORDER_STATUS_REPORT, SALES_REPORT } from '../stats.tokens';
import {
  startOfMonth,
  startOfWeek,
  storeDay,
  STORE_TIME_ZONE,
} from '../../common/store-time';
import type { OrdersByStatus } from './order-status-report.provider';

/**
 * Resumen del dashboard: ventas de hoy, de la semana (desde el lunes) y del mes, y los
 * pedidos por estado. No consulta la base: compone otros reportes, que recibe como
 * interfaces.
 */
@Injectable()
export class OverviewReportProvider implements ReportProvider<
  void,
  StatsOverview
> {
  constructor(
    @Inject(SALES_REPORT)
    private readonly sales: ReportProvider<DayRange, SalesReport>,
    @Inject(ORDER_STATUS_REPORT)
    private readonly orderStatus: ReportProvider<void, OrdersByStatus>,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  async getSummary(): Promise<StatsOverview> {
    const now = this.clock.now();
    const today = storeDay(now);

    const [day, week, month, ordersByStatus] = await Promise.all([
      this.sales.getSummary({ from: today, to: today }),
      this.sales.getSummary({ from: startOfWeek(today), to: today }),
      this.sales.getSummary({ from: startOfMonth(today), to: today }),
      this.orderStatus.getSummary(),
    ]);

    return {
      timeZone: STORE_TIME_ZONE,
      generatedAt: now.toISOString(),
      today: summaryOf(day),
      week: summaryOf(week),
      month: summaryOf(month),
      ordersByStatus,
    };
  }
}

/** El resumen sin la serie diaria, que el overview no necesita. */
function summaryOf({
  from,
  to,
  total,
  orders,
  averageTicket,
}: SalesReport): SalesSummary {
  return { from, to, total, orders, averageTicket };
}
