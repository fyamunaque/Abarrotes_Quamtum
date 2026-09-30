import { applyDecorators } from '@nestjs/common';
import { Transform } from 'class-transformer';
import { IsString, MaxLength, MinLength, ValidateIf } from 'class-validator';

/** Regla única de contraseñas (registro y alta de staff). bcrypt ignora más de 72 bytes. */
export const IsPassword = () =>
  applyDecorators(IsString(), MinLength(8), MaxLength(72));

/**
 * Campo opcional que, si viene, no puede ser `null`.
 * `@IsOptional()` deja pasar `null`, y Prisma lo rechaza en columnas no nulas.
 */
export const IsOptionalNonNullable = () =>
  ValidateIf((_object: object, value: unknown) => value !== undefined);

export const Trim = () =>
  Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim() : value,
  );

export const NormalizeEmail = () =>
  Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  );
