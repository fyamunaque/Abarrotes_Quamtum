# Servidor Serverpod — Abarrotes

Backend nuevo en Dart con [Serverpod 4](https://docs.serverpod.dev), que irá reemplazando a la
API NestJS de `apps/api`. Mientras conviven, cada uno usa **su propia base** en el mismo
PostgreSQL local: `abarrotes` (Prisma, con los datos de la demo) y `abarrotes_server` (Serverpod).
No compartas la base: Prisma y Serverpod borran las tablas que no reconocen.

## Estructura

```
apps/server/
  pubspec.yaml            -> workspace de Dart (server + client)
  abarrotes_server/       -> el servidor
    bin/main.dart
    config/               -> development / test / staging / production (+ passwords.yaml, no versionado)
    lib/server.dart       -> arma el pod
    lib/src/<dominio>/    -> modelos (.spy.yaml) y código de cada dominio
    lib/src/generated/    -> lo escribe `serverpod generate`: no se edita a mano
    migrations/           -> migraciones generadas, se versionan
    test/
  abarrotes_client/       -> cliente Dart generado (lo exige el generador; Android y web no lo usan)
```

Un dominio por carpeta (`users`, `categories`, `products`, `inventory`, `supplies`, `orders`,
`promotions`): ningún dominio importa la lógica de otro.

## Requisitos

- **Dart SDK ≥ 3.12** (probado con 3.13.5). En Windows: descomprimir el zip oficial de
  [dart.dev](https://dart.dev/get-dart/archive) en `%LOCALAPPDATA%\dart-sdk` y agregar al `Path`
  del usuario `%LOCALAPPDATA%\dart-sdk\bin` y `%LOCALAPPDATA%\Pub\Cache\bin`.
- **CLI de Serverpod**, misma versión que el paquete:

  ```powershell
  dart pub global activate serverpod_cli 4.0.3
  ```

  La CLI exige Flutter salvo en CI. Este proyecto es solo de servidor y no lo necesita: antes de
  usar `serverpod` en una terminal, marca la sesión como CI.

  ```powershell
  $env:CI = 'true'
  ```

- **PostgreSQL** local (el mismo que usa `apps/api`). El usuario `abarrotes` necesita permiso
  `CREATEDB`: los tests crean y borran bases temporales. También necesita `pg_signal_backend`:
  al borrar una base temporal, PostgreSQL a veces tiene que cortar un proceso de autovacuum que
  trabaja en ella. Sin ese permiso, algún grupo falla de vez en cuando en su `tearDownAll` y deja
  una base `sp_test_*`. Se otorga una vez, como superusuario:

  ```powershell
  & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U postgres -c "GRANT pg_signal_backend TO abarrotes"
  ```

## Primera vez

1. Crear la base del servidor (con el usuario `abarrotes`, no hace falta superusuario):

   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U abarrotes -d abarrotes -c "CREATE DATABASE abarrotes_server"
   ```

2. Crear `abarrotes_server/config/passwords.yaml` (está en `.gitignore`):

   ```yaml
   shared:
     # Proyecto de Firebase cuyos ID tokens acepta el servidor (no es secreto).
     firebaseProjectId: '<project id de Firebase>'
   development:
     database: '<contraseña del usuario abarrotes>'
     serviceSecret: '<cadena aleatoria larga>'
   test:
     database: '<contraseña del usuario abarrotes>'
   ```

   En CI o en un servidor, las mismas claves llegan por variables de entorno:
   `SERVERPOD_PASSWORD_database`, `SERVERPOD_PASSWORD_serviceSecret`, etc. El project id
   también puede venir de `FIREBASE_PROJECT_ID`. Sin él, el servidor no arranca.

3. Dependencias y migraciones, desde `apps/server/abarrotes_server`:

   ```powershell
   dart pub get
   dart run bin/main.dart --role maintenance --apply-migrations
   ```

4. Opcional, para probar la app: datos de ejemplo. Solo corre en `development` y no toca la base
   `abarrotes` de la demo.
   - **El catálogo:** 9 categorías (las de la web Next.js, ya retirada) y 25 productos, sin
     imágenes. Uno tiene una promoción vigente por 30 días y otro está agotado. Completa lo que
     falta: agrega las categorías y los productos (por SKU) que no están, y nunca toca uno que ya
     existe, aunque se haya editado o dado de baja.
   - **Pedidos:** 40 pedidos de 1 a 3 productos, repartidos en los últimos 30 días, para que el
     panel tenga ventas, top 5 y pedidos por estado. Los dos más recientes esperan confirmación,
     dos están confirmados y dos en camino; los demás, entregados o cancelados.
     - Son de un cliente de ejemplo (`seed-cliente-demo`), que no es una cuenta de Firebase:
       no se puede ingresar con él.
     - No tocan el stock: son historia de ejemplo.
     - No hace nada si ya hay pedidos.
   - **Alertas:** el yogurt vence en 3 días y la leche en 10 (si no tenían fecha). El mínimo de
     la lejía sube a 20, así queda en stock bajo junto con el azúcar agotado.

   ```powershell
   dart run bin/seed_dev.dart
   ```

## Día a día (desde `apps/server/abarrotes_server`)

| Qué | Comando |
|---|---|
| Levantar el servidor (API 8088, Insights 8081, web 8082) | `dart run bin/main.dart` |
| Regenerar código tras editar un `.spy.yaml` | `serverpod generate` |
| Crear la migración de ese cambio (se commitea) | `serverpod create-migration` |
| Aplicar migraciones pendientes | `dart run bin/main.dart --role maintenance --apply-migrations` |
| Análisis estático | `dart analyze` |
| Tests (unitarios + integración con PostgreSQL) | `dart test` |

## Autenticación con Firebase

Las cuentas viven en **Firebase Auth**: el servidor no guarda contraseñas. Cada petición
protegida trae el ID token de Firebase en `Authorization: Bearer <token>`, y el servidor:

- Verifica la firma RS256 con las llaves públicas de Google
  (`securetoken@system.gserviceaccount.com`). Las cachea según su `Cache-Control` y las vuelve a
  descargar si Google las rota.
- Exige `iss = https://securetoken.google.com/<project id>`, `aud = <project id>`, el token
  vigente y un `sub` (el uid) no vacío.
- Busca al usuario por `firebaseUid` en `users`. Ahí viven el **rol** y los datos de la tienda.

Código en `lib/src/auth/`: `GooglePublicKeys` (llaves), `FirebaseTokenVerifier`,
`firebaseAuthMiddleware` (rutas REST) y `firebaseAuthenticationHandler`. Este último autentica
también la sesión de Serverpod con el uid, para los endpoints que se agreguen después.

No hay registro ni login propios: los hace Firebase. El "registro" en la tienda es la primera
llamada a `GET /users/me`, que siempre crea un `customer`. Ningún rol que mande el cliente se
toma en cuenta.

### Proteger una ruta por rol

`RoleGuard` es el equivalente a `@Roles(...)` de NestJS: envuelve una ruta y responde 401 (sin
token o inválido), 503 (sin llaves de Google) o 403 (el rol no alcanza) antes de que la ruta lea
el body. Si deja pasar, la ruta tiene al usuario en `request.currentUser`. Las lecturas públicas
que muestran más al staff (p. ej. productos inactivos) usan `optionalUser`: un token ausente o
inválido cuenta como visitante.

## CORS (la app web)

La app Flutter web corre en otro origen (p. ej. `http://localhost:5006`) y llama a las rutas
REST del 8082, así que el navegador primero manda un preflight `OPTIONS`. `corsMiddleware`
(`lib/src/common/cors.dart`) se registra en `/` y envuelve a los middlewares de cada dominio:
el preflight no trae token, y el de Firebase en `/users` lo rechazaría.

- Con un origen permitido, responde el preflight con 204 y agrega
  `Access-Control-Allow-Origin` a todas las respuestas, también a los errores (la app tiene que
  poder leer un 401).
- A un origen no permitido no le agrega nada: el navegador bloquea la respuesta. Sin `Origin`
  (curl, la app Android) todo sigue igual.
- Orígenes permitidos: en `development`, cualquier `http://localhost:<puerto>`. En staging y
  producción, solo los de la variable `ALLOWED_ORIGINS`, separados por comas:

  ```powershell
  $env:ALLOWED_ORIGINS = 'https://tienda.pe,https://admin.tienda.pe'
  ```

## Cómo se arma un dominio

Cada dominio expone una lista de rutas `(path, ruta)` y su servicio (ver `lib/src/categories/`):

```dart
List<RouteEntry> categoriesRoutes(CategoriesService categories, FirebaseTokenVerifier verifier) => [
  ('/categories', ApiRoute(Method.get, (session, request) async => ...)),            // pública
  ('/categories', RoleGuard(staffRoles, ApiRoute(Method.post, ...), verifier: verifier)),
];
```

- `ApiRoute` es una ruta de un solo método. Un `ApiException` que lance se convierte en
  `{statusCode, message, error}`.
- `addRoutes` registra la lista en `server.dart`. Serverpod admite **una sola ruta por path**, así
  que las que comparten path se juntan en una que despacha según el método (`mergeByPath`).
  Cada path responde además `OPTIONS`: sin eso, el router contesta 405 al preflight de CORS
  antes de correr cualquier middleware.
- `InputReader` valida el body o el query como el ValidationPipe de NestJS. Junta todos los
  errores en un 400 y rechaza las propiedades no permitidas.
- Montos en céntimos en la base y como texto en el JSON (`formatMoney`: 450 → `"4.5"`). Los días
  de la tienda (`AAAA-MM-DD`) se manejan en hora de Lima (`common/store_time.dart`).
- Tests de integración: `serveRoutes` (en `test/support/`) monta las rutas igual que Serverpod,
  con la sesión del test, y `TestClient` firma tokens de prueba por uid.

## Endpoints (servidor web, puerto 8082)

El JSON tiene la misma forma que la API NestJS (`packages/shared-types`): precios como texto
(`"4.5"`), listados `{data, meta}` con `?page=` y `?limit=` (1 a 100, por defecto 20) y fechas de
promoción como días de Lima. Lo único distinto: los enums van como en los modelos de Serverpod
(`customer`, `active`…).

| Método y ruta | Quién | Qué hace |
|---|---|---|
| `GET /users/me` | cualquiera con token | Devuelve el usuario del token. La primera vez lo crea como `customer` con el email y el nombre de Firebase. |
| `POST /users` | solo `admin` | Crea una cuenta `admin` o `staff` vinculada a un `firebaseUid` existente. Es la única forma de tener esos roles. |
| `GET /categories`, `GET /categories/:id` | público | Categorías por nombre. |
| `POST /categories`, `PATCH /categories/:id` | admin, staff | `{name}`. El nombre no se repite, sin distinguir mayúsculas (409). |
| `DELETE /categories/:id` | admin, staff | 204, o 409 si todavía tiene productos (aunque estén inactivos). |
| `GET /products` | público | Paginado, por nombre. Filtros: `categoryId`, `search` (nombre o SKU), `onSale=true` (con promoción vigente) e `includeInactive=true` (solo surte efecto para admin y staff). |
| `GET /products/:id` | público | Un inactivo es 404, salvo para admin y staff. |
| `POST /products` | admin, staff | `{name, sku, price, categoryId, description?, imageUrl?, active?, currentStock?, minStock?, expirationDate?}`. SKU repetido 409, categoría inexistente 400. `currentStock` es solo el stock inicial. |
| `PATCH /products/:id` | admin, staff | Campos parciales; `null` borra `description`, `imageUrl` y `expirationDate`. El stock no se edita aquí. |
| `DELETE /products/:id` | admin, staff | Baja lógica (`active: false`); devuelve el producto. |
| `GET /promotions`, `GET /promotions/:id` | admin, staff | Paginado, el inicio más reciente primero. Filtros: `productId`, `status` (`scheduled`, `active`, `expired`, `disabled`). |
| `POST /promotions` | admin, staff | `{productId, promoPrice, startDate, endDate, active?}`, días `AAAA-MM-DD` ambos incluidos. |
| `PATCH /promotions/:id` | admin, staff | Cambia precio, fechas o `active`; el producto no cambia. |
| `DELETE /promotions/:id` | admin, staff | 204. |
| `POST /inventory/movements` | admin, staff | `{productId, type, quantity, reason?}` con `type` igual a `incoming`, `outgoing` o `adjustment`. Actualiza `currentStock` y registra el movimiento a nombre de quien lo hace, en una sola transacción. Responde el movimiento con el stock nuevo. |
| `GET /inventory/movements` | admin, staff | Historial paginado, el más reciente primero; `?productId=` filtra (404 si el producto no existe). |
| `GET /inventory/alerts/low-stock` | admin, staff | `{data}`: productos activos con `currentStock <= minStock`, los más críticos primero, con `shortage` (lo que falta para el mínimo). |
| `GET /inventory/alerts/expiring?days=7` | admin, staff | `{days, until, data}`: productos activos con stock que vencen hasta hoy + `days` (1 a 365), incluidos los ya vencidos, con `daysLeft` (negativo = vencido). |
| `POST /orders` | cualquiera con cuenta | `{deliveryAddress, items: [{productId, quantity}]}` (de 1 a 100 líneas; cantidad de 1 a 999). Sin precios ni total: el servidor cobra el precio de hoy, el de la promoción vigente si la hay. El pedido queda a nombre de quien lo crea, en `pendingConfirmation`, y descuenta el stock. Producto dado de baja o inexistente: 400 (`Ya no están disponibles: ...`). Stock insuficiente: 409. En los dos casos no se guarda nada. Responde 201 con el pedido. |
| `GET /orders/mine` | cualquiera con cuenta | Los pedidos propios con sus líneas, paginados, los más recientes primero. |
| `GET /orders` | admin, staff | Pedidos con sus líneas y cliente, paginados, los más recientes primero. Filtros: `status`, `from` y `to` (días de Lima `AAAA-MM-DD`, ambos incluidos). |
| `PATCH /orders/:id/status` | admin, staff | `{status}`. Valida la transición contra el estado actual (patrón State): si no está permitida, 400 con el motivo. |
| `GET /stats/overview` | admin, staff | Ventas de hoy, de la semana (desde el lunes) y del mes, con total, pedidos y ticket promedio, y los pedidos en cada estado. |
| `GET /stats/sales?from=&to=` | admin, staff | Resumen y un punto por día (los días sin ventas van en 0). Sin rango, los últimos 30 días; como máximo 366. |
| `GET /stats/top-products?from=&to=&limit=5` | admin, staff | Los más vendidos por unidades (a igual cantidad, por facturación), `limit` de 1 a 50. |
| `GET /stats/low-stock`, `GET /stats/expiring?days=7` | admin, staff | Las mismas alertas (y el mismo JSON) que `/inventory/alerts/*`. |

Estados de pedido (`lib/src/orders/states/`, una clase por estado): `pendingConfirmation` →
`confirmed` → `outForDelivery` → `delivered`. Se puede cancelar (`cancelled`) mientras no se haya
entregado; `delivered` y `cancelled` son finales. Reglas del cambio de estado:

- Cancelar devuelve al inventario lo que el pedido descontó: una entrada por línea, a nombre de
  quien cancela. Lo hace el servicio de inventory dentro de la misma transacción.
- La fila del pedido se bloquea durante el cambio. Si dos personas lo cambian a la vez, la segunda
  espera y se valida contra el estado ya cambiado (400 con el motivo), así el stock nunca se
  devuelve dos veces.

Al crear un pedido (`OrdersService.create`), todo pasa en una transacción:

- Los productos se bloquean (`FOR UPDATE`) al leerlos, en orden por id y antes de escribir nada.
  Así dos pedidos a la vez por las últimas unidades se ordenan ahí: uno pasa y el otro recibe
  409.
- Si el bloqueo se hiciera recién al descontar el stock, se trabarían. Cada uno ya tendría la
  fila tomada por la clave foránea de sus líneas (deadlock). El test de concurrencia lo cubre.
- El stock se descuenta con `InventoryService.record` (una salida por producto, a nombre del
  cliente, con el motivo `Pedido <id>`). Si no alcanza, su 409 deshace también el pedido.

Estadísticas (`lib/src/stats/`): cada reporte es una estrategia que extiende `ReportProvider`
(`SalesReportProvider`, `TopProductsReportProvider`, `OrderStatusReportProvider`,
`LowStockReportProvider`, `ExpiringProductsReportProvider`). Cada uno se inyecta por separado en
`statsRoutes` desde `server.dart`. Reglas:

- El overview no consulta la base: compone el reporte de ventas y el de pedidos por estado, que
  recibe como abstracciones.
- Las ventas cuentan solo pedidos aceptados (`confirmed`, `outForDelivery`, `delivered`) y se
  agrupan por día de Lima en la base.
- Stock bajo y por vencer reutilizan `StockAlerts` de inventory.

Reglas de los movimientos de inventario:

- Entrada y salida llevan `quantity` positiva. El ajuste lleva la corrección con signo (`-3` por
  merma, `+5` tras un conteo), distinta de 0, y `reason` es obligatorio. Así la suma del
  historial siempre da el stock.
- Si el stock quedaría negativo, 409 y no cambia nada.
- La fila del producto se bloquea (`FOR UPDATE`) durante la transacción: dos movimientos
  simultáneos no pueden pisarse.

Cada producto trae su categoría y `promotion`, la promoción vigente o `null`. Reglas de las
promociones (`lib/src/promotions/promotion_rules.dart`):

- El estado sale de la fecha y del interruptor `active`; no se guarda.
- `promoPrice` tiene que ser menor al precio normal (400).
- Dos promociones encendidas del mismo producto no pueden cruzarse en el tiempo (409).

Usuarios: la respuesta es `{id, email, name, phone, role, address, createdAt}`. Errores comunes a
todas las rutas, con la forma de la API NestJS (`{statusCode, message, error}`):

- 400: body o query inválidos (con la lista de errores), o token sin email en `/users/me`.
- 401: sin token o con uno inválido.
- 403: el rol no alcanza.
- 404: no existe.
- 409: conflicto (duplicados, categoría con productos, promociones que se cruzan, stock
  insuficiente).
- 503: no se pudieron obtener las llaves de Google.

### Primer admin

`POST /users` exige un admin, así que el primero se crea a mano:

1. La persona inicia sesión una vez en la app o la web; `GET /users/me` la crea como cliente.
2. Se le cambia el rol en la base:

   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U abarrotes -d abarrotes_server -c "UPDATE users SET role = 'admin' WHERE email = 'correo@ejemplo.com'"
   ```

### Probar con un token real

Desde la app o la web ya logueadas con Firebase, `await user.getIdToken()` entrega el token
(dura una hora). Con él:

```powershell
curl.exe -H "Authorization: Bearer <token>" http://localhost:8082/users/me
```
