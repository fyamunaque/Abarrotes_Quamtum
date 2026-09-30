import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/**
 * Marca una ruta como accesible sin token. Todas las demás requieren access token
 * (el JwtAuthGuard es global). Si llega un token válido igual se adjunta el usuario.
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
