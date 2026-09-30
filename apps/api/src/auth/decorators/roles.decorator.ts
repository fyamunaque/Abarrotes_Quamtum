import { SetMetadata } from '@nestjs/common';
import { UserRole } from '@prisma/client';

export const ROLES_KEY = 'roles';

/** Restringe la ruta a los roles indicados (requiere usuario autenticado). */
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES_KEY, roles);
