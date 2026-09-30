import { OrderStatus } from '@prisma/client';
import { IsEnum } from 'class-validator';

/** Estado destino. El servidor valida que el cambio esté permitido (ver order-status.ts). */
export class UpdateOrderStatusDto {
  @IsEnum(OrderStatus)
  status: OrderStatus;
}
