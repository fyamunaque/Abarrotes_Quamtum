# API — NestJS + Prisma

Backend único para la app Android, el marketplace web y el dashboard admin. El modelo de datos vive en [`/prisma/schema.prisma`](../../prisma/schema.prisma) (fuente de verdad, compartida por todo el monorepo).

## Puesta en marcha

Requisitos: Node.js 20+ y PostgreSQL.

```bash
# 1. Desde la raíz del repo (npm workspaces): instala dependencias y genera el cliente de Prisma
npm install

# 2. Configura el entorno
cd apps/api
cp .env.example .env        # completa DATABASE_URL, los dos JWT_*_SECRET y SEED_ADMIN_*

# 3. PostgreSQL local con Docker (opcional)
docker run -d --name abarrotes-db -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=abarrotes -p 5432:5432 postgres:16

# 4. Crea las tablas y carga categorías base + admin inicial
npx prisma migrate dev --name init
npm run prisma:seed

# 5. Levanta la API en http://localhost:3001
npm run start:dev
```

Las migraciones se guardan en `/prisma/migrations`, junto al schema.

> Prisma está fijado en la v6: el schema usa `url = env("DATABASE_URL")` y el generador `prisma-client-js`, que Prisma 7 ya no acepta. Subir a la v7 implica cambiar el schema (coordinarlo con el equipo).

## Autenticación

- `Authorization: Bearer <accessToken>` en cada petición protegida.
- **Todas las rutas requieren token salvo las marcadas como públicas.** Para nuevos endpoints: `@Public()` para abrirlos, `@Roles(UserRole.ADMIN, ...)` para restringirlos por rol.
- Access token: 15 min (`JWT_ACCESS_EXPIRES_IN`). Refresh token: 7 días (`JWT_REFRESH_EXPIRES_IN`). Cuando el access token expira (401), el cliente llama a `POST /auth/refresh` y reemplaza ambos tokens.
- El registro público siempre crea `CUSTOMER`. El primer `ADMIN` sale del seed; la gestión de `STAFF` llega con el módulo `users` (Fase 3).
- El rol viaja dentro del access token: si cambia el rol de alguien, se aplica en su siguiente refresh (máx. 15 min).

## Endpoints

| Método | Ruta | Acceso | Descripción |
|---|---|---|---|
| GET | `/health` | Público | Health check |
| POST | `/auth/register` | Público | `{ email, password, name, phone?, address? }` → `{ accessToken, refreshToken, user }` |
| POST | `/auth/login` | Público | `{ email, password }` → `{ accessToken, refreshToken, user }` |
| POST | `/auth/refresh` | Público | `{ refreshToken }` → par nuevo + `user` |
| GET | `/auth/me` | Autenticado | Perfil del usuario actual |
| GET | `/products` | Público | Lista paginada. Query: `categoryId`, `search` (nombre o SKU), `page` (1), `limit` (20, máx. 100), `includeInactive` (solo ADMIN/STAFF) |
| GET | `/products/:id` | Público | Detalle (los inactivos solo los ve ADMIN/STAFF) |
| POST | `/products` | ADMIN, STAFF | Crear. `currentStock` solo como stock inicial |
| PATCH | `/products/:id` | ADMIN, STAFF | Editar (campos parciales; `null` borra los opcionales). El stock no se edita aquí: irá por `inventory` (Fase 4) |
| DELETE | `/products/:id` | ADMIN, STAFF | Baja lógica (`active = false`); los pedidos históricos siguen apuntando al producto |

Respuesta de `GET /products`:

```json
{
  "data": [{ "id": "…", "name": "Arroz 1kg", "price": "4.50", "category": { "id": "…", "name": "Abarrotes" }, "…": "…" }],
  "meta": { "total": 45, "page": 1, "limit": 20, "totalPages": 3 }
}
```

`price` llega como **string** (`"4.50"`): es un `Decimal` y así no se pierde precisión. Parsearlo en el cliente (`BigDecimal` en Kotlin).

Errores: formato estándar de NestJS `{ statusCode, message, error }` — 400 validación, 401 sin token o token inválido, 403 rol sin permiso, 404 no existe, 409 email/SKU duplicado.

## Tests

```bash
npm test           # unitarios (servicios)
npm run test:e2e   # HTTP completo con Prisma simulado: no necesita base de datos
npm run lint
```
