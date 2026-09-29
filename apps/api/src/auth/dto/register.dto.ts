import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { NormalizeEmail, Trim } from '../../common/validation';

// No acepta `role`: el registro público siempre crea CUSTOMER. Con
// forbidNonWhitelisted, enviar `role` devuelve 400.
export class RegisterDto {
  @NormalizeEmail()
  @IsEmail()
  @MaxLength(254)
  email: string;

  @IsString()
  @MinLength(8)
  // bcrypt ignora lo que pase de 72 bytes.
  @MaxLength(72)
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
}
