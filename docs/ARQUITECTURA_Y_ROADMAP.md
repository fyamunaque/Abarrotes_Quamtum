# Sistema Integral de Ventas y Distribución — Arquitectura y hoja de ruta

Guía técnica para el equipo. Complementa `CLAUDE.md` (que vive en la raíz del repo y es lo que lee Claude Code automáticamente).

## 1. Resumen del proyecto

Plataforma centralizada de ecommerce para una tienda de abarrotes, con tres canales sobre un mismo backend:

- **App Android** — catálogo, carrito, pedidos y seguimiento para el cliente.
- **Marketplace web** — el mismo flujo de compra desde navegador.
- **Dashboard administrativo** — gestión de productos, pedidos, inventario, logística, estadísticas y promociones.

Todo se apoya en un **backend/API único** y una **base de datos central**, para que los tres canales muestren siempre la misma información (stock, precios, estado de pedidos).

## 2. Stack elegido y por qué

| Componente | Tecnología | Por qué |
|---|---|---|
| App Android | **Kotlin** + Jetpack Compose + Retrofit | Nativo, mejor rendimiento y acceso a APIs de Android que un framework híbrido; es la opción que ya eligieron. |
| Web (marketplace + dashboard) | **Next.js** + TypeScript + Tailwind CSS | Un solo framework sirve la tienda pública y el panel admin (con rutas protegidas por rol); TypeScript comparte tipos con el backend. |
| Backend / API | **NestJS** + TypeScript + Prisma ORM | Estructura modular por dominio (parecida a Spring, así que el paso desde POO en Java es directo), tipado fuerte, y — al ser TypeScript — el mismo lenguaje que la web. Con un equipo de 2-3 personas, no tener que cambiar de lenguaje entre web y backend ahorra tiempo real. |
| Base de datos | **PostgreSQL** | Relacional, con transacciones ACID — importante cuando un pedido descuenta stock y genera un registro de venta a la vez. |
| Auth | JWT (access + refresh token) | Roles `CUSTOMER`, `ADMIN`, `STAFF`; el mismo esquema de auth sirve para app, web y dashboard. |

**Nota sobre Python:** si alguien del equipo se siente más cómodo con Python, FastAPI es una alternativa igual de válida para el backend — la arquitectura (módulos por dominio, JWT, Prisma o SQLAlchemy) se traduce casi 1 a 1. Los prompts de la sección 6 están escritos para NestJS; si cambian a FastAPI, ajusten la referencia al framework y el resto de la guía se mantiene igual.

## 3. Estructura del repo (monorepo)

Un solo repositorio con las tres apps facilita compartir tipos y mantener sincronizados los cambios del modelo de datos:

```
/apps
  /android        -> app Kotlin nativa
  /web            -> Next.js (marketplace público + /admin protegido por rol)
  /api            -> NestJS
/packages
  /shared-types   -> tipos TypeScript compartidos entre /web y /api
/prisma
  schema.prisma
  seed.ts         -> datos de desarrollo: `cd apps/api && npx prisma db seed`
  /migrations     -> generadas por `prisma migrate dev`
/docs
  ARQUITECTURA_Y_ROADMAP.md
CLAUDE.md
package.json      -> npm workspaces (un solo `npm install` en la raíz)
```

El backend fija Prisma en la v6 porque el schema usa `url = env(...)` y `prisma-client-js`, que Prisma 7 ya no acepta. Instrucciones de arranque y lista de endpoints: `apps/api/README.md`. App Android (versiones, cómo apuntarla a la API local): `apps/android/README.md`. Web (Next.js 16, páginas, sesión): `apps/web/README.md`.

**Tipos compartidos:** `packages/shared-types` describe el JSON de la API (solo tipos, se importa con `import type`). La web los usa directamente; la API los verifica en `apps/api/src/shared-types.contract.spec.ts`, que falla si un DTO de entrada o un enum (`OrderStatus`, `UserRole`) deja de coincidir. Si cambias un DTO o el schema, actualiza también `shared-types`.

**Sesión en la web:** Next.js llama a la API desde el servidor y guarda los tokens en cookies httpOnly; el navegador nunca ve los tokens ni llama a la API directamente. `apps/web/src/proxy.ts` renueva el access token vencido antes de renderizar (los Server Components no pueden escribir cookies) y manda al login a quien entre a `/admin` sin sesión. El `/admin` confirma el rol con `GET /auth/me`, y cada lectura y acción vuelve a pasar por la API, que responde 403 si el rol no alcanza.

