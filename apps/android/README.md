# App Android — Kotlin + Jetpack Compose

App del cliente: catálogo con búsqueda y filtro por categoría, detalle de producto, carrito, login/registro y generación de pedidos contra la API de [`/apps/api`](../api/README.md).

## Requisitos

- Android Studio reciente (o JDK 17+ y el Android SDK con la plataforma 37).
- La API corriendo (ver `apps/api/README.md`).

Versiones: AGP 9.4 (requiere Gradle 9.6+), Gradle 9.8, Kotlin 2.4, Compose BOM 2026.09, `compileSdk`/`targetSdk` 37, `minSdk` 26. AGP 9 compila Kotlin por sí mismo: **no** agregues el plugin `org.jetbrains.kotlin.android` a los módulos.

## Correr la app

1. Abre la carpeta `apps/android` en Android Studio (no la raíz del monorepo).
2. Levanta la API (`cd apps/api && npm run start:dev`, puerto 3001).
3. Ejecuta la configuración `app` en un emulador.

Por defecto la app apunta a `http://10.0.2.2:3001/`, que es el `localhost` de la PC visto desde el emulador. En un teléfono físico usa la IP de tu PC en la red local, sin editar archivos del repo:

```properties
# ~/.gradle/gradle.properties
abarrotes.apiBaseUrl=http://192.168.1.50:3001/
```

Solo la build **debug** permite HTTP sin TLS (`src/debug/res/xml/network_security_config.xml`). La build release exige HTTPS.

Desde la terminal:

```bash
./gradlew assembleDebug        # APK en app/build/outputs/apk/debug/
./gradlew testDebugUnitTest    # tests unitarios
```

## Estructura

```
app/src/main/java/com/abarrotes/app/
  di/AppContainer.kt        -> inyección manual: Retrofit, OkHttp, repositorios
  data/remote/              -> API (Retrofit), DTOs, errores, token + refresh automático
  data/session/             -> tokens y datos del usuario en DataStore
  data/*Repository.kt       -> catálogo, auth y pedidos
  ui/catalog/               -> lista con búsqueda, categorías y paginación infinita
  ui/product/               -> detalle
  ui/cart/                  -> carrito (Cart = lógica pura; CartViewModel = estado)
  ui/auth/                  -> login y registro
  ui/order/                 -> confirmación del pedido
  ui/navigation/            -> rutas type-safe de Navigation Compose
```

## Cómo funciona

- **Catálogo público**: no hace falta cuenta para ver productos. La búsqueda espera 300 ms tras la última tecla; tocar una categoría seleccionada vuelve a "Todas".
- **Carrito en memoria** (`CartViewModel`, a nivel de Activity): lo comparten todas las pantallas y se pierde si el sistema cierra la app. No deja pedir más que el stock conocido ni más de 999 por producto (límite de la API).
- **Pedido**: se pide login recién al generar el pedido. La app envía solo `productId` y `quantity`; precios y total los calcula el servidor. Si el stock ya no alcanza, se muestra el mensaje de la API y el carrito se conserva.
- **Sesión**: access + refresh token en DataStore. Ante un 401, OkHttp renueva los tokens y reintenta una vez; si el refresh es rechazado, la sesión se cierra.
- **Montos**: la API los manda como string; la app usa `BigDecimal` y los muestra como `S/ 4.50`.

## Pendiente

- Pantalla "Mis pedidos" (el endpoint `GET /orders/mine` ya existe).
- Ícono de la app (usa el de Android por defecto).
- Guardar tokens cifrados (hoy están en DataStore sin cifrar, dentro del almacenamiento privado de la app).
- Cambiar `applicationId` (`com.abarrotes.app`) por el dominio real antes de publicar en Google Play.
