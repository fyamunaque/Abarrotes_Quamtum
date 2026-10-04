import { Module } from '@nestjs/common';
import { InventoryController } from './inventory.controller';
import { InventoryService } from './inventory.service';
import { ProductStockRepository } from './product-stock.repository';

/** Stock de productos: historial de movimientos y las consultas de stock bajo y por vencer. */
@Module({
  controllers: [InventoryController],
  providers: [InventoryService, ProductStockRepository],
  // stats usa las mismas consultas de stock para sus reportes.
  exports: [ProductStockRepository],
})
export class InventoryModule {}
