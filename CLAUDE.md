# Sistema Integral de Ventas y Distribución — Abarrotes

Instrucciones de proyecto para Claude Code. Este archivo se carga automáticamente al abrir el repo — no lo borren.

## Qué es esto

Plataforma de ecommerce para una tienda de abarrotes (Neil's Food Services), toda en **Dart y Flutter**: una app Flutter (Android + web) contra un servidor Serverpod, con dos partes:

- **Tienda** (cliente): catálogo, carrito, pedidos, seguimiento.
- **Panel admin** (`/admin`, interno): productos, pedidos, inventario, estadísticas, promociones.

La web Next.js, la API NestJS y la app Kotlin de antes ya se retiraron (siguen en el historial de git).

Documento de referencia completo con arquitectura, roadmap y prompts sugeridos: `docs/ARQUITECTURA_Y_ROADMAP.md`. Léelo antes de empezar cualquier feature grande. Para correr y presentar la demo: `docs/DEMO.md`.

## Stack

| Componente | Tecnología |
|---|---|
| App (Android + web) | Flutter en `/apps/client`, con Riverpod y go_router |
| Servidor | Serverpod 4 (Dart) en `/apps/server`: rutas REST en el puerto 8082 |
| Base de datos | PostgreSQL, base `abarrotes_server` |
| Auth | Firebase Auth (ID token). Los permisos del personal viven en Postgres: roles con permisos (`staff_roles`) asignados por correo (`staff_members`) |
| Hosting objetivo | Servidor + DB en Railway o Render, la web de Flutter en Vercel, app en Google Play |

## Estructura del repo

```
/apps
  /server         -> Serverpod (Dart): abarrotes_server + cliente generado
  /client         -> Flutter (Android + web): tienda y panel, contra apps/server
/docs
  ARQUITECTURA_Y_ROADMAP.md
  DEMO.md
/.githooks        -> pre-push: bloquea el push directo a main y develop
```

## Convenciones

- **Commits**: Conventional Commits (`feat:`, `fix:`, `chore:`, `refactor:`). Un commit = un cambio lógico.
- **Ramas**: `main` (estable) ← `develop` ← `feature/<nombre-corto>`. Nunca commitear directo a `main`. `main` y `develop` solo reciben cambios por Pull Request: el hook `.githooks/pre-push` bloquea el push directo a ambas. Se activa una vez por clon con `git config core.hooksPath .githooks`.
- **Nombres**: entidades y tablas en inglés (`Product`, `Order`), texto de UI en español.
- **Serverpod**: un dominio por carpeta en `apps/server/abarrotes_server/lib/src/<dominio>/`, con sus modelos `.spy.yaml`, su servicio y sus rutas. Ningún dominio importa la lógica de otro (`auth`, `common` y `push` son infraestructura compartida). `lib/src/generated/` y `abarrotes_client` los escribe `serverpod generate`: no se editan a mano. Montos en céntimos enteros (`priceCents`) y como texto en el JSON (`"4.5"`). Cada dominio expone `List<RouteEntry>` con `ApiRoute`s (rutas REST con el JSON que lee la app), valida con `InputReader` y protege cada ruta con un permiso: `guards.require(Permission.x, ruta)` (el catálogo de permisos es el enum `Permission`, en `staff/`), con su fila en `test/unit/auth/route_permissions_test.dart`; se registran con `addRoutes` en `lib/server.dart`. Nada de registro o login propios (los hace Firebase). Patrón completo: `apps/server/README.md`.
- **Flutter (`apps/client`)**: una carpeta por sección en `lib/features/<sección>/`. El estado va con Riverpod (providers, nada de `setState` para datos compartidos) y las rutas con go_router (paths en `router/routes.dart`). Las rutas protegidas se deciden en `router/route_guard.dart`, nunca dentro de una pantalla. Firebase, HTTP y el almacenamiento local solo detrás de repositorios (interfaz + implementación, como `auth/` y `users/`) expuestos con providers: las pantallas no los llaman directo, y los tests los reemplazan por versiones en memoria. Colores y tipografía solo desde `lib/theme/`: nada de colores sueltos.
- **Estados de pedido**: enum fijo — `pendingConfirmation`, `confirmed`, `outForDelivery`, `delivered`, `cancelled`. No agregar estados nuevos sin actualizar el servidor, la app Flutter y `docs/ARQUITECTURA_Y_ROADMAP.md`.

## Cómo trabajar en este repo

- Antes de tocar el modelo de datos, revisa los `.spy.yaml` de `apps/server`: son la fuente de verdad. Después de editarlos, `serverpod generate` y una migración. Cambios ahí se coordinan con el equipo antes de hacer merge.
- Antes de crear un endpoint nuevo, revisa si ya existe un dominio de Serverpod para eso.
- Para cambios grandes (nueva entidad, cambio de arquitectura, nueva integración externa), usa modo plan primero y confirma con la persona antes de escribir código.
- Corre los tests del paquete que tocaste antes de dar por terminada una tarea.
- Si un cambio deja desactualizado `docs/ARQUITECTURA_Y_ROADMAP.md`, actualízalo en el mismo commit.

## Comandos frecuentes

```bash
# Cliente Flutter (desde apps/client)
flutter pub get                            # la primera vez y después de cambiar dependencias
flutter run -d chrome                      # o -d <dispositivo>; flutter devices los lista
flutter analyze
flutter test

# Serverpod (desde apps/server/abarrotes_server; la CLI necesita Flutter en el PATH o CI=true)
dart pub get
dart run bin/main.dart                     # servidor: rutas REST en el puerto 8082
dart run bin/seed_dev.dart                 # datos de ejemplo en la base de development (--reiniciar: con fechas hasta hoy)
serverpod generate                         # después de editar un .spy.yaml
serverpod create-migration                 # y luego: dart run bin/main.dart --role maintenance --apply-migrations
dart test                                  # unitarios + integración con PostgreSQL
```

Requisitos y detalles de Serverpod (Dart SDK, `passwords.yaml`, Firebase, primer admin): `apps/server/README.md`. Del cliente Flutter (versión de Flutter, config de Firebase, `API_URL`, tema, rutas): `apps/client/README.md`.
