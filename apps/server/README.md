# Servidor Serverpod — Abarrotes

El servidor de la tienda, en Dart con [Serverpod 4](https://docs.serverpod.dev). Atiende a la app
Flutter de `apps/client` con rutas REST, verifica las cuentas de Firebase y guarda todo en la base
`abarrotes_server` de PostgreSQL. Usa una base propia: Serverpod borra las tablas que no reconoce.

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
`promotions`, `vip`): ningún dominio importa la lógica de otro. `auth`, `common` y `push` son
infraestructura compartida; lo que un dominio necesita de otro llega por constructor como interfaz
(p. ej. `PromotionPricing`, ver [Clientes VIP](#clientes-vip-y-audiencias-de-las-promociones)).

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

- **PostgreSQL** local (aquí se usa la 18), con un usuario `abarrotes` con permiso `CREATEDB`:
  los tests crean y borran bases temporales. También necesita `pg_signal_backend`:
  al borrar una base temporal, PostgreSQL a veces tiene que cortar un proceso de autovacuum que
  trabaja en ella. Sin ese permiso, algún grupo falla de vez en cuando en su `tearDownAll` y deja
  una base `sp_test_*`. Se otorga una vez, como superusuario:

  ```powershell
  & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U postgres -c "GRANT pg_signal_backend TO abarrotes"
  ```

## Primera vez

1. Crear el usuario y la base, como superusuario `postgres` (elige tu propia clave). Si el
   usuario `abarrotes` ya existe, basta con el segundo comando:

   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U postgres -c "CREATE ROLE abarrotes LOGIN CREATEDB PASSWORD 'tu-clave'"
   ```

   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U postgres -c "CREATE DATABASE abarrotes_server OWNER abarrotes"
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

4. Opcional, para probar la app: datos de ejemplo. Solo corre en `development`.
   - **El catálogo:** 9 categorías y 25 productos, sin imágenes. Uno tiene una promoción vigente
     por 30 días y otro está agotado. Completa lo que falta: agrega las categorías y los
     productos (por SKU) que no están, y nunca toca uno que ya existe, aunque se haya editado o
     dado de baja.
   - **Pedidos:** 40 pedidos de 1 a 3 productos, repartidos en los últimos 30 días, para que el
     panel tenga ventas, top 5 y pedidos por estado. Los dos más recientes esperan confirmación,
     dos están confirmados y dos en camino; los demás, entregados o cancelados.
     - Son de un cliente de ejemplo (`seed-cliente-demo`), que no es una cuenta de Firebase:
       no se puede ingresar con él.
     - No tocan el stock: son historia de ejemplo.
     - No hace nada si el cliente de ejemplo ya tiene pedidos. Los de otras cuentas no cuentan.
   - **Alertas:** el yogurt vence en 3 días y la leche en 10 (si no tenían fecha). El mínimo de
     la lejía sube a 20, así queda en stock bajo junto con el azúcar agotado.

   ```powershell
   dart run bin/seed_dev.dart
   ```

   **Antes de una demo**, con `--reiniciar` los pedidos de ejemplo se vuelven a generar con
   fechas hasta hoy (borra solo los del cliente de ejemplo, con sus items) y los vencimientos del
   yogurt y la leche se fechan desde hoy. Si no, a los días el gráfico termina vacío, "ventas de
   hoy" queda en 0 y los vencimientos pasan. No toca los pedidos de otras cuentas, el resto de
   los productos ni el stock.

   ```powershell
   dart run bin/seed_dev.dart --reiniciar
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

`RoleGuard` protege una ruta por rol: la envuelve y responde 401 (sin
token o inválido), 503 (sin llaves de Google) o 403 (el rol no alcanza) antes de que la ruta lea
el body. Si deja pasar, la ruta tiene al usuario en `request.currentUser` (y la identidad del
token en `request.firebaseIdentity`). Los conjuntos de roles están en `role_guard.dart`:
`staffRoles` (admin y staff), `adminRoles` (solo admin: cuentas del personal y clientes VIP) y
`anyRole`. Las lecturas públicas que muestran más al staff (p. ej. productos inactivos) usan
`optionalUser`: un token ausente o inválido cuenta como visitante.

## CORS (la app web)

La app Flutter web corre en otro origen (p. ej. `http://localhost:5006`) y llama a las rutas
REST del 8082, así que el navegador primero manda un preflight `OPTIONS`. `corsMiddleware`
(`lib/src/common/cors.dart`) se registra en `/` y envuelve a los middlewares de cada dominio:
el preflight no trae token, y el de Firebase en `/users` lo rechazaría.

- Con un origen permitido, responde el preflight con 204 y agrega
  `Access-Control-Allow-Origin` a todas las respuestas, también a los errores (la app tiene que
  poder leer un 401).
- A un origen no permitido no le agrega nada: el navegador bloquea la respuesta. Sin `Origin`
  (curl, la app en Android) todo sigue igual.
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
- `InputReader` valida el body o el query. Junta todos los errores en un 400 y rechaza las
  propiedades no permitidas.
- Montos en céntimos en la base y como texto en el JSON (`formatMoney`: 450 → `"4.5"`). Los días
  de la tienda (`AAAA-MM-DD`) se manejan en hora de Lima (`common/store_time.dart`).
- Tests de integración: `serveRoutes` (en `test/support/`) monta las rutas igual que Serverpod,
  con la sesión del test, y `TestClient` firma tokens de prueba por uid.

## Endpoints (servidor web, puerto 8082)

El JSON es el que lee la app Flutter (los `fromJson` de `apps/client/lib`): precios como texto
(`"4.5"`), listados `{data, meta}` con `?page=` y `?limit=` (1 a 100, por defecto 20) y fechas de
promoción como días de Lima. Lo único distinto: los enums van como en los modelos de Serverpod
(`customer`, `active`…).

| Método y ruta | Quién | Qué hace |
|---|---|---|
| `GET /users/me` | cualquiera con token | Devuelve el usuario del token. La primera vez lo crea como `customer` con el email y el nombre de Firebase. Incluye `isVip`: si puede usar las promociones VIP. Guarda si el correo está verificado (`email_verified` del token). |
| `PUT /users/me/devices` | cualquiera con token | `{token, platform?}` (`platform`: `android` o `web`): registra el token de FCM de un dispositivo para los avisos push. Repetirlo no lo duplica; si el token era de otra cuenta, pasa a esta. 204. |
| `DELETE /users/me/devices?token=…` | cualquiera con token | Lo quita (al cerrar sesión). Solo los tokens propios. 204. |
| `POST /users` | solo `admin` | Crea una cuenta `admin` o `staff` vinculada a un `firebaseUid` existente. Es la única forma de tener esos roles. |
| `GET /categories`, `GET /categories/:id` | público | Categorías por nombre. |
| `POST /categories`, `PATCH /categories/:id` | admin, staff | `{name}`. El nombre no se repite, sin distinguir mayúsculas (409). |
| `DELETE /categories/:id` | admin, staff | 204, o 409 si todavía tiene productos (aunque estén inactivos). |
| `GET /products` | público | Paginado, por nombre. Filtros: `categoryId`, `search` (nombre o SKU), `onSale=true` (con una promoción vigente que quien pregunta puede usar) e `includeInactive=true` (solo surte efecto para admin y staff). |
| `GET /products/:id` | público | Un inactivo es 404, salvo para admin y staff. |
| `POST /products` | admin, staff | `{name, sku, price, categoryId, description?, imageUrl?, active?, currentStock?, minStock?, expirationDate?}`. SKU repetido 409, categoría inexistente 400. `currentStock` es solo el stock inicial. |
| `PATCH /products/:id` | admin, staff | Campos parciales; `null` borra `description`, `imageUrl` y `expirationDate`. El stock no se edita aquí. |
| `DELETE /products/:id` | admin, staff | Baja lógica (`active: false`); devuelve el producto. |
| `GET /promotions`, `GET /promotions/:id` | admin, staff | Paginado, el inicio más reciente primero. Filtros: `productId`, `status` (`scheduled`, `active`, `expired`, `disabled`). |
| `POST /promotions` | admin, staff | `{productId, promoPrice, startDate, endDate, active?, audience?, title?}`, días `AAAA-MM-DD` ambos incluidos. `audience`: `everyone` (por defecto) o `vip`; `title`: hasta 100 caracteres. |
| `PATCH /promotions/:id` | admin, staff | Cambia precio, fechas, `active`, `audience` o `title` (`null` lo borra); el producto no cambia. |
| `GET /promotions/active` | público (token opcional) | Paginado: las vigentes que quien pregunta puede usar, de productos activos, por producto y la más barata primero. Cada una con `title`, `audience`, `promoPrice`, fechas y `product {id, name, price, imageUrl}`. Sin token, o sin ser VIP, solo salen las de `everyone`. |
| `DELETE /promotions/:id` | admin, staff | 204. |
| `GET /vip-customers` | admin, staff | Paginado, por correo. Cada uno con `email`, `active`, `createdAt`, `addedBy {id, name, email}` y `hasAccount` (si ese correo ya tiene cuenta). Filtros: `search` (en el correo) e `includeInactive=true` (también los dados de baja). |
| `POST /vip-customers` | solo `admin` | `{emails: [...]}` (de 1 a 500). Normaliza (minúsculas, sin espacios), valida el formato e ignora los repetidos. Responde 200 con `{added, duplicates, invalid}`. Un correo dado de baja que vuelve se reactiva y cuenta en `added`. |
| `DELETE /vip-customers/:id` | solo `admin` | Baja lógica (`active: false`): queda quién lo agregó y cuándo. Devuelve el VIP. |
| `POST /inventory/movements` | admin, staff | `{productId, type, quantity, reason?}` con `type` igual a `incoming`, `outgoing` o `adjustment`. Actualiza `currentStock` y registra el movimiento a nombre de quien lo hace, en una sola transacción. Responde el movimiento con el stock nuevo. |
| `GET /inventory/movements` | admin, staff | Historial paginado, el más reciente primero; `?productId=` filtra (404 si el producto no existe). |
| `GET /inventory/alerts/low-stock` | admin, staff | `{data}`: productos activos con `currentStock <= minStock`, los más críticos primero, con `shortage` (lo que falta para el mínimo). |
| `GET /inventory/alerts/expiring?days=7` | admin, staff | `{days, until, data}`: productos activos con stock que vencen hasta hoy + `days` (1 a 365), incluidos los ya vencidos, con `daysLeft` (negativo = vencido). |
| `POST /orders` | cualquiera con cuenta | `{deliveryAddress, items: [{productId, quantity, unitPrice?}]}` (de 1 a 100 líneas; cantidad de 1 a 999). El servidor pone los precios y el total: cobra por producto la mejor promoción vigente que el cliente puede usar (la más barata) o el precio normal. `unitPrice` es el que mostraba el carrito: nunca se cobra, solo se compara. El pedido queda a nombre de quien lo crea, en `pendingConfirmation`, y descuenta el stock. Producto dado de baja o inexistente: 400 (`Ya no están disponibles: ...`). Stock insuficiente: 409. En los dos casos no se guarda nada. Responde 201 con el pedido y `priceChanges: [{productId, name, shownUnitPrice, unitPrice}]`, los productos que se cobraron distinto de lo que mostraba el carrito (vacío si nada cambió). |
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

Cada producto trae su categoría y `promotion`: la mejor promoción vigente que puede usar quien
pregunta (con `title` y `audience`), o `null`. Reglas de las promociones
(`lib/src/promotions/promotion_rules.dart`):

- El estado sale de la fecha y del interruptor `active`; no se guarda.
- `promoPrice` tiene que ser menor al precio normal (400).
- Dos promociones encendidas del mismo producto y la misma audiencia no pueden cruzarse en el
  tiempo (409). De audiencias distintas sí (una para todos y otra VIP): cada cliente paga la más
  barata de las que puede usar.

### Clientes VIP y audiencias de las promociones

Cada promoción tiene una `audience`: `everyone` (todos, también sin cuenta) o `vip`. Quién
puede usar cada una lo deciden reglas que se inyectan, no condiciones repartidas por el código:

- `common/shopper.dart`: `Shopper` (quién mira o compra) y la interfaz `ShopperResolver`, que lo
  arma desde el token. La implementa `VipShopperResolver` (`vip/`).
- `promotions/audience/`: la interfaz `PromotionAudienceRule` (`audience` +
  `isEligible(shopper)`) y sus reglas, `EveryoneAudienceRule` y `VipAudienceRule`.
- `PromotionsService` recibe la lista de reglas por constructor y no conoce ninguna. Implementa
  `PromotionPricing` (las promociones que un cliente puede usar y la mejor), lo único que reciben
  `ProductsService` y `OrdersService`.
- `VipService` (`vip/`) da de alta, baja y consulta los VIP. No sabe nada de promociones.

**Es VIP** quien tiene el correo del token en `vip_customers` (activo) **y** `email_verified =
true` en Firebase. Sin esa verificación, cualquiera podría crear una cuenta con el correo de un
VIP. Las cuentas de correo y contraseña de Firebase empiezan sin verificar: hasta que la persona
confirma su correo, el servidor la trata como cliente común (`isVip: false`).

**Para sumar un segmento** (p. ej. mayoristas):

1. Un valor nuevo en `promotions/promotion_audience.spy.yaml`, y `serverpod generate`.
2. Una regla nueva en `promotions/audience/` que implemente `PromotionAudienceRule`. Si necesita
   saber algo más del cliente, se agrega a `Shopper` y lo completa el `ShopperResolver`.
3. Pasarla a `PromotionsService` en `server.dart`.

No hace falta tocar `PromotionsService`, ni products, ni orders. El test
`test/unit/promotions/promotion_audience_test.dart` lo muestra con una regla de prueba.

### Avisos push (FCM)

Al crear una promoción **VIP que ya rige** (encendida y con hoy dentro de su vigencia), el
servidor manda un push a cada dispositivo de los clientes VIP activos con el correo verificado:
"Nueva oferta exclusiva", con el producto, el precio y hasta qué día rige, y en `data`
`{type: vip_promotion, promotionId, productId}` para que la app abra el producto.

- Usa la REST API de FCM (HTTP v1), **un mensaje por token**, nunca por topic: un topic lo puede
  suscribir cualquiera desde el cliente.
- Corre en segundo plano, con su propia sesión (`Serverpod.withSession`): la respuesta del
  `POST /promotions` no espera, y si el envío falla la promoción se crea igual. Todo queda en el
  log: el resumen (enviados, tokens inválidos borrados, fallidos) y cada fallo, con solo el
  final del token.
- Los tokens que FCM da por dados de baja (`UNREGISTERED`, o un 400 por `message.token`) se
  borran. Cualquier otro error no borra nada.
- Las piezas:
  - `push/`: `PushSender`, `FcmPushSender` y `GoogleAccessTokens`, que firma el JWT de
    la cuenta de servicio (RS256) y lo canjea por un access token de OAuth;
  - `promotions/promotion_announcer.dart`: `PromotionsService` llama a
    `PromotionAnnouncer.announce` con cada promoción que se crea y ya rige;
  - `vip/vip_promotion_announcer.dart`: decide a quién y manda.
- Los tokens los registra la app con `PUT /users/me/devices` (tabla `device_tokens`, varios
  por cuenta). Si se aprueba un VIP con el correo verificado, lo sabe por `users.emailVerified`,
  que guarda `GET /users/me`.

**Configurarlo** (sin esto el servidor arranca igual y lo dice en el log: "Aviso push
desactivado"):

1. En Firebase: Configuración del proyecto → Cuentas de servicio → **Generar nueva clave
   privada**. Descarga un JSON: es un secreto.
2. Guardarlo fuera del repo, o en `config/` con un nombre que git ignora (p. ej.
   `config/firebase_service_account_key.json`, o el nombre que pone Firebase,
   `*-firebase-adminsdk-*.json`).
3. En `config/passwords.yaml`, en la sección del modo (p. ej. `development:`):
   `fcmServiceAccountFile: 'config/firebase_service_account_key.json'` (o la variable de
   entorno `FCM_SERVICE_ACCOUNT_FILE`).
4. Reiniciar el servidor. Si el proyecto de la cuenta no es el de `firebaseProjectId`, lo
   avisa al arrancar.

Usuarios: la respuesta es `{id, email, name, phone, role, address, createdAt}` (y `isVip` en
`/users/me`). Errores comunes a
todas las rutas, siempre con la forma `{statusCode, message, error}`:

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
