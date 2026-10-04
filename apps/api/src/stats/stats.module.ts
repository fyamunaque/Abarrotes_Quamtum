import { Module } from '@nestjs/common';
import { InventoryModule } from '../inventory/inventory.module';
import { ExpiringProductsReportProvider } from './providers/expiring-products-report.provider';
import { LowStockReportProvider } from './providers/low-stock-report.provider';
import { OrderStatusReportProvider } from './providers/order-status-report.provider';
import { OverviewReportProvider } from './providers/overview-report.provider';
import { SalesReportProvider } from './providers/sales-report.provider';
import { TopProductsReportProvider } from './providers/top-products-report.provider';
import { StatsController } from './stats.controller';
import {
  EXPIRING_PRODUCTS_REPORT,
  LOW_STOCK_REPORT,
  ORDER_STATUS_REPORT,
  OVERVIEW_REPORT,
  SALES_REPORT,
  TOP_PRODUCTS_REPORT,
} from './stats.tokens';

/** Cada reporte se registra bajo su token: para cambiar una estrategia basta con cambiar useClass. */
@Module({
  // Stock bajo y por vencer usan las consultas de inventory (ProductStockRepository).
  imports: [InventoryModule],
  controllers: [StatsController],
  providers: [
    { provide: SALES_REPORT, useClass: SalesReportProvider },
    { provide: ORDER_STATUS_REPORT, useClass: OrderStatusReportProvider },
    { provide: OVERVIEW_REPORT, useClass: OverviewReportProvider },
    { provide: TOP_PRODUCTS_REPORT, useClass: TopProductsReportProvider },
    { provide: LOW_STOCK_REPORT, useClass: LowStockReportProvider },
    {
      provide: EXPIRING_PRODUCTS_REPORT,
      useClass: ExpiringProductsReportProvider,
    },
  ],
})
export class StatsModule {}