**Regla de stock de pedidos:** `POST /orders` descuenta el stock al crear el pedido (en `PENDING_CONFIRMATION`) y registra un `InventoryMovement` `OUT`; pasar el pedido a `CANCELLED` lo devuelve con un movimiento `IN`. Ambas cosas ocurren dentro de una transacción. Transiciones permitidas: `apps/api/src/orders/order-status.ts`.

## 4. Modelo de datos inicial

Ya armé un `schema.prisma` de partida con las entidades centrales: `User` (con rol), `Category`, `Product` (con stock actual, stock mínimo y vencimiento), `InventoryMovement`, `Supply` (insumos generales), `Order` con el enum de estados de la propuesta (`PENDING_CONFIRMATION → CONFIRMED → OUT_FOR_DELIVERY → DELIVERED`, con `CANCELLED` como ruta alterna), `OrderItem` y `Promotion`.

Úsenlo como punto de partida, no como versión final — lo normal es que crezca (por ejemplo, direcciones múltiples por cliente, o historial de precios). Cualquier cambio al esquema pasa por `npx prisma migrate dev`, nunca editando la base directamente.

## 5. Hoja de ruta

Su propuesta ya define dos etapas (MVP de la app, luego sistema completo). Las abro en fases más chicas para un equipo de 2-3 personas — piensen en cada fase como 1-3 semanas, no como una fecha fija:

**Fase 0 — Fundamentos (antes de la app)**
Repo, CI básico, PostgreSQL + Prisma con el schema inicial, y en NestJS: módulo `auth` (registro/login/JWT) y CRUD de `products`. Sin esto, la app Android no tiene contra qué construir.

**Fase 1 — MVP App Android** *(tal como está en su propuesta)*
Registro e inicio de sesión, catálogo y categorías, detalle de producto, carrito, generación y consulta de pedidos, estados básicos.

**Fase 2 — Marketplace web**
Mismo flujo de compra en Next.js, reutilizando el backend ya construido en la Fase 0-1.

**Fase 3 — Dashboard admin**
Productos y categorías, clientes, subusuarios y roles, gestión de todos los pedidos con cambio de estado.

**Fase 4 — Inventario y logística**
Stock por producto, stock mínimo y alertas, entradas/salidas/ajustes, historial de movimientos, vencimientos, insumos generales, control de despacho.

**Fase 5 — Estadísticas y promociones**
Ventas por periodo, productos más/menos vendidos, stock bajo y por vencer, promociones creables desde el dashboard y visibles en app y web.
*Avance:* la API ya tiene el módulo `stats` (`/stats/overview`, `/sales`, `/top-products`, `/low-stock` y `/expiring`, solo ADMIN/STAFF; ver `apps/api/README.md`). Falta la vista en el dashboard web y las promociones.

**Fase 6 — Negocio real** *(no está en la propuesta original, pero la necesitan si el objetivo es un negocio funcional)*
Pasarela de pago, notificaciones (push/email) de cambio de estado, despliegue a producción, publicación en Google Play. Si formalizan el negocio en Perú y superan los umbrales de SUNAT, van a necesitar emitir comprobantes electrónicos — eso se integra después, vía un proveedor como Nubefact, no se construye desde cero.

Con 2-3 personas, un reparto que funciona bien: una persona en backend + base de datos, otra en Android, otra en web/dashboard — o si son 2, uno lleva backend+web y el otro Android, juntándose para integrar.

## 6. Flujo de trabajo con el equipo y con Claude Code

- **Git**: `main` estable, `develop` como rama de integración, una rama `feature/<nombre>` por tarea. Pull request antes de mergear a `develop`, aunque sea entre ustedes mismos — obliga a revisar el diff.
  - El repo es privado en el plan gratuito de GitHub, que no permite proteger ramas. En su lugar, el hook `.githooks/pre-push` bloquea en cada clon el push directo a `main` y `develop` (lo activa `npm install`, vía el script `prepare`). Es una barrera contra descuidos, no una restricción real: `git push --no-verify` la salta. Si pasan a GitHub Pro, configuren además la protección de ramas con PR y CI obligatorios.
