# Sistema Integral de Ventas y Distribución — Arquitectura y hoja de ruta

Guía técnica para el equipo. Complementa `CLAUDE.md` (que vive en la raíz del repo y es lo que lee Claude Code automáticamente). Para correr y presentar la demo: `docs/DEMO.md`.

## 1. Resumen del proyecto

Plataforma de ecommerce para una tienda de abarrotes (Neil's Food Services), con dos caras sobre un mismo servidor:

- **Tienda** — catálogo, carrito, pedidos y seguimiento para el cliente, en Android y en el navegador.
- **Panel** — gestión de pedidos, productos, inventario, estadísticas y promociones para la tienda.

Las dos están en **una sola app Flutter** (`apps/client`), contra un servidor **Serverpod** en Dart (`apps/server`) con una **base de datos central**, así la tienda y el panel muestran siempre la misma información (stock, precios, estado de pedidos).

## 2. Stack y por qué

| Componente | Tecnología | Por qué |
|---|---|---|
| App (Android + web) | **Flutter** + Riverpod + go_router | Pedido del cliente: una sola base de código para Android y la web, para la tienda y el panel. |
| Servidor | **Serverpod 4** (Dart) | Pedido del cliente: el mismo lenguaje que la app, con modelos y migraciones generados. |
| Base de datos | **PostgreSQL** | Relacional, con transacciones ACID: un pedido descuenta stock y registra el movimiento a la vez. |
| Cuentas | **Firebase Auth** | Registro, ingreso y contraseñas los maneja Firebase. El servidor verifica el ID token en cada petición y guarda el rol (`customer`, `staff`, `admin`) en Postgres. |

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

- `users`: `GET /users/me` devuelve el usuario del Firebase ID token (con `isVip`) y la primera vez lo crea como cliente; `POST /users` (solo admin) crea cuentas admin o staff vinculadas a un `firebaseUid`.
- `categories` y `products`: lectura pública y escritura para admin/staff. Cada producto muestra la mejor promoción vigente que puede usar quien mira.
- `promotions`: CRUD para admin/staff, con el estado según la fecha y la audiencia (`everyone` o `vip`); `GET /promotions/active`, pública, con las vigentes que el cliente puede usar.
- `vip`: la lista de clientes VIP por correo (`/vip-customers`): admin la modifica, staff solo la lee. Es VIP quien tiene su correo en la lista **y** verificado en Firebase. Las reglas de audiencia se inyectan, así un segmento nuevo (p. ej. mayoristas) no toca el resto del código: ver `apps/server/README.md`.
- `inventory` (admin/staff): movimientos de stock (entrada, salida y ajuste con signo) que actualizan `currentStock` en una transacción con la fila bloqueada, su historial, y alertas de stock bajo y de productos por vencer.
- `orders`: del lado del cliente, `POST /orders` (cobra la mejor promoción que el cliente puede usar, nunca el precio que manda la app, y avisa en `priceChanges` si difiere del carrito) y `GET /orders/mine`; para el panel, `GET /orders` con filtros y `PATCH /orders/:id/status` con el patrón State (una clase por estado en `lib/src/orders/states/`).
- `stats` (admin/staff): resumen, ventas por día, más vendidos, stock bajo y por vencer. Cada reporte es una estrategia (`ReportProvider`).

El ID token se verifica en `lib/src/auth/`: firma RS256 con las llaves públicas de Google (cacheadas), `iss`, `aud` y vigencia. Arranque, `passwords.yaml` y primer admin: `apps/server/README.md`.

**Regla de stock de pedidos:** `POST /orders` descuenta el stock al crear el pedido (en `pendingConfirmation`) y registra un movimiento `outgoing`; pasar el pedido a `cancelled` lo devuelve con un movimiento `incoming`. Todo dentro de una transacción, con los productos bloqueados en orden: dos pedidos simultáneos por la última unidad no se pisan ni se traban.

**La app:** una carpeta por sección en `apps/client/lib/features/`, los datos detrás de repositorios con Riverpod, y rutas con go_router. Detalle (tema, rutas, panel, tests): `apps/client/README.md`.

## 4. Modelo de datos

Los `.spy.yaml` del servidor son la fuente de verdad: `User` (con `firebaseUid` y rol), `Category`, `Product` (con stock actual, stock mínimo y vencimiento), `InventoryMovement`, `Supply` (insumos generales), `Order` con su `OrderStatus`, `OrderItem`, `Promotion` (con su `PromotionAudience` y un título opcional) y `VipCustomer` (correo único normalizado, activo o dado de baja, y quién lo agregó).

- **Estados de pedido:** `pendingConfirmation → confirmed → outForDelivery → delivered`, con `cancelled` como ruta alterna.
- **Montos en céntimos enteros** (`priceCents`, `totalCents`, `unitPriceCents`, `promoPriceCents`), porque Serverpod no tiene tipo decimal. En el JSON viajan como texto (`"4.5"`).
- Enums en camelCase. Movimientos: `incoming`, `outgoing`, `adjustment` (`in` es palabra reservada de Dart).
- Ids UUID v7, tablas en plural (`users`, `orders`, …) y claves foráneas `ON DELETE RESTRICT ON UPDATE CASCADE`.

Lo normal es que el modelo crezca (por ejemplo, direcciones múltiples por cliente o historial de precios). Para cambiarlo: editar el `.spy.yaml`, correr `serverpod generate` y `serverpod create-migration`, y commitear la migración. Nunca editar la base a mano.

## 5. Hoja de ruta

**Hecho:**

- **Fundamentos:** el repo, el CI, PostgreSQL, el servidor Serverpod con el modelo completo y su migración inicial, y la verificación del Firebase ID token con el guard por rol.
- **Tienda (cliente):**
  - registro e ingreso con Firebase;
  - catálogo con búsqueda y categorías, y detalle de producto;
  - carrito guardado en el dispositivo;
  - pedido, y "Mis pedidos" con el seguimiento de cada uno.
- **Panel:**
  - inicio con ventas de hoy, la semana y el mes, ticket promedio, pedidos por estado, gráfico de 30 días, stock bajo, por vencer y top 5;
  - pedidos con el stepper de estado y actualización automática;
  - productos, inventario (entradas, salidas y ajustes) y promociones.
- **Clientes VIP (servidor):** la lista de VIPs, promociones para todos o solo VIP, el catálogo y los pedidos con el precio de cada cliente.
- **Para la demo:**
  - datos de ejemplo (`dart run bin/seed_dev.dart`, con `--reiniciar` para fechas hasta hoy);
  - la app web en release;
  - un teléfono Android por cable USB (ver `docs/DEMO.md`).

**Pendiente:**

1. **Probar la app en teléfonos Android reales**, de varias marcas y gamas.
2. **Publicar:** servidor y PostgreSQL en Railway o Render, la web en Vercel y la app en Google Play.
3. **Clientes VIP en la app** (el servidor ya está):
   - pantalla del panel para agregar y quitar VIPs;
   - elegir la audiencia y el título en el formulario de promociones;
   - avisar en el carrito cuando `priceChanges` trae precios distintos;
   - enviar el correo de verificación de Firebase: sin verificar, nadie es VIP.
4. **Fotos de los productos:** subirlas desde el panel; hoy solo se puede pegar una URL.
5. **Negocio real:**
   - pasarela de pago;
   - notificaciones (push o email) de cambio de estado;
   - recuperar la contraseña.

   Si formalizan el negocio en Perú y superan los umbrales de SUNAT, van a necesitar emitir comprobantes electrónicos: eso se integra vía un proveedor como Nubefact, no se construye desde cero.
6. **Más gestión en el panel:**
   - categorías;
   - cuentas del personal;
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
