import {
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import type { AuthUser } from '../auth.types';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';

/**
 * Guard global de Passport-JWT (ver JwtStrategy). Toda ruta exige un access token
 * válido salvo las marcadas con @Public(); en esas, si llega un token válido igual se
 * adjunta el usuario (por ejemplo, para que el staff vea productos inactivos).
 */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private readonly reflector: Reflector) {
    super();
  }

  handleRequest<TUser = AuthUser>(
    err: unknown,
    user: AuthUser | false,
    info: unknown,
    context: ExecutionContext,
  ): TUser {
    if (user) return user as TUser;

    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    // En rutas públicas, sin token o con uno inválido se atiende como anónimo.
    if (isPublic) return undefined as TUser;

    if (err instanceof Error) throw err;
    // passport-jwt informa "No auth token" cuando no llega el header Authorization.
    const missingToken =
      info instanceof Error && info.message === 'No auth token';
    throw new UnauthorizedException(
      missingToken
        ? 'Falta el token de acceso'
        : 'Token de acceso inválido o expirado',
    );
  }
}
