import type { PromotionStatus } from '@abarrotes/shared-types';
import { OmitType, PartialType } from '@nestjs/mapped-types';
import {
  IsBoolean,
  IsIn,
  IsNumber,
  IsOptional,
  IsUUID,
  Max,
  Min,
} from 'class-validator';
import { PaginationQueryDto } from '../../common/pagination';
import { IsDay, IsOptionalNonNullable } from '../../common/validation';

// Límite de la columna Decimal(10, 2), como el precio del producto.
const MAX_PRICE = 99_999_999.99;

export const PROMOTION_STATUSES: readonly PromotionStatus[] = [
  'SCHEDULED',
  'ACTIVE',
  'EXPIRED',
  'DISABLED',
];

/** POST /promotions. Las fechas son días de la tienda (hora de Lima), ambos incluidos. */
export class CreatePromotionDto {
  @IsUUID()
  productId: string;

  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0.01)
  @Max(MAX_PRICE)
  promoPrice: number;

  @IsDay()
  startDate: string;

  @IsDay()
  endDate: string;

  /** Interruptor manual: apagada no se aplica aunque esté dentro de sus fechas. */
  @IsOptionalNonNullable()
  @IsBoolean()
  active?: boolean;
}

/** PATCH /promotions/:id. El producto no cambia: para otro producto, otra promoción. */
export class UpdatePromotionDto extends PartialType(
  OmitType(CreatePromotionDto, ['productId'] as const),
  { skipNullProperties: false },
) {}

export class ListPromotionsQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsUUID()
  productId?: string;

  @IsOptional()
  @IsIn(PROMOTION_STATUSES)
  status?: PromotionStatus;
}
