# Sistema Integral de Ventas y Distribución — Abarrotes

Instrucciones de proyecto para Claude Code. Este archivo se carga automáticamente al abrir el repo — no lo borren.

## Qué es esto

Plataforma de ecommerce para una tienda de abarrotes. El foco es **Dart y Flutter**: una app Flutter (Android + web) contra el servidor Serverpod, con dos partes:

- **Tienda** (cliente): catálogo, carrito, pedidos, seguimiento.
- **Panel admin** (`/admin`, interno): productos, pedidos, inventario, estadísticas, promociones.

La web Next.js ya se retiró. La app Kotlin y la API NestJS quedan como respaldo hasta probar la app Flutter en un Android real; después se retiran también.

Documento de referencia completo con arquitectura, roadmap y prompts sugeridos: `docs/ARQUITECTURA_Y_ROADMAP.md`. Léelo antes de empezar cualquier feature grande.

## Stack

| Componente | Tecnología |
|---|---|
| App (Android + web) | Flutter en `/apps/client`, con Riverpod y go_router. Reemplazó a la web Next.js; convive con la app Kotlin hasta reemplazarla |
| App Android (respaldo, en retiro) | Kotlin + Jetpack Compose + Retrofit |
| Backend / API (respaldo, en retiro) | NestJS + TypeScript + Prisma ORM |
| Backend nuevo (en migración) | Serverpod 4 (Dart) en `/apps/server`, pedido del cliente: reemplaza a NestJS dominio por dominio |
| Base de datos | PostgreSQL (`abarrotes` para NestJS, `abarrotes_server` para Serverpod: nunca la misma base) |
| Auth | NestJS: JWT (access + refresh token). Serverpod: Firebase Auth (ID token) y el rol en Postgres. Roles: `CUSTOMER`, `ADMIN`, `STAFF` |
| Hosting objetivo | Servidor + DB en Railway o Render, la web de Flutter en Vercel, app en Google Play |

## Estructura del repo (monorepo)

```
/apps
  /android        -> app Kotlin nativa (respaldo, en retiro)
  /api            -> NestJS (respaldo, en retiro)
  /server         -> Serverpod (Dart): abarrotes_server + cliente generado
  /client         -> Flutter (Android + web): la app nueva, contra apps/server
/packages
  /shared-types   -> tipos TypeScript del contrato JSON de /api (Serverpod responde con la misma forma)
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
- **Serverpod**: un dominio por carpeta en `apps/server/abarrotes_server/lib/src/<dominio>/`, con sus modelos `.spy.yaml`, su servicio y sus rutas. Ningún dominio importa la lógica de otro (`auth` y `common` son infraestructura compartida). `lib/src/generated/` y `abarrotes_client` los escribe `serverpod generate`: no se editan a mano. Montos en céntimos enteros (`priceCents`) y como texto en el JSON (`"4.5"`). Cada dominio expone `List<RouteEntry>` con `ApiRoute`s (rutas REST, JSON con la forma de `packages/shared-types`), valida con `InputReader` y protege la escritura con `RoleGuard(staffRoles, ruta, verifier: …)`; se registran con `addRoutes` en `lib/server.dart`. Nada de registro o login propios (los hace Firebase). Patrón completo: `apps/server/README.md`.
- **Flutter (`apps/client`)**: una carpeta por sección en `lib/features/<sección>/`. El estado va con Riverpod (providers, nada de `setState` para datos compartidos) y las rutas con go_router (paths en `router/routes.dart`). Las rutas protegidas se deciden en `router/route_guard.dart`, nunca dentro de una pantalla. Firebase y HTTP solo detrás de repositorios (interfaz + implementación, como `auth/` y `users/`) expuestos con providers: las pantallas no los llaman directo, y los tests los reemplazan por versiones en memoria. Colores y tipografía solo desde `lib/theme/`: nada de colores sueltos.
- **Estados de pedido**: enum fijo — `PENDING_CONFIRMATION`, `CONFIRMED`, `OUT_FOR_DELIVERY`, `DELIVERED`, `CANCELLED` (en Serverpod los mismos en camelCase: `pendingConfirmation`, …). No agregar estados nuevos sin actualizar la app Flutter, la app Kotlin y `docs/ARQUITECTURA_Y_ROADMAP.md`.

## Cómo trabajar en este repo

- Antes de tocar el modelo de datos, revisa `prisma/schema.prisma` — es la fuente de verdad de la API NestJS, de la que depende la app Kotlin. Los `.spy.yaml` de `apps/server` son la del servidor Serverpod: mientras convivan, un cambio de modelo se refleja en ambos. Cambios ahí se coordinan con el equipo antes de hacer merge.
- Antes de crear un endpoint nuevo, revisa si ya existe un módulo NestJS o un dominio de Serverpod para ese dominio.
- Para cambios grandes (nueva entidad, cambio de arquitectura, nueva integración externa), usa modo plan primero y confirma con la persona antes de escribir código.
- Corre los tests del paquete que tocaste antes de dar por terminada una tarea.
- Si un cambio deja desactualizado `docs/ARQUITECTURA_Y_ROADMAP.md`, actualízalo en el mismo commit.

## Comandos frecuentes

```bash
# Backend
cd apps/api && npm run start:dev

# Migraciones de base de datos (después de editar prisma/schema.prisma)
cd apps/api && npx prisma migrate dev --name <nombre_descriptivo>

# Cliente Flutter (desde apps/client)
flutter run -d chrome                      # o -d <emulador>; flutter devices los lista
flutter analyze
flutter test

# Serverpod (desde apps/server/abarrotes_server; la CLI necesita Flutter en el PATH o CI=true)
dart run bin/main.dart                     # servidor: rutas REST en el puerto 8082
dart run bin/seed_dev.dart                 # catálogo de ejemplo en la base de development (si está vacía)
serverpod generate                         # después de editar un .spy.yaml
serverpod create-migration                 # y luego: dart run bin/main.dart --role maintenance --apply-migrations
dart test                                  # unitarios + integración con PostgreSQL
```

Requisitos y detalles de Serverpod (Dart SDK, `passwords.yaml`, Firebase, primer admin): `apps/server/README.md`. Del cliente Flutter (versión de Flutter, config de Firebase, `API_URL`, tema, rutas): `apps/client/README.md`.
