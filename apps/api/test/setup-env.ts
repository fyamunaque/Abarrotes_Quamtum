// Se ejecuta antes de importar AppModule: ConfigModule valida el entorno al cargarse.
// Prisma se reemplaza por un mock en los e2e, así que DATABASE_URL no se usa.
process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test';
process.env.JWT_ACCESS_SECRET = 'e2e-access-secret';
process.env.JWT_REFRESH_SECRET = 'e2e-refresh-secret';