- **Tareas**: con un equipo tan chico, GitHub Projects (gratis, ligado directo a los issues del repo) alcanza — no hace falta Jira/Trello aparte.
- **Cada quien con Claude Code en su propia rama**, para no pisarse cambios en el mismo archivo a la vez.
- Empiecen cada sesión de Claude Code en la carpeta raíz del repo (para que cargue `CLAUDE.md`), y usen `/clear` al pasar de una tarea a otra sin relación.
- Para algo grande (nueva entidad, integración de pagos, cambio de arquitectura), pídanle a Claude Code que primero les muestre el plan antes de escribir código.
- Revisen el diff antes de aceptar — sobre todo en `prisma/schema.prisma`, porque un cambio ahí afecta a los tres canales a la vez.

### Prompts listos para usar (uno por hito, cópienlos y ajusten el nombre de rama)

**Levantar el backend (Fase 0):**
```
Crea el backend NestJS en /apps/api con TypeScript. Conecta Prisma usando el
schema que ya existe en /prisma/schema.prisma (no lo regeneres). Crea el
módulo `auth` con registro, login y JWT (access + refresh token, roles
CUSTOMER/ADMIN/STAFF), y el módulo `products` con CRUD protegido por rol
para ADMIN/STAFF y lectura pública para CUSTOMER. Sigue las convenciones de
CLAUDE.md (un módulo por dominio, controller + service + DTOs).
```

**Catálogo + carrito en Android (Fase 1):**
```
En /apps/android, crea las pantallas de catálogo (lista de productos por
categoría, con búsqueda) y detalle de producto, usando Jetpack Compose.
Consume el endpoint GET /products del backend (ver /apps/api). Agrega un
carrito en memoria (ViewModel) con agregar/quitar/cambiar cantidad, y un
botón para generar el pedido contra POST /orders.
```

**Marketplace web (Fase 2):**
```
En /apps/web, crea las páginas públicas del marketplace con Next.js App
Router: listado de productos con filtro por categoría, página de detalle,
carrito (Context o Zustand) y checkout que llama a POST /orders del backend
en /apps/api. Reutiliza los tipos de /packages/shared-types si ya existen,
o créalos ahí si no.
```

**Dashboard admin (Fase 3):**
```
En /apps/web, agrega la sección /admin protegida por rol ADMIN/STAFF (usa
el JWT del backend). Necesito una vista de pedidos con filtro por estado y
botón para avanzar el estado (PENDING_CONFIRMATION -> CONFIRMED -> ...), y
una vista de productos con alta/edición/desactivación.
```

**Inventario (Fase 4):**
```
En /apps/api, crea el módulo `inventory` con endpoints para registrar
movimientos de stock (entrada/salida/ajuste) sobre el modelo
InventoryMovement, que además actualicen currentStock en Product dentro de
una transacción. Agrega un endpoint que devuelva productos con stock por
debajo de minStock y otro con productos próximos a vencer (expirationDate).
```
> Los listados de stock bajo y por vencer ya existen en `GET /stats/low-stock` y `GET /stats/expiring`: el módulo `inventory` debería reutilizarlos en vez de duplicarlos.

## 7. Herramientas complementarias

- **Probar la API mientras se desarrolla**: Insomnia o Postman (o archivos `.http` dentro del repo si prefieren algo más ligero, sin instalar nada aparte).
- **CI**: GitHub Actions corriendo lint + tests en cada pull request — evita que algo roto llegue a `develop`. Configurado en `.github/workflows/ci.yml`: tres jobs en paralelo (API con PostgreSQL efímero, que además aplica las migraciones y el seed sobre una base vacía; web; Android) en cada PR y push a `develop` y `main`.
- **Hosting**: API + PostgreSQL en Railway o Render (planes gratuitos/baratos alcanzan para empezar), web en Vercel, app en Google Play Console (pago único de $25).
- **Pagos** (Fase 6, para negocio real en Perú): Culqi o Izipay son las opciones locales más simples de integrar (tarjetas, y Culqi soporta Yape); Mercado Pago es la alternativa regional.
- **Diseño de pantallas** (opcional): si quieren mockups antes de programar, Figma tiene plan gratuito suficiente para un equipo de 2-3.

## 8. Primeros pasos concretos

1. Creen el repo (monorepo) con la estructura de la sección 3, y copien `CLAUDE.md` y `prisma/schema.prisma` tal como están aquí.
2. Corran el primer prompt de la sección 6 para levantar el backend.
3. Con el backend respondiendo `auth` y `products`, arranquen en paralelo Android (Fase 1) y, si ya tienen tiempo, el marketplace web (Fase 2).
4. No avancen a inventario/estadísticas (Fases 4-5) hasta que el flujo de compra completo (app o web → pedido → cambio de estado en el dashboard) funcione de punta a punta — es la parte que valida que la arquitectura central funciona.
