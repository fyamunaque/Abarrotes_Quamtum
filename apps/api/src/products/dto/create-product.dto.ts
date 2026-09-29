import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsDate,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { IsOptionalNonNullable, Trim } from '../../common/validation';

// Límite de la columna Decimal(10, 2).
const MAX_PRICE = 99_999_999.99;

// Campos con @IsOptional() admiten null (columnas nullables: sirve para borrarlos).
// Los de @IsOptionalNonNullable() pueden omitirse, pero no venir en null.
export class CreateProductDto {
  @Trim()
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  name: string;

  @IsOptional()
  @Trim()
  @IsString()
  @MaxLength(1000)
  description?: string | null;

  @Trim()
  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  sku: string;

  @IsNumber({ maxDecimalPlaces: 2 })
  @Min(0)
  @Max(MAX_PRICE)
  price: number;

  @IsOptional()
  @IsUrl({ require_protocol: true })
  imageUrl?: string | null;

  @IsOptionalNonNullable()
  @IsBoolean()
  active?: boolean;

  // Solo stock inicial. Los cambios posteriores pasan por el módulo `inventory`
  // (Fase 4), que registra el InventoryMovement correspondiente.
  @IsOptionalNonNullable()
  @IsInt()
  @Min(0)
  currentStock?: number;

  @IsOptionalNonNullable()
  @IsInt()
  @Min(0)
  minStock?: number;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  expirationDate?: Date | null;

  @IsUUID()
  categoryId: string;
}
