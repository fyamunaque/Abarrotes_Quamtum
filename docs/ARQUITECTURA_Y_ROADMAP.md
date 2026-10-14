# Sistema Integral de Ventas y Distribución — Arquitectura y hoja de ruta

Guía técnica para el equipo. Complementa `CLAUDE.md` (que vive en la raíz del repo y es lo que lee Claude Code automáticamente). Para correr y presentar la demo: `docs/DEMO.md`.

## 1. Resumen del proyecto

Plataforma de ecommerce para una tienda de abarrotes (Neil's Food Services), con dos caras sobre un mismo servidor:

- **Tienda** — catálogo, carrito, pedidos y seguimiento para el cliente, en Android y en el navegador.
- **Panel** — gestión de pedidos, productos, inventario, estadísticas, promociones y clientes VIP para la tienda.

Las dos están en **una sola app Flutter** (`apps/client`), contra un servidor **Serverpod** en Dart (`apps/server`) con una **base de datos central**, así la tienda y el panel muestran siempre la misma información (stock, precios, estado de pedidos).

## 2. Stack y por qué

| Componente | Tecnología | Por qué |
|---|---|---|
| App (Android + web) | **Flutter** + Riverpod + go_router | Pedido del cliente: una sola base de código para Android y la web, para la tienda y el panel. |
| Servidor | **Serverpod 4** (Dart) | Pedido del cliente: el mismo lenguaje que la app, con modelos y migraciones generados. |
| Base de datos | **PostgreSQL** | Relacional, con transacciones ACID: un pedido descuenta stock y registra el movimiento a la vez. |
| Cuentas | **Firebase Auth** | Registro, ingreso y contraseñas los maneja Firebase. El servidor verifica el ID token en cada petición; los permisos del personal (roles con permisos, asignados por correo) viven en Postgres. |

## 3. Estructura del repo

```
/apps
  /server         -> Serverpod: abarrotes_server (el servidor) + abarrotes_client (generado)
  /client         -> Flutter: tienda y panel, para Android y web
/docs
  ARQUITECTURA_Y_ROADMAP.md
  DEMO.md
/.githooks        -> pre-push: bloquea el push directo a main y develop
/.github          -> CI
CLAUDE.md
```

**El servidor:** cada dominio tiene su carpeta en `apps/server/abarrotes_server/lib/src/<dominio>/`, con sus modelos `.spy.yaml`, servicio y rutas. Las rutas REST corren en el servidor web de Serverpod (puerto 8082):

- `users`: `GET /users/me` devuelve el usuario del Firebase ID token (con `isVip`, su rol de personal y sus permisos) y la primera vez lo crea. `GET /customers` (`customers.view`): el listado de clientes para el panel.
- `staff`: roles y permisos del personal. Un catálogo de permisos (`Permission`), roles editables más el Administrador de sistema, el personal por correo (con el correo verificado) y una bitácora. Cada ruta del panel pide su permiso (`guards.require`), nunca solo "ser del personal": un test compara cada ruta con su permiso. `/staff/*` (`staff.manage`) los administra.
- `categories` y `products`: lectura pública; escritura con `categories.manage` y `products.manage`. Cada producto muestra la mejor promoción vigente que puede usar quien mira.
- `promotions`: CRUD con `promotions.manage`, con el estado según la fecha y la audiencia (`everyone` o `vip`); `GET /promotions/active`, pública, con las vigentes que el cliente puede usar.
- `vip`: la lista de clientes VIP por correo (`/vip-customers`): se ve con `vip.view` y se modifica con `vip.manage`. Es VIP quien tiene su correo en la lista **y** verificado en Firebase. Las reglas de audiencia se inyectan, así un segmento nuevo (p. ej. mayoristas) no toca el resto del código: ver `apps/server/README.md`. Al crear una promoción VIP que ya rige, avisa por push (FCM HTTP v1, token por token) a los VIP con el correo verificado, sin bloquear la creación.
- `push` (infraestructura): el envío con FCM. Los dispositivos se registran en `PUT /users/me/devices`.
- `inventory`: movimientos de stock (registrarlos pide `inventory.adjust`; verlos y las alertas, `inventory.view`) (entrada, salida y ajuste con signo) que actualizan `currentStock` en una transacción con la fila bloqueada, su historial, y alertas de stock bajo y de productos por vencer.
- `orders`: del lado del cliente, `POST /orders` (cobra la mejor promoción que el cliente puede usar, nunca el precio que manda la app, y avisa en `priceChanges` si difiere del carrito) y `GET /orders/mine`; para el panel, `GET /orders` (`orders.view`) con filtros (también por tipo de entrega) y `PATCH /orders/:id/status` (`orders.updateStatus`) con el patrón State (una clase por estado en `lib/src/orders/states/`) y el flujo de cada tipo de entrega como Strategy (`lib/src/orders/fulfillment/`). A domicilio o con recojo en tienda: recoger en caja pide el código del cliente.
- `stats` (`stats.view`): resumen, ventas por día, más vendidos, stock bajo y por vencer. Cada reporte es una estrategia (`ReportProvider`).

El ID token se verifica en `lib/src/auth/`: firma RS256 con las llaves públicas de Google (cacheadas), `iss`, `aud` y vigencia. Arranque, `passwords.yaml` y primer admin: `apps/server/README.md`.

**Regla de stock de pedidos:** `POST /orders` descuenta el stock al crear el pedido (en `pendingConfirmation`) y registra un movimiento `outgoing`; pasar el pedido a `cancelled` lo devuelve con un movimiento `incoming`. Todo dentro de una transacción, con los productos bloqueados en orden: dos pedidos simultáneos por la última unidad no se pisan ni se traban.

**La app:** una carpeta por sección en `apps/client/lib/features/`, los datos detrás de repositorios con Riverpod, y rutas con go_router. Detalle (tema, rutas, panel, tests): `apps/client/README.md`.

## 4. Modelo de datos

Los `.spy.yaml` del servidor son la fuente de verdad: `User` (con `firebaseUid`), `Role`, `StaffMember` y `AuditLog` (los permisos del personal, con el enum `Permission`), `Category`, `Product` (con stock actual, stock mínimo y vencimiento), `InventoryMovement`, `Supply` (insumos generales), `Order` con su `OrderStatus`, `OrderItem`, `Promotion` (con su `PromotionAudience` y un título opcional) y `VipCustomer` (correo único normalizado, activo o dado de baja, y quién lo agregó).

- **Estados de pedido y tipos de entrega:** cada pedido es a domicilio (`delivery`, por defecto) o de recojo en tienda (`pickup`, con un `pickupCode` de 6 caracteres sin 0/O/1/I, único). A domicilio: `pendingConfirmation → confirmed → outForDelivery → delivered`; con recojo: `pendingConfirmation → confirmed → preparing → readyForPickup → delivered` ("recogido", con el código del cliente). En los dos, `cancelled` es la ruta alterna hasta antes de entregar. El flujo de cada tipo es un Strategy (`FulfillmentFlow`) que consultan los estados (State); el JSON trae `allowedNextStatuses`.
- **Montos en céntimos enteros** (`priceCents`, `totalCents`, `unitPriceCents`, `promoPriceCents`), porque Serverpod no tiene tipo decimal. En el JSON viajan como texto (`"4.5"`).
- Enums en camelCase. Movimientos: `incoming`, `outgoing`, `adjustment` (`in` es palabra reservada de Dart).
- Ids UUID v7, tablas en plural (`users`, `orders`, …) y claves foráneas `ON DELETE RESTRICT ON UPDATE CASCADE`.

Lo normal es que el modelo crezca (por ejemplo, direcciones múltiples por cliente o historial de precios). Para cambiarlo: editar el `.spy.yaml`, correr `serverpod generate` y `serverpod create-migration`, y commitear la migración. Nunca editar la base a mano.

## 5. Hoja de ruta

**Hecho:**

- **Fundamentos:** el repo, el CI, PostgreSQL, el servidor Serverpod con el modelo completo y su migración inicial, y la verificación del Firebase ID token con los guards por permiso.
- **Tienda (cliente):**
  - registro e ingreso con Firebase;
  - catálogo con búsqueda y categorías, y detalle de producto;
  - carrito guardado en el dispositivo;
  - pedido, y "Mis pedidos" con el seguimiento de cada uno.
- **Panel:**
  - inicio con ventas de hoy, la semana y el mes, ticket promedio, pedidos por estado, gráfico de 30 días, stock bajo, por vencer y top 5;
  - pedidos con el stepper de estado y actualización automática;
  - productos, inventario (entradas, salidas y ajustes) y promociones;
  - clientes VIP: la lista con búsqueda; admin agrega (uno o varios pegados) y quita, staff solo la ve;
  - equipo (solo con `staff.manage`): las personas por correo con su rol y estado (agregar uno o varios con un rol, cambiar el rol, desactivar) y los roles con un checklist de permisos por área; el Administrador se ve bloqueado;
  - cada sección y cada botón según los `permissions` de `/users/me` (lo demás, "No tienes acceso a esta sección"), y al ingresar cada uno llega a su sección: la Cajera a Pedidos, el Almacenero a Inventario. Un rol que cambió rige al volver a la app, sin cerrar sesión.
- **Roles y permisos del personal:** en el servidor, permisos por rol, el Administrador de sistema, las plantillas Almacenero y Cajera, el personal por correo, la bitácora y las reglas para no quedarse sin administrador; en el panel, las pestañas Personas y Roles de la sección Equipo, solo con `staff.manage`.
- **Clientes VIP:** en el servidor, la lista de VIPs, promociones para todos o solo VIP, el catálogo y los pedidos con el precio de cada cliente; en el panel, la sección `/admin/clientes-vip` y la audiencia y el título en el formulario de promociones; en la tienda, el precio VIP en el catálogo, las "Ofertas exclusivas", el carrito como estimación con el precio final al pedir, el refresco del perfil sin cerrar sesión y el aviso para verificar el correo.
- **Para la demo:**
  - datos de ejemplo (`dart run bin/seed_dev.dart`, con `--reiniciar` para fechas hasta hoy);
  - la app web en release;
  - un teléfono Android por cable USB (ver `docs/DEMO.md`).

**Pendiente:**

1. **Probar la app en teléfonos Android reales**, de varias marcas y gamas.
2. **Avisos push en la app** (el servidor ya los manda): `firebase_messaging`, pedir el permiso
   de notificaciones, registrar el token con `PUT /users/me/devices` (y quitarlo al salir), en la
   web la clave VAPID y el service worker, y abrir el producto al tocar el aviso. Para que salgan,
   configurar la cuenta de servicio en el servidor (`apps/server/README.md`, "Avisos push").
3. **Publicar:** servidor y PostgreSQL en Railway o Render, la web en Vercel y la app en Google Play.
4. **Fotos de los productos:** subirlas desde el panel; hoy solo se puede pegar una URL.
5. **Negocio real:**
   - pasarela de pago;
   - notificaciones (push o email) de cambio de estado;
   - recuperar la contraseña.

   Si formalizan el negocio en Perú y superan los umbrales de SUNAT, van a necesitar emitir comprobantes electrónicos: eso se integra vía un proveedor como Nubefact, no se construye desde cero.
6. **Recojo en tienda en la app** (el servidor y el seguimiento ya lo tienen): elegir domicilio o recojo en el carrito, y en el panel el filtro por tipo de entrega.
7. **Más gestión en el panel:**
   - el listado de clientes (el servidor ya tiene `GET /customers`);
   - categorías;
   - insumos;
   - exportar a CSV;
   - gráficos por rango de fechas.

**Historia:** el proyecto empezó con una app Kotlin, una web Next.js (tienda y panel) y una API NestJS con Prisma. Por pedido del cliente se pasó todo a Dart y Flutter. Lo que la web tenía y Flutter no (la búsqueda, el carrito guardado, las 9 categorías, los títulos de pestaña) se pasó antes de retirarla. Ese código sigue en el historial de git y en las ramas viejas de GitHub.

## 6. Flujo de trabajo con el equipo y con Claude Code

- **Git**: `main` estable, `develop` como rama de integración, una rama `feature/<nombre>` por tarea. Pull request antes de mergear a `develop`, aunque sea entre ustedes mismos — obliga a revisar el diff.
  - El repo es privado en el plan gratuito de GitHub, que no permite proteger ramas. En su lugar, el hook `.githooks/pre-push` bloquea en cada clon el push directo a `main` y `develop`. Se activa una vez por clon con `git config core.hooksPath .githooks`. Es una barrera contra descuidos, no una restricción real: `git push --no-verify` la salta. Si pasan a GitHub Pro, configuren además la protección de ramas con PR y CI obligatorios.
- **Tareas**: con un equipo tan chico, GitHub Projects (gratis, ligado directo a los issues del repo) alcanza — no hace falta Jira/Trello aparte.
- **Cada quien con Claude Code en su propia rama**, para no pisarse cambios en el mismo archivo a la vez.
- Empiecen cada sesión de Claude Code en la carpeta raíz del repo (para que cargue `CLAUDE.md`), y usen `/clear` al pasar de una tarea a otra sin relación.
- Para algo grande (nueva entidad, integración de pagos, cambio de arquitectura), pídanle a Claude Code que primero les muestre el plan antes de escribir código.
- Revisen el diff antes de aceptar — sobre todo en los `.spy.yaml` y las migraciones, porque un cambio ahí afecta a la tienda y al panel a la vez.

## 7. Herramientas complementarias

- **Probar el servidor mientras se desarrolla**: Insomnia o Postman, o `curl` (ver los ejemplos de `apps/server/README.md`).
- **CI**: GitHub Actions en cada pull request y push a `develop` y `main` (`.github/workflows/ci.yml`), con dos jobs en paralelo:
  - Serverpod, con PostgreSQL efímero: formato, análisis, tests, migraciones y arranque del servidor con un chequeo de 401.
  - App Flutter: formato, análisis, tests y build web.
- **Hosting**: servidor + PostgreSQL en Railway o Render (planes gratuitos o baratos alcanzan para empezar), la web de Flutter en Vercel, app en Google Play Console (pago único de $25).
- **Pagos** (para negocio real en Perú): Culqi o Izipay son las opciones locales más simples de integrar (tarjetas, y Culqi soporta Yape); Mercado Pago es la alternativa regional.
- **Diseño de pantallas** (opcional): si quieren mockups antes de programar, Figma tiene plan gratuito suficiente para un equipo de 2-3.
