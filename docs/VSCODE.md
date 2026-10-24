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

## La app en el teléfono Android por USB

1. Activar la depuración USB en el teléfono y conectarlo (ver "Tu teléfono Android por cable USB"
   en `docs/DEMO.md`).
2. Elegir el teléfono abajo a la derecha, en la barra de estado de VS Code.
3. Con el servidor corriendo: **Run and Debug** → **App en el teléfono por USB** → `F5`. Primero
   pasa el puerto del servidor por el cable (`adb reverse`) y después instala la app en release.

## Otras tareas (Terminal → Run Task)

| Tarea | Cuándo |
|---|---|
| Servidor: aplicar migraciones | Al traer cambios del modelo de datos (una migración nueva en `apps/server/abarrotes_server/migrations/`). |
| Servidor: datos de ejemplo | Para completar el catálogo, las fotos y los pedidos de ejemplo. |
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
