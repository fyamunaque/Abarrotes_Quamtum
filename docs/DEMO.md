# Demo: la app Flutter y el servidor Serverpod

Cómo levantar la tienda y el panel en tu máquina, con un guion para mostrárselos al cliente, cómo
compartir la demo y qué necesita otra computadora para levantarla en Android Studio.

Todo corre local: el cliente lo ve en tu pantalla o compartiéndola, o en su Android si está en
tu misma Wi-Fi. Para que lo abra desde cualquier lugar hay que publicarlo, y eso es otro paso.

Los comandos son de **Windows PowerShell 5.1**, y los `cd` parten de la raíz del repositorio.
Desde VS Code se levanta todo sin escribirlos: ver `docs/VSCODE.md`.

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

4. **Datos de ejemplo**: el catálogo (9 categorías) con sus fotos, 40 pedidos de los últimos
   30 días y productos en las alertas. Si la base ya tiene algo, completa lo que falta, también
   las fotos de los productos de ejemplo que no tienen una.

   ```powershell
   cd apps\server\abarrotes_server; dart run bin/seed_dev.dart
   ```

5. **Las cuentas.** La que se crea en la app es de cliente. Crear una cuenta pide el celular, una
   contraseña de al menos 8 caracteres con letras y números, y aceptar los términos; el DNI es
   opcional. Para hacer pedidos, además, hay que **confirmar el correo** con el enlace que manda
   Firebase.
   - Para el panel, pásala a admin en la base (ver "Primer admin" en `apps/server/README.md`).
   - Para mostrar el lado del cliente, crea una segunda cuenta con tu mismo correo y `+demo`
     (`tucorreo+demo@gmail.com`): Gmail lo deja en tu bandeja, así puedes abrir el enlace para
     confirmarlo.
   - Las cuentas de antes no tienen celular ni los términos: al ingresar, la app las lleva a
     "Mi cuenta" para completarlos.

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
- **Datos frescos:** desde `apps\server\abarrotes_server` (puede ser con el servidor corriendo):

  ```powershell
  dart run bin/seed_dev.dart --reiniciar
  ```

  Vuelve a generar los pedidos de ejemplo con fechas hasta hoy y fecha los vencimientos desde
  hoy. Así el gráfico llega hasta hoy, hay pedidos pendientes para confirmar y las alertas tienen
  algo. Tus pedidos de prueba no se tocan.

**El recorrido:**

1. **La tienda** (incógnito):
   - la portada para negocios: el titular, los sellos, "Nuestras categorías" y la banda de
     promociones (en el teléfono, el saludo, el buscador y las promociones en lista);
   - el catálogo con el filtro por categoría (y su encabezado) y "Promociones";
   - un producto con su cinta ("3x2"), la cantidad y el total en la pastilla verde, y la barra
     roja del carrito en el teléfono;
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
   camino", con el código de entrega en grande. En el panel, **Marcar entregado** pide ese
   código, como lo haría el repartidor (con la cuenta admin, también se puede entregar sin
   código, con el motivo).
6. **Productos:**
   - buscar por nombre o SKU;
   - el stock bajo resaltado;
   - editar un precio o crear un producto.
7. **Inventario:** registrar una entrada para el producto agotado. El formulario muestra cómo
   queda el stock antes de guardar, y en la tienda deja de estar agotado.
8. **Promociones:**
   - crear una que empiece hoy: en la tienda aparece el precio rebajado;
   - crear un **2x1** ("Tipo de promoción": NxM, lleva 2, paga 1) en otro producto: el catálogo
     lo muestra con la insignia "2x1" y, con dos unidades en el carrito, la línea dice
     "2x1 −S/ …" y abajo aparecen "Subtotal" y "Descuentos". Si se cruza con otra promoción del
     producto, el aviso "Se cruza con otras promociones" deja crearla igual (se acumulan).
   - **Códigos:** en la pestaña **Códigos**, "Nuevo código" (p. ej. `DEMO-10`, vigente hoy,
     "Usos por cliente": 1), guardar, abrirlo y "Agregar promoción" (un 2x1 o un % de un
     producto); después encenderlo y guardar. En la tienda, en el carrito, "¿Tienes un código?"
     lleva a "Mis códigos": escribir `demo-10` (vale en minúsculas), "Activar", y de vuelta en
     el carrito la línea dice "Código DEMO-10: …". Al hacer el pedido se gasta el uso: el código
     ya no aparece en "Mis códigos" (si se cancela el pedido, vuelve).
