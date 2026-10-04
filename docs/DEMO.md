# Demo: la app Flutter y el servidor Serverpod

Cómo levantar la tienda y el panel en tu máquina, con un guion para mostrárselos al cliente, cómo
compartir la demo y qué necesita otra computadora para levantarla en Android Studio.

Todo corre local: el cliente lo ve en tu pantalla o compartiéndola, o en su Android si está en
tu misma Wi-Fi. Para que lo abra desde cualquier lugar hay que publicarlo, y eso es otro paso.

Los comandos son de **Windows PowerShell 5.1**, y los `cd` parten de la raíz del repositorio.

## La primera vez

1. **PostgreSQL** tiene que estar instalado, con la base `abarrotes_server` y
   `config/passwords.yaml` (ver `apps/server/README.md`). El servicio arranca solo con Windows.
2. **Flutter en el PATH.** Si `flutter --version` no responde, agrégalo en cada terminal que
   abras. Cambia la carpeta por la tuya:

   ```powershell
   $env:Path = "C:\ruta\a\flutter\bin;" + $env:Path
   ```

3. **Los paquetes**, uno por proyecto:

   ```powershell
   cd apps\server\abarrotes_server; dart pub get
   ```

   ```powershell
   cd apps\client; flutter pub get
   ```

4. **Datos de ejemplo**, si la base está vacía: el catálogo, 40 pedidos de los últimos 30 días y
   productos en las alertas.

   ```powershell
   cd apps\server\abarrotes_server; dart run bin/seed_dev.dart
   ```

5. **Las cuentas.** La que se crea en la app es de cliente.
   - Para el panel, pásala a admin en la base (ver "Primer admin" en `apps/server/README.md`).
   - Para mostrar el lado del cliente, crea una segunda cuenta. Firebase no verifica el correo,
     así que sirve tu mismo correo con `+demo` (`tucorreo+demo@gmail.com`).

## Cada vez

Dos terminales, que quedan abiertas durante toda la demo.

**1. El servidor**, desde `apps\server\abarrotes_server`:

```powershell
dart run bin/main.dart
```

Está listo cuando dice `Webserver listening on http://localhost:8082`.

**2. La app**, desde `apps\client`, en modo release (carga rápido):

```powershell
flutter run -d web-server --release --web-hostname localhost --web-port 5006
```

La primera compilación tarda uno o dos minutos. Está lista cuando dice
`lib\main.dart is being served at http://localhost:5006`. Ábrela en tu Chrome de siempre.

**Para cerrar:** `q` en la terminal de la app y `Ctrl+C` en la del servidor.

### Si algo falla

| Qué pasa | Qué hacer |
|---|---|
| "address already in use" o el puerto está ocupado | Ya hay otro servidor o app corriendo (otra terminal, o una sesión de Claude) en el 8082, 8088, 8081 o 5006. Ciérralo. |
| La app abre pero no hay productos, o dice que no hay conexión | El servidor no está corriendo, o todavía no terminó de arrancar. |
| El servidor no arranca y habla de la base | El servicio de PostgreSQL está detenido: `services.msc` → `postgresql-x64-18` → Iniciar. |
| Ingresaste como admin y llegas al catálogo | El rol se lee al ingresar: sal y vuelve a ingresar. |

## Guion para el cliente (15-20 minutos)

**Antes de empezar:**
- **Ventana normal de Chrome:** con la cuenta admin.
- **Ventana de incógnito** (`Ctrl+Shift+N`): para el lado del cliente, con la cuenta de prueba.
- **Imágenes:** los productos de ejemplo no tienen. Ponle una URL de imagen a 4 o 5 desde
  **Productos → editar**: el catálogo se ve mucho mejor.
- **Fechas:** las ventas de ejemplo son de los 30 días anteriores al día en que se cargaron.
  "Ventas de hoy" arranca en 0 hasta que haya un pedido de ese día: el que se hace en el paso 2
  lo llena.

**El recorrido:**

1. **La tienda** (incógnito):
   - la portada con el logo animado;
   - el catálogo con el filtro por categoría;
   - un producto en promoción, con el precio anterior tachado, y uno agotado;
   - el detalle de un producto.
2. **Comprar:** agregar al carrito, ingresar con la cuenta de prueba, confirmar el pedido. Termina
   en **Mis pedidos**, con el seguimiento en "Pendiente".
3. **El panel** (ventana admin), **Inicio:**
   - ventas de hoy (ya con ese pedido), de la semana y del mes, y el ticket promedio;
   - pedidos por estado;
   - el gráfico de 30 días ("Ver los datos" lo muestra en tabla);
   - stock bajo, por vencer y el top 5.
4. **Pedidos:** filtrar por "Pendiente de confirmación", abrir el pedido recién hecho, **Confirmar**
   y luego **Marcar en camino**.
5. **De vuelta en la tienda:** en **Mis pedidos**, **Actualizar**: el seguimiento avanza hasta "En
   camino".
6. **Productos:**
   - buscar por nombre o SKU;
   - el stock bajo resaltado;
   - editar un precio o crear un producto.
7. **Inventario:** registrar una entrada para el producto agotado. El formulario muestra cómo
   queda el stock antes de guardar, y en la tienda deja de estar agotado.
8. **Promociones:** crear una que empiece hoy. En la tienda aparece el precio rebajado.
9. **En el teléfono:** `F12` → ícono de dispositivo (`Ctrl+Shift+M`). La tienda y el panel se
   adaptan: en el panel, la navegación pasa abajo y las tablas, a tarjetas.

**Qué hay detrás**, si pregunta:
- una sola app en Flutter, para Android y web;
- el servidor en Dart (Serverpod) con PostgreSQL;
- las cuentas con Firebase;
- cada sección probada con tests automáticos.

