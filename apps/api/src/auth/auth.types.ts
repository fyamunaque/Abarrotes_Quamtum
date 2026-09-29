import { UserRole } from '@prisma/client';
import type { Request } from 'express';
import type { PublicUser } from '../users/users.service';

/** Contenido de los access y refresh tokens. */
export interface JwtPayload {
  sub: string;
  email: string;
  role: UserRole;
}

/** Usuario autenticado que los guards adjuntan a la request. */
export interface AuthUser {
  id: string;
  email: string;
  role: UserRole;
}

export type AuthenticatedRequest = Request & { user?: AuthUser };

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface AuthResponse extends AuthTokens {
  user: PublicUser;
}

export const STAFF_ROLES: readonly UserRole[] = [
  UserRole.ADMIN,
  UserRole.STAFF,
];

export function isStaff(user?: AuthUser): boolean {
  return user !== undefined && STAFF_ROLES.includes(user.role);
}
