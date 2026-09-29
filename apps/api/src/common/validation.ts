import { Transform } from 'class-transformer';
import { ValidateIf } from 'class-validator';

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
