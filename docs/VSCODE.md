# Levantar el proyecto desde VS Code

El servidor Serverpod y la app Flutter, sin escribir comandos: con las tareas y las
configuraciones que están en `.vscode/`. Para los comandos a mano y el guion de la demo, ver
`docs/DEMO.md`.

## La primera vez

1. **Abrir la carpeta raíz del repo** (la que tiene `apps/` y `docs/`): **File → Open Folder**.
   Si VS Code sugiere instalar la extensión **Flutter** (trae también la de Dart), aceptar.
2. **Decirle a VS Code dónde está Flutter.** En esta computadora ya está hecho:
   `.vscode/settings.json` apunta a `C:\Users\aligh\develop\flutter`. En otra computadora, crear
   ese archivo con la carpeta de Flutter de esa máquina (no se sube a git):

   ```json
   {
     "dart.flutterSdkPath": "C:\\ruta\\a\\flutter",
     "dart.sdkPath": "C:\\ruta\\a\\flutter\\bin\\cache\\dart-sdk"
   }
   ```

   Si Flutter ya está en el PATH de Windows, este paso no hace falta.
3. **PostgreSQL** corriendo, con la base `abarrotes_server` y `config/passwords.yaml` (ver
   `apps/server/README.md`). El servicio arranca solo con Windows.
4. **Los paquetes:** **Terminal → Run Task → Preparar paquetes**. Repetirlo cuando cambien las
   dependencias (un `pubspec.yaml` nuevo).
5. **Datos de ejemplo** (opcional): **Terminal → Run Task → Servidor: datos de ejemplo**.

## Levantar todo: `Ctrl+Shift+B`

Corre la tarea **Levantar todo**, que abre dos terminales abajo, una después de la otra:

1. **Servidor**: listo cuando dice `Webserver listening on http://localhost:8082`.
2. **Tienda web**, cuando el servidor ya está listo: sirve la tienda compilada en release
   (`apps/client/tool/serve_web.dart`). Solo compila si no hay una compilación o si el código
   cambió desde la última (p. ej. después de un `git pull`), y eso tarda uno o dos minutos. Lista
   cuando dice `La tienda está en http://localhost:5006`.

Van en orden, y la tienda no recompila cada vez, para no pasarse de memoria: con 8 GB de RAM no
alcanza para el servidor y la tienda compilando a la vez, más VS Code y el navegador.

Después, abrir **http://localhost:5006** en Chrome. El panel está en `/admin` (con una cuenta
del personal).

También se puede levantar uno solo: **Terminal → Run Task → Servidor** (o **Tienda web**). Si
la tienda se ve desactualizada, **Tienda web: compilar de nuevo** la compila aunque no detecte
cambios.

**Para cerrar:** en el panel de terminales, el ícono de papelera de cada una (o **Terminal →
Terminate Task → Terminate All Tasks**).

## Para programar: la app en Chrome con recarga en caliente

1. Levantar el servidor: **Terminal → Run Task → Servidor**.
2. **Run and Debug** (`Ctrl+Shift+D`) → elegir **Tienda web en Chrome (para programar)** → `F5`.
   Se abre una ventana de Chrome con la app. Al guardar un archivo de `apps/client/lib`, se
   recarga sola.

Esta versión es de depuración: tarda más en cargar y usa más memoria que la de **Levantar todo**.
Con 8 GB de RAM, mejor no tener las dos a la vez.

## Depurar el servidor (con breakpoints)

En lugar de la tarea **Servidor** (las dos usan el puerto 8082): cerrar esa terminal y, en **Run
and Debug**, elegir **Servidor (depurar)** → `F5`. Los breakpoints van en
`apps/server/abarrotes_server/lib/`.

## La app en el teléfono Android por USB: un APK con su versión

1. Activar la depuración USB en el teléfono y conectarlo (ver "Tu teléfono Android por cable USB"
   en `docs/DEMO.md`; en un Xiaomi, además, "Instalar vía USB").
