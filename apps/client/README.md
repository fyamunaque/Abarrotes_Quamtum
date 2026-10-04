# Cliente Flutter — Neil's Food Services

App de la tienda para **Android y web**, hecha en Flutter. Por ahora convive con la app Kotlin
(`apps/android`) y la web Next.js (`apps/web`). Cuando tenga todo lo que esas apps hacen, las
reemplaza. Habla con el backend Serverpod de `apps/server`.

- Paquete Android: `com.quamtum.neils` (el registrado en Firebase).
- Estado: [Riverpod](https://riverpod.dev). Rutas: [go_router](https://pub.dev/packages/go_router).
- Cuentas: [Firebase Auth](https://firebase.google.com/docs/auth) (email y contraseña). El rol
  lo da el servidor.

## Requisitos

- **Flutter 3.47.6** (trae Dart 3.13.5). En Windows: descomprimir el zip oficial en
  `%USERPROFILE%\develop\flutter` y agregar `%USERPROFILE%\develop\flutter\bin` al `Path` del
  usuario.
- Para Android, el SDK que ya usa `apps/android` más el **NDK 30.0.16248370**: en Android Studio,
  SDK Manager → SDK Tools → NDK (Side by side). `android/build.gradle.kts` fija esa versión en
  todos los módulos. Flutter pide el 28.2 y, en Windows, su instalador automático falla.
- Para la web, Chrome o Edge.
- Para ingresar, el servidor de `apps/server` corriendo (ver su README).

## Comandos (desde `apps/client`)

| Qué | Comando |
|---|---|
| Dependencias | `flutter pub get` |
| Correr en Chrome | `flutter run -d chrome` |
| Correr en el emulador o teléfono | `flutter run -d <dispositivo>` (ver `flutter devices`) |
| Contra otro servidor | agregar `--dart-define=API_URL=https://api.ejemplo.com` |
| Análisis estático | `flutter analyze` |
| Tests | `flutter test` |
| Compilar la web | `flutter build web` (queda en `build/web`) |
| Compilar el APK | `flutter build apk --debug` |

## Firebase y el servidor

**Config de Firebase:** `lib/firebase_options.dart`, con el formato de `flutterfire configure`.
Se versiona: los valores identifican el proyecto, no son secretos. Lo que protege los datos es el
servidor, que verifica el ID token en cada petición.

- **Android** ya está: sale de `apps/android/app/google-services.json` (mismo proyecto y paquete
  que la app Kotlin). Se inicializa desde Dart, sin el plugin de Gradle de google-services.
- **Web**: pendiente. Hasta tenerla, la web arranca y el ingreso dice que no está disponible.
  Para agregarla:
  1. En la consola de Firebase: Configuración del proyecto → Tus apps → Agregar app → Web.
  2. Copiar `apiKey`, `appId`, `messagingSenderId`, `projectId`, `authDomain` y `storageBucket`
     en `DefaultFirebaseOptions.web`, como `FirebaseOptions(...)`, igual que `android`.
- Una sola vez, en la consola: **Authentication → Sign-in method → habilitar "Correo
  electrónico/contraseña"**. `localhost` ya viene en los dominios autorizados.

**Servidor:** la app llama a las rutas REST de `apps/server` (puerto 8082). La URL se elige al
compilar con `--dart-define=API_URL=...`. Por defecto:

| Dónde corre la app | Servidor |
|---|---|
| Web | `http://localhost:8082` |
| Emulador de Android | `http://10.0.2.2:8082` (así ve el emulador a la máquina) |
| Teléfono real | no hay valor por defecto: pasar la IP de la máquina en la red local, p. ej. `--dart-define=API_URL=http://192.168.1.20:8082` |

Desde la web, el servidor tiene que aceptar el origen (CORS). En `development` acepta cualquier
`http://localhost:<puerto>`; en staging y producción, los de `ALLOWED_ORIGINS` (ver el README del
servidor). En Android, el HTTP sin cifrar solo está permitido en los builds de debug.

## Estructura (`lib/`)

```
main.dart              URLs sin "#" en la web, fuentes empaquetadas, Firebase, ProviderScope
app.dart               MaterialApp.router: tema, router, español
firebase_options.dart  config de Firebase por plataforma
config/                URL del servidor (API_URL) y apiClientProvider
auth/                  AuthRepository (Firebase Auth) y los providers de los repositorios
users/                 UserRepository: el perfil y el rol desde GET /users/me
session/               Session y sessionProvider (quién ingresó y con qué rol)
catalog/               Product, Category, CatalogRepository y sus providers
cart/                  Cart y cartProvider (en memoria; también hace el pedido)
orders/                Order, OrderStatus, OrderRepository y myOrdersProvider
admin/                 los datos del panel, un dominio por carpeta (stats, orders, products,
                       inventory, promotions) y PagedNotifier
common/                ApiClient y AuthedApi (las rutas REST y sus errores), PageList,
                       formatSoles, los días de la tienda (days.dart)
router/                rutas, guard y GoRouter
theme/                 tokens de marca y de estados (brand_colors.dart), ThemeData
                       (neils_theme.dart) y movimiento (motion.dart)
features/<sección>/    pantallas y componentes: home, auth, catalog, cart, orders, admin,
                       showcase (la vitrina) y shared (logo, barra, swoosh, PressScale)
```

Las pantallas no hablan con Firebase ni con HTTP: usan providers, que usan los repositorios
(una interfaz y su implementación HTTP o Firebase). Los tests reemplazan los repositorios por
versiones en memoria (`test/fakes.dart`). Los errores del servidor llegan como `ApiFailure`, ya en
español: sin conexión, sesión vencida, 5xx, o el mensaje del servidor (p. ej. "Stock
insuficiente: Aceite tiene 2 unidades").

## Tema

Los tokens son los mismos de la web y la app Kotlin:

| Token | Color |
|---|---|
| primary | `#E8652F` |
| primaryDark | `#B54F25` |
| accent | `#A1241B` |
| cream | `#F9F3E7` |
| ink | `#1D0605` |

El naranja sobre crema da 3,0:1 de contraste. Por eso el `primary` de Material (botones, textos
de acción) es **primaryDark**, y el naranja va en `secondaryContainer` (botones tonales).

La tipografía usa `google_fonts` con las fuentes **empaquetadas** en `assets/google_fonts`, así
que la app no descarga nada:
- **Baloo 2** (600/700/800) para títulos y precios (`NeilsText.price`).
- **Inter** (400/500/600) para el resto.

**Estados de pedido** (`OrderStatusColors`):

| Estado | Color |
|---|---|
| Pendiente de confirmación | `#D98C21` |
| Confirmado | `#3C7A5F` |
| En camino | `#2E6F9E` |
| Entregado | `#3C7A5F` |
| Cancelado | `#8C3B33` |

Son para puntos y líneas. El estado va siempre también en texto, en tinta: el ámbar sobre crema
no alcanza el contraste de un texto. El rojo de cancelado sí (6,8:1). Como paleta para
distinguir categorías tampoco alcanzan: el verde de confirmado y el azul de en camino se
parecen (ΔE 11,5) y el ámbar queda en 2,66:1 sobre crema. Por eso el panel nunca usa solo el
color (ver `StatusBadge`).

**El panel** (`neilsAdminTheme`, en `theme/neils_theme.dart`) usa una variante calmada del tema,
solo bajo `/admin`:
- fondo crema y texto en tinta;
- tarjetas planas con un borde suave, sin sombra;
- lo elegido (la sección en la navegación, los chips, el segmento) en el naranja muy claro
  (`primaryTint`), no en naranja;
- el `primary` solo en la acción principal de cada pantalla, en la sección activa y en la línea
  del gráfico de ventas.

## Movimiento

Poco, y con un motivo. Las duraciones están en `theme/motion.dart`. Todo respeta "reducir
animaciones" del sistema (Android: "Quitar animaciones"; web: `prefers-reduced-motion`): con eso
activo, cada animación salta a su estado final.

- **El swoosh de la portada** (`AnimatedSwoosh`, en `features/shared/swoosh.dart`): el trazo de
  pincel del logo, en `accent`, se dibuja bajo "a la puerta de tu casa" al abrir la pantalla.
  Dura 700 ms, una sola vez: no se repite aunque la pantalla se reconstruya. Es el único momento
  animado que no responde a una acción.
- **"Agregar"** en la tarjeta de producto (`PressScale`): se achica un poco mientras se presiona.
  El precio va subrayado con el mismo swoosh, quieto (`Swoosh`).
- **El seguimiento de pedido** (`OrderTracker`): cuando el estado avanza, la línea se llena
  hasta el paso nuevo en 500 ms, y el color pasa al del estado nuevo. Al mostrarse no se anima.
  Un pedido cancelado muestra los pasos apagados y el aviso: el servidor no guarda en qué paso
  se canceló.

## Vitrina (solo en debug)

`/vitrina` muestra los componentes con datos de ejemplo: las tarjetas de producto (con
promoción, sin stock, con un nombre largo) y el seguimiento, con un selector de estado para ver
la animación. Sirve para revisarlos antes de que tengan pantallas con datos reales. La ruta se
registra solo si `kDebugMode`: en los builds de release no existe, y el compilador la saca del
JavaScript y del APK.

```powershell
flutter run -d chrome   # y abrir /vitrina
```

## Sesión y rutas

| Ruta | Quién | Qué |
|---|---|---|
| `/`, `/login`, `/registro` | Cualquiera | Portada, ingreso y registro |
| `/catalogo?categoria=<id>` | Cualquiera | Productos página a página ("Ver más"), con filtro por categoría. La elegida va en la URL, así un enlace abre el catálogo ya filtrado. |
| `/producto/:id` | Cualquiera | Detalle, con la cantidad a agregar (hasta el stock que queda) |
| `/carrito` | Cualquiera; confirmar pide cuenta | Cantidades, total, dirección de entrega (propone la del perfil) y "Confirmar pedido". Sin cuenta, "Ingresar para confirmar" lleva al ingreso y vuelve aquí. |
| `/mis-pedidos` | Cualquier cuenta | Cada pedido con su seguimiento. "Actualizar" recarga sin sacar la lista de pantalla, así el seguimiento anima un estado que avanzó. |
| `/admin` y sus subrutas | Solo `admin` y `staff` | El panel: inicio, `/admin/pedidos`, `/admin/productos`, `/admin/inventario` y `/admin/promociones` (ver "El panel") |

**Carrito** (`cart/cart_provider.dart`): vive solo en memoria, así que se vacía al cerrar o
recargar la app.
- La cantidad va de 1 al stock, y como mucho a 999, lo que el servidor acepta por línea.
- Los precios son los del catálogo al agregar. El servidor cobra los del momento del pedido, el de
  la promoción vigente si la hay.
- `placeOrder` hace el pedido con el ID token. Si sale bien, vacía el carrito y recarga "Mis
  pedidos" y el catálogo (cambió el stock).
- Si el servidor lo rechaza (409 sin stock, 400 producto dado de baja), muestra su mensaje y el
  carrito queda igual.

**Sesión** (`session/session_provider.dart`): hay sesión cuando hay una cuenta de Firebase y el
servidor devolvió su perfil.
- Al arrancar es `SessionLoading`, hasta saber si quedó una cuenta abierta. Firebase la guarda de
  forma segura en cada plataforma y renueva el ID token solo.
- Registrarse crea la cuenta en Firebase con su nombre. Después, `GET /users/me` la crea en la
  tienda, siempre como `customer`. Las cuentas admin y staff las crea un admin.
- Si el servidor no responde, la app cierra también la cuenta de Firebase y muestra el error: sin
  perfil no hay rol.

**Después de ingresar** (`routeAfterSignIn` en `router/route_guard.dart`):
- si el ingreso lo pidió el carrito o "Mis pedidos" (`/login?from=...`), vuelve ahí, con
  cualquier cuenta;
- si no, un cliente va a `/catalogo`;
- admin y staff van a `/admin`, o a la ruta del panel que pidió el ingreso.

**El guard** protege `/mis-pedidos` y `/admin`:
- sin sesión, manda a `/login?from=...`;
- con una cuenta de cliente, `/admin` vuelve al inicio;
- mientras la sesión carga, la pantalla muestra un indicador.

Si la sesión cambia (p. ej. "Salir"), el router vuelve a evaluar la ruta actual.

## El panel (`/admin`)

`AdminShell` (`features/admin/admin_shell.dart`) es el layout de todas las secciones:
- desde 840 px, la navegación es un riel a la izquierda; más angosto, una barra abajo;
- las secciones salen del enum `AdminSection` (ruta, nombre, ícono), y el router arma una ruta
  por cada una.

| Sección | Qué hace |
|---|---|
| Inicio | Ventas de hoy, la semana y el mes con el ticket promedio, pedidos por estado, el gráfico de ventas de los últimos 30 días (`fl_chart`, con "Ver los datos" en tabla), stock bajo, por vencer en 7 días y el top 5. Cada tarjeta carga y falla por su lado, con "Reintentar". |
| Pedidos | Todos los pedidos, con chips por estado. El detalle muestra el cliente, la entrega, las líneas y el stepper: el seguimiento con la acción del paso siguiente ("Confirmar", "Marcar en camino", "Marcar entregado") y "Cancelar pedido", que pide confirmación. Si el servidor lo rechaza porque otra persona ya lo cambió, muestra su mensaje y trae el pedido como está. |
| Productos | Buscar por nombre o SKU, filtrar por categoría, crear, editar y dar de baja. El stock inicial solo se pone al crear; después se cambia en Inventario. Un SKU repetido (409) se marca en su campo. |
| Inventario | El historial de movimientos y "Registrar movimiento": entrada, salida o ajuste (con signo y motivo), con un buscador de producto y cómo queda el stock antes de registrarlo. |
| Promociones | Chips por estado, crear, editar y eliminar. El precio tiene que ser menor que el normal, la vigencia son días de la tienda (los dos incluidos) y el producto no cambia al editar. Una promoción que se cruza con otra del producto (409) se muestra. |

Las piezas compartidas están en `features/admin/shared/`:
- `AdminTable<T>`:
  - la tabla de cada sección: columnas (`AdminColumn`), paginación ("1–20 de 54"), cargando,
    error con "Reintentar" y vacío;
  - desde 720 px de ancho es una tabla; más angosto, cada fila es una tarjeta con
    `etiqueta: valor`;
  - cada fila es un botón con su descripción para el lector de pantalla.
- `showAdminForm`: un formulario en un diálogo en pantallas anchas y a pantalla completa en el
  teléfono. Con `admin_form.dart` (campos de a dos, el error del servidor y los botones) y
  `ProductPicker` (el buscador de productos con autocompletado).
- `FilterChips`, `StatusBadge` (punto de color más texto) y `confirmAction`.

Los datos van por sección en `lib/admin/<dominio>/` (modelo, repositorio HTTP con el ID token
y providers). Las tablas usan `PagedNotifier<T>`, con los filtros como argumento del provider
(family). Crear, editar y borrar pasan por el notifier, que actualiza la página sin recargar
toda la pantalla.

## Probar de punta a punta

Con el servidor corriendo y la config de Firebase de la plataforma. La primera vez, correr
`dart run bin/seed_dev.dart` (ver el README del servidor): deja productos, 40 pedidos de ejemplo
de los últimos 30 días (así el inicio del panel tiene ventas) y productos en las alertas.

1. `flutter run -d chrome` (o en el emulador). Crear una cuenta en **Crear una cuenta**: termina
   en `/catalogo`, con el nombre en la barra.
2. Agregar productos, abrir el carrito y confirmar el pedido: termina en `/mis-pedidos`, con el
   aviso y el pedido en "Pendiente".
3. Pasar la cuenta a admin en la base del servidor:

   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U abarrotes -d abarrotes_server -c "UPDATE users SET role = 'admin' WHERE email = 'correo@ejemplo.com'"
   ```

4. **Salir** e ingresar de nuevo: termina en `/admin`, con las ventas de los pedidos de ejemplo.
5. En **Pedidos**, abrir el pedido y avanzarlo ("Confirmar", "Marcar en camino"…). En "Mis
   pedidos", **Actualizar** anima el seguimiento hasta el estado nuevo.
6. Probar las otras secciones: crear un producto, registrar una entrada de stock y crear una
   promoción. La promoción se ve en el catálogo.

## Tests

- `test/router/route_guard_test.dart`: el guard y `routeAfterSignIn` son funciones puras; prueba
  cada ruta con cada tipo de sesión.
- `test/router/router_test.dart`: la app completa con una sesión simulada (`TestSession`), que se
  puede cambiar en medio del test.
- `test/session/session_provider_test.dart`: la sesión real con Firebase y el servidor en memoria
  (`test/fakes.dart`). El Firebase falso avisa de la cuenta nueva antes de guardar el nombre,
  como el real: así se prueba que el registro no crea la cuenta sin nombre en el servidor.
- `test/features/auth_screens_test.dart`: ingreso, registro, validación, errores, carga y salir,
  con la app completa.
- `test/users/http_user_repository_test.dart`, `test/catalog/http_catalog_repository_test.dart`
  y `test/orders/http_order_repository_test.dart`: cada ruta REST con un cliente HTTP simulado
  (`MockClient`): la URL, el query, el token, el body y cómo se lee la respuesta.
- `test/common/api_client_test.dart`: los errores (sin conexión, sin respuesta, 401, 5xx, el
  mensaje del servidor o su lista).
- `test/catalog/product_list_test.dart`: el catálogo página a página, por categoría, y "Ver más"
  cuando falla.
- `test/cart/`: el carrito (sumar, límites, total) y `placeOrder` (vacía el carrito solo si el
  pedido sale bien).
- `test/features/catalog_screen_test.dart`, `cart_screen_test.dart` y `checkout_test.dart`: el
  flujo de compra con la app completa:
  - filtro y URL, "Ver más", errores, detalle;
  - carrito, cantidades y quitar;
  - sin cuenta: ingresar, volver al carrito y pedir;
  - el 409, la dirección vacía;
  - `/mis-pedidos` y "Actualizar" animando el seguimiento.
- `test/auth/auth_error_message_test.dart`: los mensajes de cada error de Firebase.
- `test/features/account_bar_test.dart`: la barra con sesión entra en un teléfono de 320 y 375
  px (la cuenta va en un menú).
- `test/features/swoosh_test.dart` y `home_screen_test.dart`: la forma del trazo, que se dibuja
  una vez y en menos de un segundo, y que con "reducir animaciones" aparece completo.
- `test/features/product_card_test.dart`: precio, promoción, "Agotado", tarjetas de igual alto y
  el achique de "Agregar" (que no ocurre con "reducir animaciones").
- `test/features/order_tracker_test.dart`: cuánto se llena cada tramo por estado, la animación al
  avanzar (a mitad de camino y al final), cancelado y el estado como texto.
- `test/theme/theme_test.dart`: colores, contraste y fuentes del tema.
- `test/admin/`: el panel, con repositorios en memoria y una sesión de staff (`pumpPanel` en
  `panel_support.dart`):
  - `admin_repositories_test.dart`: cada repositorio del panel con `MockClient`;
  - `admin_table_test.dart` y `admin_shell_test.dart`: tabla o tarjetas según el ancho,
    paginación, estados, y la navegación (riel o barra);
  - `admin_home_test.dart`: los KPI, el gráfico (30 puntos, la tabla de datos), las alertas, el
    top 5 y una tarjeta que falla sola;
  - `admin_orders_test.dart`, `admin_products_test.dart`, `admin_inventory_test.dart` y
    `admin_promotions_test.dart`: filtros, formularios (validación y lo que se manda), los
    errores del servidor (400 y 409), las confirmaciones y que no se desborde en 320 y 375 px.

Los tests de movimiento usan `MediaQueryData(disableAnimations: true)` para "reducir
animaciones" y `tester.hasRunningAnimations` para saber si quedó algo animándose. Flutter da por
terminada una animación en el frame siguiente a su duración: por eso avanzan un milisegundo más.

Los tests que usan el tema llaman a `useBundledFonts()` (`test/support.dart`): fuentes desde los
assets, sin red. Ese helper también esquiva un fallo del motor de pruebas de Windows: cargar
Baloo2-SemiBold y Baloo2-Bold en el mismo proceso lo cierra sin error. Por eso, en los tests, la
SemiBold se reemplaza por la ExtraBold. La app no cambia.

En Windows, además, `flutter_tester` a veces se cae solo: el archivo de tests termina con "did
not complete" y sin ningún assert fallido. En el registro de eventos de Windows figura como
access violation (0xC0000005) dentro de `flutter_tester.exe`. Pasa con cualquier archivo que use
el tema, también corriendo de a uno (`--concurrency=1`), y más con poca RAM libre o con
`flutter run` abierto.
- Es un fallo del motor de pruebas de Flutter 3.47 en Windows, no de los tests. Probé cargar las
  fuentes de a una y usar un solo archivo de fuente, y ninguna de las dos cosas lo evita.
- Si pasa, vuelve a correr ese archivo.
- En CI (Linux) no ocurre.
