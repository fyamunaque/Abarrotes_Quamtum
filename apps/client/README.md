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
config/                URL del servidor (API_URL)
auth/                  AuthRepository (Firebase Auth) y los providers de los repositorios
users/                 UserRepository: el perfil y el rol desde GET /users/me
session/               Session y sessionProvider (quién ingresó y con qué rol)
catalog/               Product (montos en céntimos, como el servidor)
orders/                OrderStatus (los estados del servidor, con los textos de la web)
common/                formatSoles
router/                rutas, guard de /admin y GoRouter
theme/                 tokens de marca y de estados (brand_colors.dart), ThemeData
                       (neils_theme.dart) y movimiento (motion.dart)
features/<sección>/    pantallas y componentes: home, auth, catalog, orders, admin,
                       showcase (la vitrina) y shared (logo, barra, swoosh, PressScale)
```

Las pantallas no hablan con Firebase ni con HTTP: usan `sessionProvider`, que usa los
repositorios. Los tests reemplazan los repositorios por versiones en memoria.

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
no alcanza el contraste de un texto. El rojo de cancelado sí (6,8:1).

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

| Ruta | Quién |
|---|---|
| `/`, `/login`, `/registro`, `/catalogo` | Cualquiera |
| `/admin` y sus subrutas | Solo `admin` y `staff` |

**Sesión** (`session/session_provider.dart`): hay sesión cuando hay una cuenta de Firebase y el
servidor devolvió su perfil.
- Al arrancar es `SessionLoading`, hasta saber si quedó una cuenta abierta. Firebase la guarda de
  forma segura en cada plataforma y renueva el ID token solo.
- Registrarse crea la cuenta en Firebase con su nombre. Después, `GET /users/me` la crea en la
  tienda, siempre como `customer`. Las cuentas admin y staff las crea un admin.
- Si el servidor no responde, la app cierra también la cuenta de Firebase y muestra el error: sin
  perfil no hay rol.

**Después de ingresar** (`routeAfterSignIn` en `router/route_guard.dart`):
- un cliente va a `/catalogo`;
- admin y staff van a `/admin`, o a la ruta del panel que pidió el ingreso (`/login?from=...`).

**El guard** protege `/admin`:
- sin sesión, manda a `/login?from=...`;
- con una cuenta de cliente, vuelve al inicio;
- mientras la sesión carga, el panel muestra un indicador.

Si la sesión cambia (p. ej. "Salir"), el router vuelve a evaluar la ruta actual.

## Probar el ingreso real

Con el servidor corriendo y la config de Firebase de la plataforma:

1. `flutter run -d chrome` (o en el emulador). Crear una cuenta en **Crear una cuenta**: termina
   en `/catalogo`, con el nombre en la barra.
2. Pasarla a admin en la base del servidor:

   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U abarrotes -d abarrotes_server -c "UPDATE users SET role = 'admin' WHERE email = 'correo@ejemplo.com'"
   ```

3. **Salir** e ingresar de nuevo: termina en `/admin`.

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
- `test/users/http_user_repository_test.dart`: `GET /users/me` con un cliente HTTP simulado.
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

Los tests de movimiento usan `MediaQueryData(disableAnimations: true)` para "reducir
animaciones" y `tester.hasRunningAnimations` para saber si quedó algo animándose. Flutter da por
terminada una animación en el frame siguiente a su duración: por eso avanzan un milisegundo más.

Los tests que usan el tema llaman a `useBundledFonts()` (`test/support.dart`): fuentes desde los
assets, sin red. Ese helper también esquiva un fallo del motor de pruebas de Windows: cargar
Baloo2-SemiBold y Baloo2-Bold en el mismo proceso lo cierra sin error. Por eso, en los tests, la
SemiBold se reemplaza por la ExtraBold. La app no cambia.

Con poca RAM libre, `flutter test` puede cortar a mitad algún test ("did not complete", sin
error): corre varios motores de prueba en paralelo. En ese caso, `flutter test --concurrency=1`,
y sin `flutter run` abierto al mismo tiempo.
