# API — NestJS + Prisma

Backend único para la app Android, el marketplace web y el dashboard admin. El modelo de datos vive en [`/prisma/schema.prisma`](../../prisma/schema.prisma) (fuente de verdad, compartida por todo el monorepo).

## Puesta en marcha

Requisitos: Node.js 20+ y PostgreSQL.

```bash
# 1. Desde la raíz del repo (npm workspaces): instala dependencias y genera el cliente de Prisma
npm install

# 2. Configura el entorno
cd apps/api
cp .env.example .env        # completa DATABASE_URL y los dos JWT_*_SECRET

# 3. Base de datos: ver "PostgreSQL local" más abajo

# 4. Crea las tablas (aplica las migraciones de /prisma/migrations) y carga los datos de desarrollo
npx prisma migrate dev
npx prisma db seed          # imprime el email y la contraseña del admin de prueba

# 5. Levanta la API en http://localhost:3001
npm run start:dev
```

Las migraciones se guardan en `/prisma/migrations`, junto al schema, y se suben al repo. Al cambiar el schema: `npx prisma migrate dev --name <descripcion>` genera la migración nueva (coordinarlo con el equipo, ver `CLAUDE.md`).

### PostgreSQL local

**Instalado en la PC** (instalador oficial): crea un usuario y una base solo para el proyecto, en vez de usar el superusuario `postgres`. Guarda esto en un archivo `setup-db.sql` fuera del repo, con una contraseña tuya:

```sql
-- CREATEDB: prisma migrate dev crea una base temporal ("shadow") para validar migraciones.
CREATE ROLE abarrotes WITH LOGIN PASSWORD 'cambia-esta-clave' CREATEDB;
CREATE DATABASE abarrotes OWNER abarrotes;
```

Ejecútalo con el superusuario (pide su contraseña). En PowerShell:

```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -f setup-db.sql
```

Y en `.env`: `DATABASE_URL="postgresql://abarrotes:cambia-esta-clave@localhost:5432/abarrotes?schema=public"`.

**Con Docker**, en cambio:

```bash
docker run -d --name abarrotes-db -e POSTGRES_USER=abarrotes -e POSTGRES_PASSWORD=cambia-esta-clave -e POSTGRES_DB=abarrotes -p 5432:5432 postgres:18
```

### Datos de desarrollo (`/prisma/seed.ts`)

`npx prisma db seed` (desde `apps/api`, donde está la configuración `prisma.seed`) carga:

- 9 categorías base.
- 4 productos de ejemplo con stock (SKU `DEMO-*`). Uno queda bajo su stock mínimo, para ver el aviso en el admin. Si ya existen no se tocan.
- Un **ADMIN de prueba**: `admin@abarrotes.test` (o `SEED_ADMIN_EMAIL`). La contraseña es `SEED_ADMIN_PASSWORD` o, si no la defines, una generada al azar en cada corrida. Al terminar imprime ambas.

Se puede correr las veces que haga falta. **No corre con `NODE_ENV=production`**: un admin con la contraseña impresa en consola no debe existir en producción. El primer ADMIN de producción queda pendiente para cuando se prepare el despliegue (Fase 6).

> Prisma está fijado en la v6: el schema usa `url = env("DATABASE_URL")` y el generador `prisma-client-js`, que Prisma 7 ya no acepta. Subir a la v7 implica cambiar el schema (coordinarlo con el equipo).

## Autenticación

- `Authorization: Bearer <accessToken>` en cada petición protegida.
- **Todas las rutas requieren token salvo las marcadas como públicas.** Para nuevos endpoints: `@Public()` para abrirlos, `@Roles(UserRole.ADMIN, ...)` para restringirlos por rol.
- Verificación con **Passport-JWT** (`src/auth/strategies/jwt.strategy.ts`): firma HS256 con `JWT_ACCESS_SECRET` y vencimiento. El guard global (`JwtAuthGuard`, que extiende `AuthGuard('jwt')`) deja pasar las rutas `@Public()`; si en ellas llega un token válido, igual adjunta el usuario.
- El payload del token trae `sub` (id del usuario), `email` y `role`.
- Access token: 15 min (`JWT_ACCESS_EXPIRES_IN`). Refresh token: 7 días (`JWT_REFRESH_EXPIRES_IN`), firmado con otro secreto. Cuando el access token expira (401), el cliente llama a `POST /auth/refresh` y reemplaza ambos tokens.
- Contraseñas con bcrypt (`src/common/password.ts`, paquete `bcryptjs`: mismo algoritmo, sin compilación nativa).
- **Quién crea qué cuenta:**
  - `CUSTOMER`: registro público. Si el body trae `role`, se ignora; cualquier otro campo desconocido responde 400.
  - `ADMIN` y `STAFF`: solo un ADMIN, con `POST /users`. En desarrollo, el primer ADMIN sale del seed.
