import type {
  ExpiringProductsReport,
  LowStockReport,
  SalesReport,
  StatsOverview,
  TopProductsReport,
} from '@abarrotes/shared-types';
import { Controller, Get, Inject, Query } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '../auth/decorators/roles.decorator';
import { resolveDayRange } from './day-range';
import {
  DateRangeQueryDto,
  ExpiringQueryDto,
  TopProductsQueryDto,
} from './dto/stats-query.dto';
import type { ExpiringRange } from './providers/expiring-products-report.provider';
import type { TopProductsRange } from './providers/top-products-report.provider';
import type { Clock, DayRange, ReportProvider } from './report-provider';
import {
  CLOCK,
  EXPIRING_PRODUCTS_REPORT,
  LOW_STOCK_REPORT,
  OVERVIEW_REPORT,
  SALES_REPORT,
  TOP_PRODUCTS_REPORT,
} from './stats.tokens';
import { storeDay } from '../common/store-time';

/**
 * Estadísticas del dashboard, solo para ADMIN y STAFF. El controller traduce el query a un
 * rango y delega: los cálculos viven en cada ReportProvider.
 */
@Roles(UserRole.ADMIN, UserRole.STAFF)
@Controller('stats')
export class StatsController {
  constructor(
    @Inject(OVERVIEW_REPORT)
    private readonly overview: ReportProvider<void, StatsOverview>,
    @Inject(SALES_REPORT)
    private readonly sales: ReportProvider<DayRange, SalesReport>,
    @Inject(TOP_PRODUCTS_REPORT)
    private readonly topProducts: ReportProvider<
      TopProductsRange,
      TopProductsReport
    >,
    @Inject(LOW_STOCK_REPORT)
    private readonly lowStock: ReportProvider<void, LowStockReport>,
    @Inject(EXPIRING_PRODUCTS_REPORT)
    private readonly expiring: ReportProvider<
      ExpiringRange,
      ExpiringProductsReport
    >,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  @Get('overview')
  getOverview() {
    return this.overview.getSummary();
  }

  @Get('sales')
  getSales(@Query() query: DateRangeQueryDto) {
    return this.sales.getSummary(resolveDayRange(query, this.today()));
  }

  @Get('top-products')
  getTopProducts(@Query() query: TopProductsQueryDto) {
    return this.topProducts.getSummary({
      ...resolveDayRange(query, this.today()),
      limit: query.limit,
    });
  }

  @Get('low-stock')
  getLowStock() {
    return this.lowStock.getSummary();
  }

  @Get('expiring')
  getExpiring(@Query() query: ExpiringQueryDto) {
    return this.expiring.getSummary({ days: query.days });
  }

  private today(): string {
    return storeDay(this.clock.now());
  }
}