2. Levantar el servidor (tarea **Servidor**).
3. **Terminal → Run Task → App: generar APK e instalar en el teléfono**
   (`apps/client/tool/build_apk.dart --instalar`):
   - sube la versión en `pubspec.yaml`: 1.0.1+2 → 1.0.2+3 (el nombre y el número de compilación,
     que en Android son `versionName` y `versionCode`);
   - compila en release (unos minutos), para teléfonos ARM de 32 y 64 bits, con el servidor en
     `http://localhost:8082`;
   - deja el APK en `apps/client/build/apk/neils-1.0.2.apk`;
   - pasa el puerto del servidor por el cable (`adb reverse`) y lo instala encima de la versión
     anterior.
4. La app dice su versión ("Versión 1.0.2 (3)") al pie de Ingresar y en el menú de la cuenta: así
   se sabe qué APK tiene cada teléfono.
5. **Commitear `pubspec.yaml`** para que la versión quede registrada en git.

Con **App: generar APK** se genera sin instalarlo. Desde `apps/client`, el script acepta
`--minor` (1.0.2 → 1.1.0), `--major` (→ 2.0.0), `--misma` (recompila sin subir la versión, p. ej.
para instalar lo mismo en otro teléfono) y `--api=https://...` (otro servidor):

```powershell
dart run tool/build_apk.dart --minor --instalar
```

Al terminar apaga el daemon de Gradle, que si no se queda con un par de GB. Si el teléfono se
desconecta, el `adb reverse` se pierde: la tarea **Teléfono: pasar el puerto por USB** lo
vuelve a hacer.

Para programar en el teléfono (con depuración, sin APK ni versión): elegir el teléfono abajo a la
derecha, en la barra de estado, y en **Run and Debug** → **App en el teléfono por USB** → `F5`.

## Otras tareas (Terminal → Run Task)

| Tarea | Cuándo |
|---|---|
| Servidor: aplicar migraciones | Al traer cambios del modelo de datos (una migración nueva en `apps/server/abarrotes_server/migrations/`). |
| Servidor: datos de ejemplo | Para completar el catálogo, las fotos y los pedidos de ejemplo. |
| App: generar APK | Para un APK con la versión siguiente, sin instalarlo (queda en `apps/client/build/apk/`). |
| App: generar APK e instalar en el teléfono | Lo mismo, y lo instala en el teléfono conectado por USB. |
| App: generar APK para Wi-Fi | Para instalarlo como cualquier app (copiando el APK al teléfono), sin la depuración USB: llega al servidor por la Wi-Fi, a la IP de esta computadora. Ver "Un APK para un Android en la misma Wi-Fi" en `docs/DEMO.md`. |
| App: instalar el último APK en el teléfono | Sin compilar ni subir la versión: instala el APK que ya está (p. ej. si el teléfono no lo dejó instalar la primera vez). |
| Tienda web: compilar de nuevo | Si la tienda se ve desactualizada: la compila aunque no detecte cambios, y la sirve. |
| Preparar paquetes | La primera vez y cuando cambian las dependencias. |
| Teléfono: pasar el puerto por USB | Cada vez que se conecta el teléfono (la configuración del teléfono ya lo hace sola). |

## Si algo falla

| Qué pasa | Qué hacer |
|---|---|
| `dart` o `flutter` "no se reconoce" | Falta el paso 2 de "La primera vez", o la carpeta de Flutter está mal escrita. |
| "address already in use", "Failed to bind" o "El puerto 5006 ya está en uso" | Ya hay otro servidor o tienda corriendo: otra terminal, la configuración "Servidor (depurar)", una sesión de Claude Code o lo que quedó de un VS Code que se cerró de golpe (fila siguiente). Cerrarlo antes. |
| VS Code se cierra solo ("The window terminated unexpectedly") | Se quedó sin memoria. Cerrar lo que no se use (pestañas del navegador, Android Studio, el emulador) y volver a abrirlo. Las tareas que corrían pueden seguir vivas sin su terminal: en el **Administrador de tareas → Detalles**, finalizar los `dart.exe` y `dartaotruntime.exe` antes de levantar de nuevo. |
| La tienda abre pero sin productos, o dice que no hay conexión | El servidor no está corriendo o todavía no terminó de arrancar. |
| El servidor no arranca y habla de la base | El servicio de PostgreSQL está detenido: `services.msc` → `postgresql-x64-18` → Iniciar. |
| La terminal de la tienda se queda en "Compiling..." mucho rato | Compilar en release tarda uno o dos minutos. Solo pasa la primera vez y cuando el código cambió. |
