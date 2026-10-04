import { OrderStatus } from '@prisma/client';
import { IsEnum, IsOptional } from 'class-validator';
import { PaginationQueryDto } from '../../common/pagination';
import { IsDay } from '../../common/validation';

/** Query de GET /orders (dashboard). `from` y `to` son días de la tienda, ambos incluidos. */
export class ListOrdersQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsEnum(OrderStatus)
  status?: OrderStatus;

  @IsOptional()
  @IsDay()
  from?: string;

  @IsOptional()
  @IsDay()
  to?: string;
}
