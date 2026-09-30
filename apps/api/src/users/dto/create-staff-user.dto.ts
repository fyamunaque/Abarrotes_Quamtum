import { UserRole } from '@prisma/client';
import {
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { IsPassword, NormalizeEmail, Trim } from '../../common/validation';

/** Roles que solo puede asignar un ADMIN. CUSTOMER se crea con POST /auth/register. */
export const STAFF_USER_ROLES = [UserRole.ADMIN, UserRole.STAFF] as const;
export type StaffUserRole = (typeof STAFF_USER_ROLES)[number];

export class CreateStaffUserDto {
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

  @IsIn(STAFF_USER_ROLES, { message: 'role debe ser ADMIN o STAFF' })
  role: StaffUserRole;
}
