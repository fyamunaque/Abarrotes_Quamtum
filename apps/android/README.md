# App Android — Kotlin + Jetpack Compose

App del cliente: catálogo con búsqueda y filtro por categoría, detalle de producto, carrito, login/registro, generación de pedidos y "Mis pedidos" (seguimiento del estado), contra la API de [`/apps/api`](../api/README.md).

## Requisitos

- Android Studio **Quail 4 (2026.1.4) o posterior**: AGP 9.4 no abre en versiones anteriores.
- Un emulador (o teléfono) con Android 8.0+.
- PostgreSQL y la API corriendo (ver `apps/api/README.md`).

Versiones: AGP 9.4 (requiere Gradle 9.6+), Gradle 9.8, Kotlin 2.4, Compose BOM 2026.09, `compileSdk`/`targetSdk` 37, `minSdk` 26. AGP 9 compila Kotlin por sí mismo: **no** agregues el plugin `org.jetbrains.kotlin.android` a los módulos.

## Correr la demo

1. **API**: con PostgreSQL encendido (en Windows es un servicio que arranca solo), desde la raíz del repo:

   ```bash
   cd apps/api && npm run start:dev
   ```

   Comprueba que responde en http://localhost:3001/health.

2. **Proyecto**: en Android Studio, *File → Open…* y elige la carpeta **`apps/android`**, no la raíz del monorepo (la raíz no es un proyecto Gradle). Espera a que termine la sincronización de Gradle.

3. **Emulador**: en *Device Manager* elige uno con Android 17 (API 37) o créalo con *Create Virtual Device → Pixel → API 37 (Google APIs, x86_64)*. Al arrancar en frío, la Wi‑Fi simulada puede tardar un minuto en conectarse: si el catálogo dice "No se pudo conectar", espera y toca *Reintentar*.

4. **Ejecutar**: configuración `app` → ▶ Run. La primera vez Android 17 pregunta si la app puede acceder a dispositivos cercanos / de la red local: elige **Permitir** (ver "Red local" abajo).

Por defecto la app apunta a `http://10.0.2.2:3001/`, que es el `localhost` de la PC visto desde el emulador. En un teléfono físico usa la IP de tu PC en la red local, sin editar archivos del repo:

```properties
# ~/.gradle/gradle.properties
abarrotes.apiBaseUrl=http://192.168.1.50:3001/
```

Solo la build **debug** permite HTTP sin TLS (`src/debug/res/xml/network_security_config.xml`). La build release exige HTTPS.

### Red local (Android 17+)

Android 17 bloquea el tráfico hacia la red local (`10.0.2.2`, `192.168.x.x`) de las apps sin el permiso `ACCESS_LOCAL_NETWORK`. El síntoma es un timeout de conexión aunque la API responda en el navegador de la PC. La build debug declara el permiso (`src/debug/AndroidManifest.xml`) y `MainActivity` lo pide antes de mostrar el catálogo. La release no lo declara, porque habla con la API pública por HTTPS.

Si lo rechazaste, actívalo en *Ajustes → Apps → Abarrotes → Permisos → Dispositivos cercanos*, o desde la terminal:

```bash
adb shell pm grant com.abarrotes.app android.permission.ACCESS_LOCAL_NETWORK
```

### Recorrido sugerido

1. Catálogo → filtrar por categoría o buscar → abrir un producto → *Agregar al carrito*.
2. Carrito → *Inicia sesión para pedir* → *Regístrate* (crea un cliente nuevo) → vuelve al carrito.
3. Dirección de entrega → *Generar pedido* → confirmación → *Ver mis pedidos*.
4. En la web (`/admin/pedidos`, con el admin del seed) confirma o envía el pedido y actualiza "Mis pedidos" en la app: el estado cambia.

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
  ui/order/                 -> confirmación del pedido y "Mis pedidos"
  ui/navigation/            -> rutas type-safe de Navigation Compose
```

## Cómo funciona

- **Catálogo público**: no hace falta cuenta para ver productos. La búsqueda espera 300 ms tras la última tecla; tocar una categoría seleccionada vuelve a "Todas".
- **Carrito en memoria** (`CartViewModel`, a nivel de Activity): lo comparten todas las pantallas y se pierde si el sistema cierra la app. No deja pedir más que el stock conocido ni más de 999 por producto (límite de la API).
- **Pedido**: se pide login recién al generar el pedido; al volver al carrito se propone la dirección guardada en la cuenta. La app envía solo `productId` y `quantity`; precios y total los calcula el servidor. Si el stock ya no alcanza, se muestra el mensaje de la API y el carrito se conserva.
- **Mis pedidos** (`GET /orders/mine`): ícono de lista en el catálogo o botón en la confirmación. Muestra estado, fecha (hora de Lima), líneas y total; se actualiza con el botón ↻. Pide login si no hay sesión y carga sola al iniciarla.
- **Sesión**: access + refresh token en DataStore. Ante un 401, OkHttp renueva los tokens y reintenta una vez; si el refresh es rechazado, la sesión se cierra.
- **Montos**: la API los manda como string; la app usa `BigDecimal` y los muestra como `S/ 4.50`.

## Pendiente

- Guardar tokens cifrados (hoy están en DataStore sin cifrar, dentro del almacenamiento privado de la app).
- Cambiar `applicationId` (`com.abarrotes.app`) por el dominio real antes de publicar en Google Play.
