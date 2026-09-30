import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import type { AuthUser } from '../auth/auth.types';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { PaginationQueryDto } from '../common/pagination';
import { CreateOrderDto } from './dto/create-order.dto';
import { OrdersService } from './orders.service';

// Requiere token (guard global). El pedido siempre queda a nombre de quien lo crea.
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateOrderDto) {
    return this.ordersService.create(user.id, dto);
  }

  @Get('mine')
  findMine(@CurrentUser() user: AuthUser, @Query() query: PaginationQueryDto) {
    return this.ordersService.findMine(user.id, query);
  }
}
