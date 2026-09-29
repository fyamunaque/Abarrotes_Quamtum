import { Prisma } from '@prisma/client';

/** Códigos de error de Prisma que la API traduce a respuestas HTTP. */
export const PrismaErrorCode = {
  UniqueConstraint: 'P2002',
  ForeignKeyConstraint: 'P2003',
  RecordNotFound: 'P2025',
} as const;

type PrismaErrorCodeValue =
  (typeof PrismaErrorCode)[keyof typeof PrismaErrorCode];

export function isPrismaError(
  error: unknown,
  code: PrismaErrorCodeValue,
): error is Prisma.PrismaClientKnownRequestError {
  return (
    error instanceof Prisma.PrismaClientKnownRequestError && error.code === code
  );
}
