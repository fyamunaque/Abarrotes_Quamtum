# Cómo correr la demo (Windows)

Guía paso a paso para mostrar Neil's Food Services en una PC con Windows: la API, la tienda web con su panel admin y la app Android en el emulador. Los comandos son para **Windows PowerShell** (la terminal que trae Windows) y se escriben **uno por línea**.

Tiempo: unos 10 minutos la primera vez y 3 a 5 minutos las siguientes.

---

## 0. Una sola vez (en una PC nueva)

Si la PC ya corrió el proyecto, salta al paso 1.

1. **Programas**: Node.js 20 o superior, PostgreSQL y Android Studio Quail 4 o superior.
2. **Dependencias**, desde la carpeta del repo:

   ```powershell
   npm.cmd install
   ```

3. **Base de datos y datos de prueba**: sigue la sección "Puesta en marcha" de [`apps/api/README.md`](../apps/api/README.md). Crea `apps/api/.env`, la base, las tablas y los datos de prueba.
4. **Android Studio**:
   - *File → Open…* y elige la carpeta **`apps/android`**, no la raíz del repo.
   - *Settings → Tools → Emulator* y **desmarca "Launch in the Running Devices tool window"**. En PCs con 8 GB de RAM, el emulador dentro de la ventana de Android Studio se cierra al arrancar; en su propia ventana funciona.
   - *Device Manager*: crea un emulador **Pixel 7 con Android 17 (API 37, Google APIs, x86_64)**. Al editarlo, en las opciones adicionales (*Additional settings*), elige el arranque **Cold boot**: así arranca limpio cada vez y no carga un estado guardado que puede quedar dañado. En esta PC ya existe y está configurado: se llama `Abarrotes_API_37`.

---

## 1. Antes de empezar: liberar memoria

El emulador de Android 17 necesita **4 GB de RAM libres**, y la PC tiene 8 GB en total. Cierra el navegador y cualquier programa pesado que no vayas a usar. Para la demo bastan Android Studio, el emulador, dos terminales y un navegador con pocas pestañas.

Si te falta memoria, la app no necesita a Android Studio una vez instalada: puedes cerrarlo y abrir el emulador solo (paso 4, opción B).

---

## 2. Levantar la API (terminal 1)

PostgreSQL es un servicio de Windows y arranca solo con la PC. Abre PowerShell en la carpeta del repo:

```powershell
cd C:\Users\aligh\Desktop\Ally
```

```powershell
npm.cmd run api:dev
```

Espera el mensaje `Nest application successfully started` y comprueba en el navegador que http://localhost:3001/health responda `{"status":"ok"}`. Deja esta terminal abierta.

## 3. Levantar la web (terminal 2)

Abre otra terminal de PowerShell, también en la carpeta del repo:

```powershell
npm.cmd run web:dev
```

- La tienda queda en http://localhost:3000.
- El panel admin está en http://localhost:3000/admin/pedidos. Usuario: `admin@abarrotes.test`. La contraseña es el valor de `SEED_ADMIN_PASSWORD` en `apps/api/.env`, y volver a correr el seed (`npm.cmd run prisma:seed -w apps/api`) la restablece a ese valor.

## 4. Abrir el emulador y la app

**Opción A, desde Android Studio**: elige `Abarrotes_API_37` y presiona ▶ Run. Android Studio espera a que arranque el emulador, instala la app y la abre.

**Opción B, sin Android Studio** (usa menos memoria; la app ya tiene que estar instalada). En una tercera terminal:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Abarrotes_API_37 -netdelay none -netspeed full -no-snapstorage
```

Cuando aparezca la pantalla de inicio de Android, abre la app **Neil's**.

Ten en cuenta:

- El arranque en frío tarda **1 a 3 minutos**, y la Wi‑Fi simulada puede tardar un minuto más. Si el catálogo dice "No se pudo conectar con el servidor", espera y toca *Reintentar*.
- La primera vez Android pregunta si la app puede acceder a **dispositivos cercanos**: elige **Allow / Permitir**. Sin ese permiso la app no llega a la API de la PC.
- Si aparece "System UI isn't responding", toca **Wait**: es el emulador yendo lento, no la app.

---

## 5. Recorrido sugerido para presentar

1. **Web, portada** (http://localhost:3000): el trazo granate bajo el titular se dibuja al cargar (recarga la página para verlo otra vez). En una tarjeta, toca **Agregar**: el botón rebota y el carrito de la cabecera pulsa con el contador.
2. **App, catálogo**: filtra por categoría o busca, abre un producto y agrégalo al carrito.
3. **App, pedido**: en el carrito, inicia sesión o regístrate (para mostrar el registro, primero *Cerrar sesión*), revisa la dirección y toca *Generar pedido*. Luego, *Ver mis pedidos*: el pedido aparece "Pendiente de confirmación".
4. **Web, panel admin** (http://localhost:3000/admin/pedidos): entra como administrador y confirma o envía ese pedido.
5. **App, seguimiento**: en "Mis pedidos" toca ↻: el estado cambia a "Confirmado" o "En camino".

---

## 6. Si algo falla

| Lo que ves | Por qué pasa | Qué hacer |
|---|---|---|
| `El token '&&' no es un separador de instrucciones válido` | Windows PowerShell no acepta `&&` | Escribe los comandos de a uno, en líneas separadas. |
| `No se puede cargar el archivo ...\npm.ps1 porque la ejecución de scripts está deshabilitada` | La política de Windows bloquea los scripts `.ps1` | Usa `npm.cmd` en vez de `npm` (y `npx.cmd` en vez de `npx`). |
| `Insufficient RAM free for launching emulator` | No hay 4 GB libres | Cierra el navegador y otros programas, y vuelve a intentarlo. |
| El emulador se abre y se cierra solo, o se queda en negro | Está corriendo dentro de la ventana de Android Studio, o cargó un estado guardado dañado | Desmarca "Launch in the Running Devices tool window" (paso 0) y en *Device Manager → ⋮ → Cold Boot Now*. |
| Android Studio: `Can't find service: package` al presionar Run | El emulador todavía no terminó de arrancar | Espera la pantalla de inicio de Android y vuelve a presionar Run. |
| La app: "No se pudo conectar con el servidor" | La API no está corriendo, o la red del emulador aún no está lista | Revisa http://localhost:3001/health, espera un minuto y toca *Reintentar*. |
| La app tarda y termina sin conectar, aunque la API responde | Se rechazó el permiso de "dispositivos cercanos" | En el emulador (en inglés): *Settings → Apps → Neil's → Permissions → Nearby devices → Allow*. |
| Android Studio o Gradle: `There is insufficient memory for the Java Runtime Environment` | La PC se quedó sin memoria al compilar | Cierra programas y vuelve a compilar. |
| `EADDRINUSE` o "puerto en uso" al levantar la API (3001) o la web (3000) | Ya hay una copia corriendo en otra terminal | Usa esa terminal, o ciérrala con `Ctrl + C` y vuelve a levantarla. |
| No recuerdas la contraseña del admin | — | Es `SEED_ADMIN_PASSWORD` en `apps/api/.env`. |

## 7. Al terminar

- **API y web**: `Ctrl + C` en cada terminal.
- **Emulador**: ciérralo con la ✕ de su ventana.

Más detalles de cada parte: [API](../apps/api/README.md), [web](../apps/web/README.md) y [Android](../apps/android/README.md).