9. **Clientes VIP:**
   - pegar varios correos de una vez y mostrar el resumen (agregados, ya estaban, no válidos);
   - en **Promociones**, crear una "Solo clientes VIP": lleva la insignia VIP en la lista.

   - En la tienda, con una cuenta de cliente agregada como VIP y su correo verificado (el aviso
     "Verifica tu correo" manda el correo): al volver a la pestaña o abrir el catálogo aparecen
     el precio VIP con su insignia y las "Ofertas exclusivas", sin volver a ingresar.
   - Una cuenta que no es VIP no ve nada de eso.
10. **En el teléfono:** `F12` → ícono de dispositivo (`Ctrl+Shift+M`). La tienda y el panel se
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
| mostrarla en tu teléfono Android | El teléfono por cable USB (abajo) | La depuración USB activada y tu servidor corriendo |
| la pruebe en su Android, cerca tuyo | Un APK que apunta a tu computadora (abajo) | Los dos en la misma Wi-Fi y tu servidor corriendo |
| la pruebe desde otro lugar, en iPhone o en su navegador | Publicar el servidor y la web en internet | Un hosting (el objetivo del roadmap es Railway o Render, y Vercel): todavía no está |
| un desarrollador la levante | Clonar el repositorio (ver "En otra computadora") | Las herramientas de esa sección |

### Tu teléfono Android por cable USB

Lo más estable para una demo: el teléfono llega al servidor por el mismo cable, sin depender de la
Wi-Fi, la IP ni el firewall. `adb` está en `%LOCALAPPDATA%\Android\Sdk\platform-tools`.

1. **En el teléfono:** **Ajustes → Acerca del teléfono**, tocar 7 veces **Número de compilación**;
   después, en **Opciones de desarrollador**, activar **Depuración por USB**. Conectarlo y aceptar
   "¿Permitir depuración por USB?".
2. **Pasar el puerto del servidor por el cable**, cada vez que se conecta:

   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:8082 tcp:8082
   ```

3. **Compilar e instalar la app** desde `apps\client`, en release (rápida en cualquier teléfono),
   con el servidor en `localhost`:

   ```powershell
   flutter run --release --dart-define=API_URL=http://localhost:8082
   ```

   La versión release solo permite HTTP sin cifrar hacia el propio teléfono (`localhost`), que es
   justo lo que usa el cable; todo lo demás va por HTTPS.

   **O un APK con su número de versión**, que queda instalado y dice qué versión es (al pie de
   Ingresar y en el menú de la cuenta). Sube la versión de `pubspec.yaml`, compila, deja
   `build\apk\neils-<versión>.apk` y lo instala (el `adb reverse` lo hace solo). Desde VS Code es
   la tarea **App: generar APK e instalar en el teléfono** (ver `docs/VSCODE.md`):

   ```powershell
   dart run tool/build_apk.dart --instalar
   ```

### Un APK para un Android en la misma Wi-Fi

Para instalarlo como cualquier app, sin la depuración USB: el teléfono llega al servidor por la
Wi-Fi, a la IP de tu computadora.

1. **El APK**, desde `apps\client` (o la tarea **App: generar APK para Wi-Fi** de VS Code):

   ```powershell
   dart run tool/build_apk.dart --wifi
   ```

   - Sube la versión, busca tu IP en la red (p. ej. `192.168.1.20`; otra con
     `--wifi=192.168.1.20`) y compila en modo **profile**: es como release (rápido en cualquier
     teléfono), pero permite HTTP sin cifrar hacia la red, porque tu servidor no tiene HTTPS.
     Release solo lo permite hacia `localhost`.
   - Queda en `apps\client\build\apk\neils-<versión>-wifi.apk`. Pásalo al teléfono por cable
     (el teléfono aparece en "Este equipo": cópialo a su carpeta Download), Drive o WhatsApp.
2. **En el teléfono:** abrirlo desde el gestor de archivos y permitir "instalar apps de fuentes
   desconocidas" para esa app.
3. **Tu servidor tiene que estar corriendo**, y el teléfono en la misma Wi-Fi.
   - La primera vez, Windows pregunta si Dart puede usar la red: permitir.
   - Si el teléfono no conecta: en el navegador del teléfono, `http://<tu IP>:8082/categories`
     tiene que mostrar las categorías. Si no, revisa que estén en la misma Wi-Fi y que el
     firewall de Windows deje entrar a Dart (o a `main.exe`).
4. **Si cambias de red,** cambia tu IP: hay que generar el APK de nuevo.

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
