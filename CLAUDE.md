# Sistema Integral de Ventas y Distribución — Abarrotes

Instrucciones de proyecto para Claude Code. Este archivo se carga automáticamente al abrir el repo — no lo borren.

## Qué es esto

Plataforma de ecommerce para una tienda de abarrotes con tres canales conectados a un mismo backend:

- **App Android** (cliente): catálogo, carrito, pedidos, seguimiento.
- **Marketplace web** (cliente): mismo flujo de compra desde navegador.
- **Dashboard admin** (interno): productos, pedidos, inventario, logística, estadísticas, promociones.

Documento de referencia completo con arquitectura, roadmap y prompts sugeridos: `docs/ARQUITECTURA_Y_ROADMAP.md`. Léelo antes de empezar cualquier feature grande.

## Stack

| Componente | Tecnología |
|---|---|
| App Android | Kotlin + Jetpack Compose + Retrofit |
| Web (marketplace + dashboard) | Next.js (App Router) + TypeScript + Tailwind CSS |
| Backend / API | NestJS + TypeScript + Prisma ORM |
| Base de datos | PostgreSQL |
| Auth | JWT (access + refresh token). Roles: `CUSTOMER`, `ADMIN`, `STAFF` |
| Hosting objetivo | API + DB en Railway o Render, web en Vercel, app en Google Play |

## Estructura del repo (monorepo)

```
/apps
  /android        -> app Kotlin nativa
  /web            -> Next.js (marketplace público + /admin protegido por rol)
  /api            -> NestJS
/packages
  /shared-types   -> tipos TypeScript compartidos entre /web y /api
/prisma
  schema.prisma   -> fuente de verdad del modelo de datos
/docs
  ARQUITECTURA_Y_ROADMAP.md
```

## Convenciones

- **Commits**: Conventional Commits (`feat:`, `fix:`, `chore:`, `refactor:`). Un commit = un cambio lógico.
- **Ramas**: `main` (estable) ← `develop` ← `feature/<nombre-corto>`. Nunca commitear directo a `main`. `main` y `develop` solo reciben cambios por Pull Request: el hook `.githooks/pre-push` (se activa con `npm install`) bloquea el push directo a ambas.
- **Nombres**: entidades y tablas en inglés (`Product`, `Order`), texto de UI en español.
- **Módulos NestJS**: uno por dominio (`products`, `orders`, `inventory`, `promotions`, `auth`, `users`), cada uno con controller + service + DTOs propios. No mezclar dominios en un mismo módulo.
- **Estados de pedido**: enum fijo — `PENDING_CONFIRMATION`, `CONFIRMED`, `OUT_FOR_DELIVERY`, `DELIVERED`, `CANCELLED`. No agregar estados nuevos sin actualizar los tres frontends y `docs/ARQUITECTURA_Y_ROADMAP.md`.

## Cómo trabajar en este repo

- Antes de tocar el modelo de datos, revisa `prisma/schema.prisma` — es la fuente de verdad; los tres canales dependen de él. Cambios ahí se coordinan con el equipo antes de hacer merge.
- Antes de crear un endpoint nuevo, revisa si ya existe un módulo NestJS para ese dominio.
- Para cambios grandes (nueva entidad, cambio de arquitectura, nueva integración externa), usa modo plan primero y confirma con la persona antes de escribir código.
- Corre los tests del paquete que tocaste antes de dar por terminada una tarea.
- Si un cambio deja desactualizado `docs/ARQUITECTURA_Y_ROADMAP.md`, actualízalo en el mismo commit.

## Comandos frecuentes

```bash
# Backend
cd apps/api && npm run start:dev

# Web
cd apps/web && npm run dev

# Migraciones de base de datos (después de editar prisma/schema.prisma)
cd apps/api && npx prisma migrate dev --name <nombre_descriptivo>
```
