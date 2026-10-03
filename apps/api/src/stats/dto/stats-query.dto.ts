import { Type } from 'class-transformer';
import {
  IsInt,
  IsOptional,
  Max,
  Min,
  Validate,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';
import { isValidDay } from '../store-time';

/** Día real con formato AAAA-MM-DD ("2026-02-30" no pasa). */
@ValidatorConstraint({ name: 'isDay' })
class IsDayConstraint implements ValidatorConstraintInterface {
  validate(value: unknown): boolean {
    return typeof value === 'string' && isValidDay(value);
  }

  defaultMessage(): string {
    return '$property debe ser una fecha AAAA-MM-DD';
  }
}

/** Query de GET /stats/sales. Por defecto, los últimos 30 días (ver resolveDayRange). */
export class DateRangeQueryDto {
  @IsOptional()
  @Validate(IsDayConstraint)
  from?: string;

  @IsOptional()
  @Validate(IsDayConstraint)
  to?: string;
}

export class TopProductsQueryDto extends DateRangeQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit: number = 5;
}

export class ExpiringQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(365)
  days: number = 7;
}
