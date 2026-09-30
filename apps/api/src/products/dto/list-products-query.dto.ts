import { Transform } from 'class-transformer';
import {
  IsBoolean,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { PaginationQueryDto } from '../../common/pagination';
import { Trim } from '../../common/validation';

export class ListProductsQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  /** Busca por nombre o SKU (sin distinguir mayúsculas). */
  @IsOptional()
  @Trim()
  @IsString()
  @MaxLength(100)
  search?: string;

  /** Solo tiene efecto para ADMIN/STAFF; para el resto se ignora. */
  @IsOptional()
  @Transform(
    ({ value }: { value: unknown }) => value === 'true' || value === true,
  )
  @IsBoolean()
  includeInactive?: boolean;
}
