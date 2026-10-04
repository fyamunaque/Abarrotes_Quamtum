import { Controller, Get, Query } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '../auth/decorators/roles.decorator';
import { ListMovementsQueryDto } from './dto/list-movements-query.dto';
import { InventoryService } from './inventory.service';

@Roles(UserRole.ADMIN, UserRole.STAFF)
@Controller('inventory')
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  @Get('movements')
  findMovements(@Query() query: ListMovementsQueryDto) {
    return this.inventoryService.findMovements(query);
  }
}