- El rol viaja dentro del access token: si cambia el rol de alguien, se aplica en su siguiente refresh (máx. 15 min).

## Endpoints

| Método | Ruta | Acceso | Descripción |
|---|---|---|---|
| GET | `/health` | Público | Health check |
| POST | `/auth/register` | Público | `{ email, password, name, phone?, address? }` → `{ accessToken, refreshToken, user }` |
| POST | `/auth/login` | Público | `{ email, password }` → `{ accessToken, refreshToken, user }` |
| POST | `/auth/refresh` | Público | `{ refreshToken }` → par nuevo + `user` |
| GET | `/auth/me` | Autenticado | Perfil del usuario actual |
| POST | `/users` | ADMIN | `{ email, password, name, phone?, role: "ADMIN" \| "STAFF" }` → usuario creado (sin hash). `CUSTOMER` responde 400; email repetido, 409 |
| GET | `/categories` | Público | `[{ id, name }]` ordenadas por nombre |
| GET | `/categories/:id` | Público | `{ id, name }`; 404 si no existe |
| POST | `/categories` | ADMIN, STAFF | `{ name }` → categoría creada. Nombre repetido (sin distinguir mayúsculas): 409 |
| PATCH | `/categories/:id` | ADMIN, STAFF | `{ name }` → renombra; mismas reglas que al crear |
| DELETE | `/categories/:id` | ADMIN, STAFF | 204. Si todavía tiene productos (también inactivos), 409: hay que moverlos antes |
| GET | `/products` | Público | Lista paginada. Query: `categoryId`, `search` (nombre o SKU), `page` (1), `limit` (20, máx. 100), `includeInactive` (solo ADMIN/STAFF) |
| GET | `/products/:id` | Público | Detalle (los inactivos solo los ve ADMIN/STAFF) |
| POST | `/products` | ADMIN, STAFF | Crear. `currentStock` solo como stock inicial |
| PATCH | `/products/:id` | ADMIN, STAFF | Editar (campos parciales; `null` borra los opcionales). El stock no se edita aquí: irá por `inventory` (Fase 4) |
| DELETE | `/products/:id` | ADMIN, STAFF | Baja lógica (`active = false`); los pedidos históricos siguen apuntando al producto |
| POST | `/orders` | Autenticado | `{ deliveryAddress, items: [{ productId, quantity }] }` → pedido en `PENDING_CONFIRMATION` a nombre del usuario del token |
| GET | `/orders/mine` | Autenticado | Mis pedidos, del más reciente al más antiguo. Query: `page`, `limit` |
| GET | `/orders` | ADMIN, STAFF | Todos los pedidos con los datos del cliente, del más reciente al más antiguo. Query: `status`, `from` y `to` (`AAAA-MM-DD`, días de Lima, ambos incluidos; cualquiera puede faltar), `page`, `limit` |
| PATCH | `/orders/:id/status` | ADMIN, STAFF | `{ status }` → cambia el estado si la transición está permitida (ver abajo) |
| GET | `/inventory/movements` | ADMIN, STAFF | Historial de movimientos de stock (entradas, salidas y ajustes), del más reciente al más antiguo, con el producto y quién lo originó. Query: `productId` (opcional; 404 si no existe), `page`, `limit` |
| GET | `/stats/overview` | ADMIN, STAFF | Ventas de hoy, de la semana (desde el lunes) y del mes, con total, pedidos y ticket promedio; pedidos por estado |
| GET | `/stats/sales` | ADMIN, STAFF | Serie diaria para graficar. Query: `from`, `to` (`AAAA-MM-DD`; por defecto, los últimos 30 días; máx. 366) |
| GET | `/stats/top-products` | ADMIN, STAFF | Más vendidos por unidades, con ingresos. Query: `limit` (5, máx. 50), `from`, `to` |
| GET | `/stats/low-stock` | ADMIN, STAFF | Productos activos con `currentStock <= minStock`, los más críticos primero |
| GET | `/stats/expiring` | ADMIN, STAFF | Productos activos con stock que vencen en los próximos días (incluye los ya vencidos). Query: `days` (7, máx. 365) |