**Qué todavía no está**, para no prometer de más:
- la app no está publicada: corre en esta máquina;
- desde el panel no se gestionan categorías ni usuarios (las cuentas de staff se crean a mano);
- no hay exportar a CSV, gráficos por rango de fechas ni notificaciones;
- los productos de ejemplo no traen imágenes.

## Compartir la demo

| Para que… | Cómo | Qué hace falta |
|---|---|---|
| alguien la vea | Compartir pantalla (Meet, Zoom) y seguir el guion | Nada más |
| la pruebe en su Android, cerca tuyo | Un APK que apunta a tu computadora (abajo) | Los dos en la misma Wi-Fi y tu servidor corriendo |
| la pruebe desde otro lugar, en iPhone o en su navegador | Publicar el servidor y la web en internet | Un hosting (el objetivo del roadmap es Railway o Render, y Vercel): todavía no está |
| un desarrollador la levante | Clonar el repositorio (ver "En otra computadora") | Las herramientas de esa sección |

### Un APK para un Android en la misma Wi-Fi

1. **Tu IP:** en PowerShell, `ipconfig` → "Dirección IPv4" del adaptador Wi-Fi (p. ej.
   `192.168.1.20`).
2. **El APK**, desde `apps\client`, con esa IP:

   ```powershell
   flutter build apk --debug --dart-define=API_URL=http://192.168.1.20:8082
   ```

   - Tiene que ser `--debug`: solo ese build permite HTTP sin cifrar, y tu servidor no tiene
     HTTPS.
   - Queda en `apps\client\build\app\outputs\flutter-apk\app-debug.apk`. Mándalo por Drive,
     WhatsApp o cable.
3. **En el teléfono:** abrir el archivo y permitir "instalar apps de fuentes desconocidas".
4. **Tu servidor tiene que estar corriendo.**
   - La primera vez, Windows pregunta si Dart puede usar la red: permitir en **redes privadas**.
   - Si el teléfono no conecta, revisa que tu red Wi-Fi esté marcada como **Privada** en
     Windows.
5. **Si cambias de red,** cambia tu IP: hay que generar el APK de nuevo.

La persona crea su cuenta en la app. Para que vea el panel, pásala a admin en tu base, como
cualquier otra cuenta.

## En otra computadora (Android Studio)

El repositorio es privado: primero hay que invitar a la persona en GitHub (**Settings →
Collaborators**). Las cuentas de Firebase son compartidas: es el mismo proyecto y su config ya
está en el repositorio. No hace falta acceso a la consola de Firebase ni `google-services.json`.

**Qué instalar:**
- **Git.**
- **Flutter 3.47.6 o más nuevo de la 3.47** (trae Dart 3.13.5, lo mínimo que pide la app).
- **PostgreSQL** (aquí se usa la 18).
- **Android Studio**, con:
  - los plugins **Flutter** y **Dart**;
  - en **SDK Manager → SDK Tools**, marcando "Show Package Details": **NDK (Side by side)
    30.0.16248370**. Tiene que ser esa versión: el proyecto la fija. Gradle y el plugin de
    Android se descargan solos en el primer build;
  - un emulador (**Device Manager**) o un teléfono con la depuración USB activada. El emulador
    pide unos 4 GB de RAM: con 8 GB en total, cerrar lo demás.

**Pasos:**

1. **Clonar** y pasar a la rama de la app (todavía no está en `develop`):

   ```powershell
   git clone https://github.com/fyamunaque/Abarrotes_Quamtum.git
   ```

   ```powershell
   cd Abarrotes_Quamtum; git checkout feature/flutter-client
   ```

2. **La base**, como superusuario `postgres`. Elige tu propia clave para `abarrotes`:

   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U postgres -c "CREATE ROLE abarrotes LOGIN CREATEDB PASSWORD 'tu-clave'"
   ```

   ```powershell
   & "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U postgres -c "CREATE DATABASE abarrotes_server OWNER abarrotes"
   ```

3. **`apps\server\abarrotes_server\config\passwords.yaml`.** No está en el repositorio:

   ```yaml
   shared:
     firebaseProjectId: 'prototype-440b7'
   development:
     database: 'tu-clave'
     serviceSecret: 'cualquier-texto-largo-y-al-azar'
   ```

4. **El servidor, la primera vez**, desde `apps\server\abarrotes_server`: paquetes, tablas y datos
   de ejemplo.

   ```powershell
   dart pub get; dart run bin/main.dart --role maintenance --apply-migrations; dart run bin/seed_dev.dart
   ```

5. **Levantar el servidor** (en la terminal de Android Studio o en PowerShell) y dejarlo abierto:

   ```powershell
   dart run bin/main.dart
   ```

6. **La app en Android Studio:**
   - **File → Open →** la carpeta `apps\client` (no la raíz del repositorio).
   - En **Settings → Languages & Frameworks → Flutter**, la carpeta de Flutter.
   - Aceptar **Pub get** cuando lo ofrezca.
   - Elegir el emulador arriba y **Run ▶**.
   - En el emulador, la app llama a `http://10.0.2.2:8082`, que es el servidor de esa misma
     computadora: no hay que configurar nada.
   - En un teléfono real por USB: **Run → Edit Configurations → Additional run args:**
     `--dart-define=API_URL=http://<IP de esa computadora>:8082`. Además, los dos en la misma
     Wi-Fi.
7. **La cuenta admin:** crear la cuenta en la app y pasarla a admin en **su** base. El rol vive
   en la base de cada computadora, no en Firebase (ver "Primer admin" en
   `apps/server/README.md`).

Cada computadora tiene sus propios datos. Arranca con los de ejemplo: los productos y pedidos de
otra no viajan.
