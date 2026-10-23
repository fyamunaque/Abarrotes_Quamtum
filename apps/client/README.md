# Cliente Flutter — Neil's Food Services

App de la tienda para **Android y web**, hecha en Flutter: la tienda para los clientes y el panel
`/admin` para la tienda. Habla con el servidor Serverpod de `apps/server`.

- Paquete Android: `com.quamtum.neils` (el registrado en Firebase).
- Estado: [Riverpod](https://riverpod.dev). Rutas: [go_router](https://pub.dev/packages/go_router).
- Cuentas: [Firebase Auth](https://firebase.google.com/docs/auth) (email y contraseña). El rol
  lo da el servidor.

## Requisitos

- **Flutter 3.47.6** (trae Dart 3.13.5). En Windows: descomprimir el zip oficial en
  `%USERPROFILE%\develop\flutter` y agregar `%USERPROFILE%\develop\flutter\bin` al `Path` del
  usuario.
- Para Android, el SDK de Android Studio más el **NDK 30.0.16248370**: en Android Studio,
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

- **Android** ya está: la Android app del proyecto, con el paquete `com.quamtum.neils`. Se
  inicializa desde Dart, sin `google-services.json` ni el plugin de Gradle de google-services.
- **Web** también: es la Web app del mismo proyecto (consola de Firebase → Configuración del
  proyecto → Tus apps). Si se registra otra plataforma, sus valores van en
  `DefaultFirebaseOptions` igual; sin config, la app arranca y el ingreso dice que no está
  disponible.
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
users/                 UserRepository: el perfil, el rol y si es VIP, desde GET /users/me
session/               Session, sessionProvider (quién ingresó, con qué rol, si es VIP y si
                       confirmó su correo) e isVipProvider
catalog/               Product, Category, CatalogRepository y sus providers
offers/                Offer, OffersRepository (GET /promotions/active) y exclusiveOffersProvider
cart/                  Cart, cartProvider (también hace el pedido) y CartStorage (dónde se guarda)
orders/                Order (con priceChanges), OrderStatus, OrderRepository, myOrdersProvider
                       y placedOrderProvider
admin/                 los datos del panel, un dominio por carpeta (stats, orders, products,
                       inventory, promotions, vip) y PagedNotifier
common/                ApiClient y AuthedApi (las rutas REST y sus errores), PageList,
                       formatSoles, los días de la tienda (days.dart)
router/                rutas, guard y GoRouter
theme/                 tokens de marca y de estados (brand_colors.dart), ThemeData
                       (neils_theme.dart) y movimiento (motion.dart)
features/<sección>/    pantallas y componentes: home, auth, catalog, cart, orders, offers,
                       admin, showcase (la vitrina) y shared (logo, barra, swoosh,
                       PressScale, VipTag, el aviso de verificación, RefreshOnResume)
```

Las pantallas no hablan con Firebase ni con HTTP: usan providers, que usan los repositorios
(una interfaz y su implementación HTTP o Firebase). Los tests reemplazan los repositorios por
versiones en memoria (`test/fakes.dart`). Los errores del servidor llegan como `ApiFailure`, ya en
español: sin conexión, sesión vencida, 5xx, o el mensaje del servidor (p. ej. "Stock
insuficiente: Aceite tiene 2 unidades").

## Tema

Los tokens de la marca:

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

**Fotos de los productos** (`ProductPhoto`, en `features/catalog/product_photo.dart`):
- **Las fotos subidas:** llegan del servidor como ruta relativa (`/images/products/…`) y se
  completan con `apiBaseUrl`. Una URL externa se pide tal cual.
- **Mientras carga, o si no hay foto o no carga:** se ve un marcador, la inicial del producto en
  Baloo 2 sobre un fondo suave. La foto entra con un fundido de 200 ms, que no se anima si está
  activado "reducir animaciones".
- **El color del marcador** sale de la categoría (`PlaceholderColors.of(id)`, 8 pares
  fondo/texto con contraste de al menos 4.5:1). Una misma categoría tiene siempre el mismo
  color, en la web y en Android, así el catálogo no se ve repetido aunque falten fotos.

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
- **El carrito de la barra** (`CartButton`): cuando sube el contador, el ícono da un rebote de
  300 ms. Al quitar no se mueve.
- **El seguimiento de pedido** (`OrderTracker`): los pasos del tipo de entrega del pedido
  (`FulfillmentType.steps`): a domicilio, Por confirmar → Confirmado → En camino →
  Entregado; con recojo, Por confirmar → Confirmado → Preparando → En espera de recojo →
  Recogido. Dibuja los pasos y el estado actual que manda el servidor: no sabe de
  transiciones. Cuando el estado avanza, la línea se llena hasta el paso nuevo en 500 ms, y el
  color pasa al del estado nuevo (preparando `#7A5A9E`, en espera de recojo `#2A8C82`, en
  `OrderStatusColors`). Al mostrarse no se anima. En un ancho angosto los nombres se achican
  todos por igual y cortan solo en los espacios, en dos líneas como máximo.
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
| `/catalogo?categoria=<id>&q=<texto>` | Cualquiera | Productos página a página ("Ver más"), con búsqueda por nombre y filtro por categoría (cambiar de categoría conserva lo buscado). Los dos van en la URL, así un enlace abre el catálogo ya filtrado. |
| `/producto/:id` | Cualquiera | Detalle, con la cantidad a agregar (hasta el stock que queda) |
| `/carrito` | Cualquiera; confirmar pide cuenta | Cantidades, total estimado, cómo recibirlo ("Entrega a domicilio" o "Recoger en tienda") y "Confirmar pedido". A domicilio pide la dirección (obligatoria; propone la del perfil); con recojo la oculta y muestra la dirección, el teléfono, el horario y las instrucciones de la tienda (`GET /store`, `storeSettingsProvider`, `StoreDetails`). En un teléfono, las dos opciones van sin ícono para que cada una entre en una línea. Sin cuenta, "Ingresar para confirmar" lleva al ingreso y vuelve aquí. |
| `/mis-pedidos` | Cualquier cuenta | Cada pedido con su seguimiento y su entrega, en el mismo lugar y con el mismo formato (`InfoLine`): "Entrega a domicilio" con la dirección o, con recojo en tienda, los datos de la tienda y, desde que el pedido está confirmado, el código de recojo en grande para mostrar en caja (el lector de pantalla lo deletrea). En espera de recojo, un aviso destacado: "¡Tu pedido está listo para recoger!". "Actualizar" recarga sin sacar la lista de pantalla, así el seguimiento anima un estado que avanzó. Recién hecho un pedido, el aviso dice el total que cobró la tienda y los precios que cambiaron desde el carrito. |
| `/admin` y sus subrutas | El personal, cada sección con su permiso | El panel: inicio, `/admin/pedidos` (y `/admin/pedidos/recoger`), `/admin/productos`, `/admin/inventario`, `/admin/promociones`, `/admin/clientes-vip`, `/admin/tienda`, `/admin/equipo` y `/admin/roles` (ver "El panel") |
| `/admin/sin-acceso?seccion=<ruta>` | El personal | "No tienes acceso a esta sección", adonde lleva el guard una sección sin su permiso |

**Carrito** (`cart/cart_provider.dart`): queda guardado en el dispositivo (`cart/cart_storage.dart`:
SharedPreferences en Android, `localStorage` en la web), así que sigue ahí al recargar o volver a
abrir la app. Se guarda lo necesario para mostrarlo; datos rotos o de otra versión dejan el
carrito vacío.
- La cantidad va de 1 al stock, y como mucho a 999, lo que el servidor acepta por línea.
- Los precios son los del catálogo al agregar (los VIP, para una cuenta VIP): el total es una
  **estimación**. El servidor cobra los del momento del pedido, la mejor promoción que la cuenta
  puede usar.
- `placeOrder` hace el pedido con el ID token y manda el precio que mostraba cada línea
  (`unitPrice`), que el servidor solo compara: si cobró otro, lo devuelve en `priceChanges`
  y el aviso de "Mis pedidos" lo muestra. Si sale bien, vacía el carrito y recarga "Mis
  pedidos" y el catálogo (cambió el stock).
- Si la cuenta deja de ser VIP (o se cierra la sesión), las líneas con precio VIP vuelven al
  precio normal: quien no es VIP no ve precios VIP, tampoco en el mismo dispositivo.
- Si el servidor lo rechaza (409 sin stock, 400 producto dado de baja), muestra su mensaje y el
  carrito queda igual.

**Sesión** (`session/session_provider.dart`): hay sesión cuando hay una cuenta de Firebase y el
servidor devolvió su perfil.
- Al arrancar es `SessionLoading`, hasta saber si quedó una cuenta abierta. Firebase la guarda de
  forma segura en cada plataforma y renueva el ID token solo.
- Registrarse crea la cuenta en Firebase con su nombre. Después, `GET /users/me` la crea en la
  tienda, siempre como `customer`. Al equipo lo agrega por correo quien tiene `staff.manage`
  (`/admin/equipo`).
- El perfil trae `permissions` (`SessionUser.permissions`, el catálogo en
  `session/staff_permission.dart`) y el nombre del rol (`staffRoleName`, que el panel muestra
  junto al nombre). La app solo muestra u oculta con ellos (`permissionsProvider`): el
  servidor revisa cada acción.
- Si el servidor no responde, la app cierra también la cuenta de Firebase y muestra el error: sin
  perfil no hay rol.
- `refreshProfile` vuelve a pedir el perfil sin cerrar la sesión: al abrir el catálogo, al
  volver la app a primer plano (`RefreshOnResume`, con `AppLifecycleListener`; en la web, al
  volver a la pestaña) y al deslizar hacia abajo en el inicio y el catálogo. Así un correo que un
  admin hizo VIP, o un rol que cambió, se ve sin volver a ingresar: el panel muestra las
  secciones nuevas y, si la abierta ya no le corresponde, el guard la cierra. Si falla, la
  sesión queda como estaba.
- **Correo sin verificar:** las pantallas de la tienda muestran "Verifica tu correo para
  completar tu cuenta", con "Enviar el correo" y "Ya lo verifiqué". Al registrarse se manda el
  correo una vez. Si se acaba de confirmar, `refreshProfile` renueva el ID token para que el
  servidor lo vea (`email_verified`).

**Clientes VIP** (`isVipProvider`): lo decide el servidor (VIP activo y correo verificado).
- El catálogo pide los productos con el ID token: el servidor da a cada cliente su mejor precio.
  Si la cuenta pasa a ser VIP (o deja de serlo), los productos se vuelven a pedir.
- Un precio VIP va con el normal tachado, el swoosh y la insignia `VipTag` (`accent` sobre
  crema). Entra en 300 ms (`NeilsMotion.reveal`) una sola vez, y aparece directo con "reducir
  animaciones".
- "Ofertas exclusivas" (`features/offers/`), en el inicio y arriba del catálogo completo: las
  promociones VIP de `/promotions/active`. Tocar una abre el producto.
- Para quien no es VIP no hay nada: ni la sección, ni la insignia, ni el pedido de ofertas.

**Después de ingresar** (`routeAfterSignIn` en `router/route_guard.dart`):
- si el ingreso lo pidió el carrito o "Mis pedidos" (`/login?from=...`), vuelve ahí, con
  cualquier cuenta;
- si no, un cliente va a `/catalogo`;
- el personal va a la ruta del panel que pidió el ingreso, si la puede ver, o a su sección
  principal (`panelHomeFor`): quien tiene `staff.manage`, al inicio; los demás, a la de su
  tarea, lo primero que pueden cambiar en este orden: pedidos, inventario, productos,
  promociones, clientes VIP. Así la Cajera llega a Pedidos y el Almacenero a Inventario. Si no
  pueden cambiar nada, a la primera sección que ven.

**El guard** protege `/mis-pedidos` y `/admin`:
- sin sesión, manda a `/login?from=...`;
- con una cuenta de cliente, `/admin` vuelve al inicio;
- cada sección del panel pide alguno de sus permisos (`Routes.permissionsFor`, los mismos que
  sus rutas en el servidor; ver "El panel"). Sin ellos, `/admin` lleva a la sección principal
  y cualquier otra a "No tienes acceso a esta sección" (`/admin/sin-acceso`), con el camino a
  la suya;
- mientras la sesión carga, la pantalla muestra un indicador.

Es solo experiencia de usuario: la seguridad la aplica el servidor en cada ruta.

Si la sesión cambia (p. ej. "Salir"), el router vuelve a evaluar la ruta actual.

**Título de la pestaña** (`PageTitle`): cada pantalla pone el suyo, p. ej. "Carrito · Neil's Food
Services", el nombre del producto en el detalle o "Pedidos · Panel · Neil's Food Services" en el
panel. En Android es el nombre en el selector de apps. `PublicScaffold` lo recibe en `title`.

## El panel (`/admin`)

`AdminShell` (`features/admin/admin_shell.dart`) es el layout de todas las secciones:
- desde 840 px, la navegación es un riel a la izquierda; más angosto, una barra abajo;
- las secciones salen del enum `AdminSection` (ruta, nombre, ícono), y el router arma una ruta
  por cada una;
- la navegación muestra solo las que la sesión puede abrir (`AdminSection.visibleTo`). La
  barra del teléfono necesita al menos dos y una elegida: con una sola, o en "No tienes
  acceso", no se muestra. Muestra hasta cinco destinos (`AdminShell.barDestinations`): con
  más secciones, el quinto es "Más", que abre una hoja abajo con las que no entran (y queda
  elegido cuando se está en una de ellas);
- dos secciones tienen pestañas (`PanelTabs`), así no suman destinos a la barra: Pedidos,
  "Todos los pedidos" (`/admin/pedidos`) y "Para recoger" (`/admin/pedidos/recoger`), y
  Equipo, Personas (`/admin/equipo`) y Roles (`/admin/roles`). En un teléfono van sin
  ícono, así cada nombre entra en una línea.

| Sección | Para verla | Lo que pide además |
|---|---|---|
| Inicio (`/admin`) | `stats.view` | Sus enlaces a otras secciones salen si se pueden abrir |
| Pedidos (y "Para recoger") | `orders.view` | Avanzar o cancelar, `orders.updateStatus`; la columna y los datos del cliente (y buscar por nombre en "Para recoger"), `customers.view` |
| Productos | `products.view` o `products.manage` | Crear, editar y dar de baja, `products.manage` |
| Inventario | `inventory.view` | "Registrar movimiento", `inventory.adjust` |
| Promociones | `promotions.manage` | — |
| Clientes VIP | `vip.view` | Agregar y quitar, `vip.manage` |
| Tienda | `store.manage` | — |
| Equipo (Personas y Roles) | `staff.manage` | — |

Sin un permiso, el botón no aparece y una nota dice qué puede hacer el rol (`PanelNote`, p. ej.
"Tu rol puede ver el inventario, pero no registrar movimientos.").

| Sección | Qué hace |
|---|---|
| Inicio | Ventas de hoy, la semana y el mes con el ticket promedio (una venta es un pedido entregado o recogido), pedidos por estado (con Preparando y En espera de recojo), pedidos por tipo de entrega (cuántos y qué parte a domicilio y con recojo), el gráfico de ventas de los últimos 30 días (`fl_chart`, con "Ver los datos" en tabla), stock bajo, por vencer en 7 días y el top 5. Cada tarjeta carga y falla por su lado, con "Reintentar". Las tarjetas de una misma fila tienen el mismo alto (`ResponsiveGrid`). |
| Pedidos: Todos los pedidos | Todos los pedidos, con chips por estado ("Estado") y por entrega ("Entrega"; "Domicilio y recojo", "Domicilio", "Recojo"; los dos filtros van al servidor) y la columna "Entrega" con su insignia (`FulfillmentBadge`). Se actualiza solo cada 30 s, así los pedidos nuevos aparecen sin tocar nada. El detalle muestra el cliente, la entrega (la dirección, o "Recojo en tienda" con el código), las líneas y el stepper: el seguimiento con la acción del paso siguiente y "Cancelar pedido", que pide confirmación. Los botones salen de `allowedNextStatuses`, que calcula el servidor con el flujo del tipo de entrega (la app no escribe transiciones), y su texto, del estado al que llevan: a domicilio, "Confirmar", "Marcar en camino" y "Marcar entregado"; con recojo, "Confirmar", "Empezar a preparar", "Marcar listo para recoger" y "Marcar recogido". Marcar recogido abre `showPickupCodeDialog`: pide el código que muestra el cliente y, si el servidor dice que no coincide, el motivo sale en el mismo diálogo para corregirlo. Si el servidor lo rechaza porque otra persona ya lo cambió, muestra su mensaje y trae el pedido como está. |
| Pedidos: Para recoger | Pensada para caja: los pedidos de recojo en Preparando y En espera de recojo (hasta 100 de cada estado), primero los que esperan hace más. Cada uno con el código en grande (el lector de pantalla lo deletrea), el estado, cuánto hace que está listo ("Listo hace 12 min") o que se pidió, el cliente y el total. Se busca por el código (sin importar espacios ni mayúsculas) o por el nombre (sin tildes; la ñ cuenta como n), y se actualiza sola cada 30 s. Con `orders.updateStatus`, el botón del paso siguiente; entregar pide el código con el mismo diálogo. |
| Productos | Buscar por nombre o SKU, filtrar por categoría, crear, editar y dar de baja; cada fila con la foto en miniatura. El stock inicial solo se pone al crear; después se cambia en Inventario. Un SKU repetido (409) se marca en su campo. **La foto:**<br>• "Subir foto" elige un archivo o una foto de la galería, y "Tomar foto" usa la cámara (solo en el teléfono). La app la achica a 1600 px antes de subirla, y el servidor la deja en 800 px.<br>• También se puede pegar la URL de una imagen: escribirla descarta la foto elegida, y elegir una foto vacía la URL.<br>• La foto elegida se sube después de guardar el producto (`PUT /products/:id/image`). Si la subida falla, el producto ya quedó guardado: el formulario lo dice y "Reintentar la foto" sube solo la foto.<br>• `PhotoPicker` (`admin/products/photo_picker.dart`) es una interfaz con su implementación sobre `image_picker`, y los tests la reemplazan. |
| Inventario | El historial de movimientos y "Registrar movimiento": entrada, salida o ajuste (con signo y motivo), con un buscador de producto y cómo queda el stock antes de registrarlo. |
| Promociones | Chips por estado, crear, editar y eliminar. El precio tiene que ser menor que el normal, la vigencia son días de la tienda (los dos incluidos) y el producto no cambia al editar. Cada una tiene un título opcional y una audiencia: "Todos" o "Solo clientes VIP" (las exclusivas llevan la insignia VIP en la lista). Una promoción que se cruza con otra del producto para la misma audiencia (409) se muestra. |
| Clientes VIP | Los correos VIP, con búsqueda y paginación: si ya tienen cuenta ("Registrado" / "Aún sin cuenta") y la fecha de alta. Con `vip.manage` agrega (un correo, validado, o varios pegados separados por coma o salto de línea, con el resumen del servidor: agregados, ya estaban y no válidos) y quita, con confirmación; sin él, la lista en modo lectura. Un VIP ve sus promociones cuando ingresa con ese correo verificado. |
| Tienda | Solo con `store.manage`. El formulario con los datos que ven los clientes al elegir recojo: nombre y dirección (obligatorios), referencia, teléfono, horario de atención e instrucciones de recojo. Un campo opcional vacío se borra. Guarda con `PATCH /store` y muestra el motivo si el servidor lo rechaza. |
| Equipo: Personas | Solo con `staff.manage`. El equipo por correo, con búsqueda: el rol y el estado ("Activo", "Pendiente de registro" si todavía no creó su cuenta, "Desactivado"). Agregar uno o varios correos con un mismo rol, con el mismo formulario y resumen que los VIP (un desactivado vuelve con ese rol). "Cambiar rol" y "Desactivar" (con confirmación) en cada fila, menos en la propia. Si el servidor lo rechaza (el último Administrador), el motivo sale en un aviso o en el formulario. |
| Equipo: Roles | Solo con `staff.manage`. Los roles con cuántos permisos tienen, cuántas personas activas y si están activos. El editor es un checklist por área (Productos, Pedidos, Inventario, Promociones, Clientes VIP, Estadísticas, Tienda, Equipo) con lo que permite cada permiso; marcar uno que necesita otro (cambiar el estado de los pedidos necesita verlos) marca los dos. El rol del sistema (Administrador) se abre bloqueado. Crear, editar, desactivar y borrar; un nombre repetido o un rol con personal asignado muestran el motivo del servidor. |

Las piezas compartidas están en `features/admin/shared/`:
- `AdminTable<T>`:
  - la tabla de cada sección: columnas (`AdminColumn`), paginación ("1–20 de 54"), cargando,
    error con "Reintentar" y vacío;
  - desde 720 px de ancho es una tabla; más angosto, cada fila es una tarjeta con
    `etiqueta: valor`;
  - cada fila es un botón con su descripción para el lector de pantalla;
  - con `rowActions` (`AdminRowAction`), cada fila tiene además sus botones (p. ej.
    "Cambiar rol" y "Desactivar"), fuera de la descripción de la fila: al final en la tabla y
    abajo en las tarjetas. Con `showFor`, una acción sale solo en las filas que la tienen.
- `EmailsAddForm`: agregar uno o varios correos pegados, con el resumen del servidor
  (agregados, ya estaban, no válidos). Lo usan los clientes VIP y el equipo (con el rol como
  campo extra).
- `showAdminForm`: un formulario en un diálogo en pantallas anchas y a pantalla completa en el
  teléfono. Con `admin_form.dart` (campos de a dos, el error del servidor y los botones) y
  `ProductPicker` (el buscador de productos con autocompletado). `showRejected`: el motivo
  de una acción rechazada por el servidor, en un aviso.
- `RefreshButton`: el "Actualizar" de cada tabla; vuelve a pedir la página que se ve y, si falla,
  lo avisa sin vaciar la tabla.
- `PanelSearchField`: el buscador de cada sección (lupa y "x" para borrar). Mide 320 px y queda
  a la izquierda; en un teléfono ocupa todo el ancho.
- `FilterChips`: los chips de un filtro. En el teléfono se deslizan de lado; desde 600 px bajan
  a otra línea si no entran, porque con el mouse no se desliza de lado.
- `StatusBadge` (punto de color más texto), `VipBadge` (la insignia de lo que es solo para
  clientes VIP), `FulfillmentBadge` ("Domicilio" o "Recojo" con su ícono), `PanelTabs` (las
  pestañas de una sección, cada una con su ruta) y `confirmAction`.

Los datos van por sección en `lib/admin/<dominio>/` (modelo, repositorio HTTP con el ID token
y providers). Las tablas usan `PagedNotifier<T>`, con los filtros como argumento del provider
(family). Crear, editar y borrar pasan por el notifier, que actualiza la página sin recargar
toda la pantalla.

## Probar de punta a punta

Para presentar la app (levantar todo en modo release y un guion de demo), ver
[`docs/DEMO.md`](../../docs/DEMO.md).

Con el servidor corriendo y la config de Firebase de la plataforma. La primera vez, correr
`dart run bin/seed_dev.dart` (ver el README del servidor): deja productos, 40 pedidos de ejemplo
de los últimos 30 días (así el inicio del panel tiene ventas) y productos en las alertas.

1. `flutter run -d chrome` (o en el emulador). Crear una cuenta en **Crear una cuenta**: termina
   en `/catalogo`, con el nombre en la barra.
2. Agregar productos, abrir el carrito y confirmar el pedido: termina en `/mis-pedidos`, con el
   aviso y el pedido en "Pendiente".
3. Hacer admin a esa cuenta: en el servidor, `firstAdminEmail` en `config/passwords.yaml` con
   su correo y reiniciarlo (ver "Primer admin" en el README del servidor). El correo tiene que
   estar verificado: el aviso "Verifica tu correo" de la app manda el correo.

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
- `test/users/http_user_repository_test.dart`, `test/catalog/http_catalog_repository_test.dart`,
  `test/orders/http_order_repository_test.dart` y `test/store/http_store_repository_test.dart`: cada ruta REST con un cliente HTTP simulado
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
  - recoger en tienda: los datos de la tienda (con su teléfono), el código y las opciones sin
    ícono en un teléfono;
  - `/mis-pedidos` con la entrega de cada pedido y "Actualizar" animando el seguimiento.
- `test/auth/auth_error_message_test.dart`: los mensajes de cada error de Firebase.
- `test/features/account_bar_test.dart`: la barra con sesión entra en un teléfono de 320 y 375
  px (la cuenta va en un menú).
- `test/features/swoosh_test.dart` y `home_screen_test.dart`: la forma del trazo, que se dibuja
  una vez y en menos de un segundo, y que con "reducir animaciones" aparece completo.
- `test/features/product_card_test.dart`: precio, promoción, el precio VIP (insignia, entrada
  de 300 ms una sola vez), "Agotado", tarjetas de igual alto y el achique de "Agregar" (que no
  ocurre con "reducir animaciones").
- `test/features/exclusive_offers_test.dart`: las ofertas de una cuenta VIP en el inicio y el
  catálogo, y que un visitante o un cliente que no es VIP no ven nada VIP (ni se piden).
- `test/features/verify_email_test.dart`: el aviso para confirmar el correo y el refresco del
  perfil al volver a la app.
- `test/features/order_tracker_test.dart`: cuánto se llena cada tramo por estado, la animación al
  avanzar (a mitad de camino y al final), cancelado y el estado como texto.
- `test/theme/theme_test.dart`: colores, contraste y fuentes del tema, también los pares del
  marcador sin foto.
- `test/features/product_photo_test.dart`: la foto subida se pide al servidor de la app y una
  URL externa tal cual; sin foto, la inicial sobre el color de su categoría, el mismo siempre.
- `test/admin/`: el panel, con repositorios en memoria y una sesión de staff, del rol que se
  pida o con justo los permisos que se pidan (`pumpPanel` en `panel_support.dart`; las
  plantillas Almacenero y Cajera en `test/support.dart`):
  - `admin_access_test.dart`: el menú y las rutas de cada rol, "No tienes acceso", los botones
    según el permiso, a dónde llega cada uno al ingresar y un rol que cambia al volver a la app;
  - `admin_repositories_test.dart`: cada repositorio del panel con `MockClient`, también la
    subida de la foto (PUT con los bytes, su tipo y el token);
  - `admin_table_test.dart` y `admin_shell_test.dart`: tabla o tarjetas según el ancho,
    paginación, estados, y la navegación (riel o barra);
  - `admin_home_test.dart`: los KPI, los pedidos por estado (con los de recojo) y por tipo de
    entrega, el gráfico (30 puntos, la tabla de datos), las alertas, el top 5 y una tarjeta que
    falla sola;
  - `admin_pickup_test.dart`: "Para recoger": el orden, el tiempo de espera, la búsqueda,
    marcar listo y entregar con el código (el error en el diálogo), los permisos y el teléfono;
  - `admin_store_test.dart`: el formulario de la tienda (lo que manda, lo obligatorio, el
    rechazo del servidor) y que solo se ve con `store.manage`;
  - `admin_orders_test.dart`, `admin_products_test.dart`, `admin_inventory_test.dart`,
    `admin_promotions_test.dart`, `admin_vip_test.dart`, `admin_team_test.dart` y
    `admin_roles_test.dart`: filtros, formularios (validación y lo que se manda), los errores
    del servidor (400, 403 y 409: el último Administrador, un rol con personal), las
    confirmaciones, lo que ve staff y lo que ve admin, y que no se desborde en 320 y 375 px;
  - `emails_test.dart`: separar los correos pegados y validarlos como el servidor.

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