### Cómo se crea un pedido

`POST /orders` no acepta precios ni total: los toma de la base de datos al momento del pedido. En una sola transacción:

1. Verifica que todos los productos existan y estén activos (si no, 400).
2. Descuenta el stock de cada uno solo si alcanza (si no, 409 `Stock insuficiente para "..."` y no se guarda nada).
3. Crea el pedido con sus líneas (`unitPrice` = precio vigente) y registra un `InventoryMovement` de tipo `OUT` por producto.

Productos repetidos en `items` se suman en una sola línea. Las promociones (Fase 5) todavía no afectan el precio.

### Cambios de estado

```
PENDING_CONFIRMATION → CONFIRMED → OUT_FOR_DELIVERY → DELIVERED
        └──────────────────┴───────────────┴──→ CANCELLED
```

- **Patrón State** (`src/orders/states/`): cada estado es una clase (`PendingConfirmationState`, `ConfirmedState`, …) que implementa `OrderStateHandler` y declara a qué estados puede pasar. `PATCH` consulta el handler del estado actual antes de guardar: si la transición no vale, responde 400 con el motivo ("Un pedido entregado ya no puede cambiar de estado", "Un pedido pendiente de confirmación no puede pasar a entregado: solo puede pasar a confirmado o cancelado"). Pedir el mismo estado también es 400. `DELIVERED` y `CANCELLED` son finales.
- **Cancelar devuelve el stock** de cada línea y registra un `InventoryMovement` `IN` a nombre de quien canceló, en la misma transacción.
- Si dos personas cambian el mismo pedido a la vez, la segunda recibe 409 ("El pedido cambió mientras tanto"): así el stock nunca se devuelve dos veces.

### Estadísticas (`src/stats`)

- **Qué es una venta**: los pedidos que la tienda aceptó (`CONFIRMED`, `OUT_FOR_DELIVERY` y `DELIVERED`). Los pendientes todavía pueden rechazarse y los cancelados devuelven el stock, así que no cuentan. Se cambia en un solo lugar: `SALE_STATUSES` (`src/stats/day-range.ts`).
- **Días de Lima**: todo se agrupa por día de `America/Lima`, no de UTC. Un pedido de las 22:00 cuenta para ese día, aunque en UTC ya sea el siguiente. `from` y `to` son días de calendario y ambos se incluyen.
- **Serie sin huecos**: `GET /stats/sales` trae un punto por día del rango, en 0 los días sin ventas. `averageTicket` es `total / pedidos` redondeado a céntimos.
- **Vencimientos**: `expirationDate` se guarda sin hora y se compara como fecha. `daysLeft` es 0 si vence hoy y negativo si ya venció.
- **Diseño**: cada reporte es una clase propia que implementa `ReportProvider` (`getSummary(range)`) y se inyecta por token (`stats.tokens.ts`). El controller solo traduce el query a un rango, y `/stats/overview` compone los reportes de ventas y de pedidos por estado.
- **Stock bajo y por vencer** no tienen consulta propia en `stats`: usan `ProductStockRepository` de `src/inventory`, el único lugar de la API con esas consultas. `StatsModule` importa `InventoryModule`, así que los dos módulos comparten la misma instancia.
- Las respuestas usan los tipos de `@abarrotes/shared-types` (`StatsOverview`, `SalesReport`, …).

Respuesta de `GET /products`:

```json
{
  "data": [{ "id": "…", "name": "Arroz 1kg", "price": "4.5", "category": { "id": "…", "name": "Abarrotes" }, "…": "…" }],
  "meta": { "total": 45, "page": 1, "limit": 20, "totalPages": 3 }
}
```

Los montos (`price`, `total`, `unitPrice`) llegan como **string** (`"4.5"`, sin ceros finales): son `Decimal` y así no se pierde precisión. Parsearlos en el cliente (`BigDecimal` en Kotlin) y formatear con 2 decimales al mostrar.

Errores: formato estándar de NestJS `{ statusCode, message, error }` — 400 validación, 401 sin token o token inválido, 403 rol sin permiso, 404 no existe, 409 email/SKU duplicado.

## Tests

```bash
npm test           # unitarios (servicios)
npm run test:e2e   # HTTP completo con Prisma simulado: no necesita base de datos
npm run lint
```
