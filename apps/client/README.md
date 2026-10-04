# Cliente Flutter — Neil's Food Services

App de la tienda para **Android y web**, hecha en Flutter. Por ahora convive con la app Kotlin
(`apps/android`) y la web Next.js (`apps/web`). Cuando tenga todo lo que esas apps hacen, las
reemplaza. Habla con el backend Serverpod de `apps/server`.

- Paquete Android: `com.quamtum.neils` (el registrado en Firebase).
- Estado: [Riverpod](https://riverpod.dev). Rutas: [go_router](https://pub.dev/packages/go_router).

## Requisitos

- **Flutter 3.47.6** (trae Dart 3.13.5). En Windows: descomprimir el zip oficial en
  `%USERPROFILE%\develop\flutter` y agregar `%USERPROFILE%\develop\flutter\bin` al `Path` del
  usuario.
- Para Android, el SDK que ya usa `apps/android` más el **NDK 30.0.16248370**: en Android Studio,
  SDK Manager → SDK Tools → NDK (Side by side). `android/build.gradle.kts` fija esa versión en
  todos los módulos. Flutter pide el 28.2 y, en Windows, su instalador automático falla.
- Para la web, Chrome o Edge.

## Comandos (desde `apps/client`)

| Qué | Comando |
|---|---|
| Dependencias | `flutter pub get` |
| Correr en Chrome | `flutter run -d chrome` |
| Correr en el emulador o teléfono | `flutter run -d <dispositivo>` (ver `flutter devices`) |
| Análisis estático | `flutter analyze` |
| Tests | `flutter test` |
| Compilar la web | `flutter build web` (queda en `build/web`) |
| Compilar el APK | `flutter build apk --debug` |

## Estructura (`lib/`)

```
main.dart            URLs sin "#" en la web, fuentes empaquetadas, ProviderScope
app.dart             MaterialApp.router: tema, router, español
theme/               tokens de marca (brand_colors.dart) y ThemeData (neils_theme.dart)
session/             Session y sessionProvider (quién inició sesión y con qué rol)
router/              rutas, guard de /admin y GoRouter
features/<sección>/  pantallas: home, auth, catalog, admin, shared
```

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

## Rutas

| Ruta | Quién |
|---|---|
| `/`, `/login`, `/registro`, `/catalogo` | Cualquiera |
| `/admin` y sus subrutas | Solo `admin` y `staff` |

El guard (`router/route_guard.dart`) protege `/admin`:
- Sin sesión manda a `/login?from=...`, para volver después de ingresar.
- Una cuenta de cliente vuelve al inicio.
- Si la sesión cambia, el router vuelve a evaluar la ruta actual.

Por ahora la app arranca siempre sin sesión. El ingreso con Firebase Auth, y el rol desde
`GET /users/me`, se conectan en `session/session_provider.dart`.

## Tests

- `test/router/route_guard_test.dart`: el guard es una función pura; prueba cada ruta con cada
  tipo de sesión.
- `test/router/router_test.dart`: la app completa con una sesión simulada (`TestSession`), que se
  puede cambiar en medio del test.
- `test/theme/theme_test.dart`: colores y fuentes del tema.

Los tests que usan el tema llaman a `useBundledFonts()` (`test/support.dart`): fuentes desde los
assets, sin red. Ese helper también esquiva un fallo del motor de pruebas de Windows: cargar
Baloo2-SemiBold y Baloo2-Bold en el mismo proceso lo cierra sin error. Por eso, en los tests, la
SemiBold se reemplaza por la ExtraBold. La app no cambia.
