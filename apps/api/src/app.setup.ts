import { INestApplication, ValidationPipe } from '@nestjs/common';

/** Configuración global compartida entre main.ts y los tests e2e. */
export function configureApp(app: INestApplication): void {
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
}
