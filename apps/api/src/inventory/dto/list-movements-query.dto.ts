import { IsOptional, IsUUID } from 'class-validator';
import { PaginationQueryDto } from '../../common/pagination';

/** Query de GET /inventory/movements. Sin productId, el historial de todos los productos. */
export class ListMovementsQueryDto extends PaginationQueryDto {
  @IsOptional()
  @IsUUID()
  productId?: string;
}
