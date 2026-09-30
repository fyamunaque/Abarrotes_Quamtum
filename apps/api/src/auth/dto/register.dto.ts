import { Transform } from 'class-transformer';
import {
  Allow,
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { IsPassword, NormalizeEmail, Trim } from '../../common/validation';

export class RegisterDto {
  @NormalizeEmail()
  @IsEmail()
  @MaxLength(254)
  email: string;

  @IsPassword()
  password: string;

  @Trim()
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name: string;

  @IsOptional()
  @Trim()
  @IsString()
  @MaxLength(20)
  phone?: string;

  @IsOptional()
  @Trim()
  @IsString()
  @MaxLength(255)
  address?: string;

  /**
   * Se acepta para no rechazar a quien lo envíe, pero se descarta siempre: el registro
   * público solo crea CUSTOMER (AuthService.register fija el rol). ADMIN y STAFF se
   * crean con POST /users.
   */
  @Allow()
  @Transform(() => undefined)
  role?: undefined;
}
