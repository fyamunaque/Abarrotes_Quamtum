import { OmitType, PartialType } from '@nestjs/mapped-types';
import { CreateProductDto } from './create-product.dto';

// skipNullProperties: false → `null` se valida (y falla) en los campos no nullables;
// los campos nullables conservan su @IsOptional() y siguen aceptando null.
export class UpdateProductDto extends PartialType(
  OmitType(CreateProductDto, ['currentStock'] as const),
  { skipNullProperties: false },
) {}
