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

Corre la tarea **Levantar todo**, que abre dos terminales abajo:

- **Servidor**: listo cuando dice `Webserver listening on http://localhost:8082`.
- **Tienda web**: compila la app en release (uno o dos minutos la primera vez). Lista cuando dice
  `lib\main.dart is being served at http://localhost:5006`.

Después, abrir **http://localhost:5006** en Chrome. El panel está en `/admin` (con una cuenta
del personal).

También se puede levantar uno solo: **Terminal → Run Task → Servidor** (o **Tienda web**).

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
| Preparar paquetes | La primera vez y cuando cambian las dependencias. |
| Teléfono: pasar el puerto por USB | Cada vez que se conecta el teléfono (la configuración del teléfono ya lo hace sola). |

## Si algo falla

| Qué pasa | Qué hacer |
|---|---|
| `dart` o `flutter` "no se reconoce" | Falta el paso 2 de "La primera vez", o la carpeta de Flutter está mal escrita. |
| "address already in use", o el puerto 8082 o 5006 ocupado | Ya hay otro servidor o tienda corriendo: otra terminal, la configuración "Servidor (depurar)" o una sesión de Claude Code. Cerrarlo antes. |
| La tienda abre pero sin productos, o dice que no hay conexión | El servidor no está corriendo o todavía no terminó de arrancar. |
| El servidor no arranca y habla de la base | El servicio de PostgreSQL está detenido: `services.msc` → `postgresql-x64-18` → Iniciar. |
| La terminal de la tienda se queda en "Compiling..." mucho rato | La primera compilación en release tarda uno o dos minutos; las siguientes, menos. |
