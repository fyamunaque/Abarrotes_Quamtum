# Demo: la app Flutter y el servidor Serverpod

Cómo levantar la tienda y el panel en tu máquina, y un guion para mostrárselos al cliente. Todo
corre local: el cliente lo ve en tu pantalla, o compartiéndola. Para que lo abra desde su propio
dispositivo hay que publicarlo, y eso es otro paso.

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
