import { IsNotEmpty, IsString, MaxLength } from 'class-validator';
import { Trim } from '../../common/validation';

export class CreateCategoryDto {
  @Trim()
  @IsString()
  @IsNotEmpty()
  @MaxLength(60)
  name: string;
}
