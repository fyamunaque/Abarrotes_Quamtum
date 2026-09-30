# Web — Marketplace (Next.js)

Tienda pública: catálogo con filtro por categoría y búsqueda, detalle de producto, carrito, login/registro y checkout contra la API de [`/apps/api`](../api/README.md). El dashboard `/admin` (Fase 3) vivirá en esta misma app.

Next.js 16 (App Router, Turbopack), React 19, Tailwind CSS 4, Zustand. Los tipos de la API vienen de [`@abarrotes/shared-types`](../../packages/shared-types/src/index.ts).

> Next.js 16 cambió varias APIs (`params`/`searchParams`/`cookies()` asíncronos, `error.tsx` recibe `retry()`, `middleware` pasó a `proxy`…). Antes de escribir código aquí, lee la guía correspondiente en `node_modules/next/dist/docs/` (ver `AGENTS.md`).

## Correr en local

```bash
# 1. Dependencias: desde la raíz del monorepo
npm install

# 2. Configuración
cp apps/web/.env.example apps/web/.env.local   # API_URL=http://localhost:3001

# 3. La API tiene que estar corriendo (ver apps/api/README.md)
npm run web:dev                                 # http://localhost:3000
```

## Páginas

| Ruta | Qué hace |
|---|---|
| `/` | Catálogo. Filtros en la URL: `?categoria=<id>&q=<texto>&pagina=<n>` (se pueden compartir y funcionan sin JavaScript) |
| `/productos/[id]` | Detalle del producto |
| `/carrito` | Carrito: cambiar cantidades, quitar, total |
| `/checkout` | Dirección de entrega y confirmación del pedido. Pide login |
| `/checkout/confirmado` | Número, total y estado del pedido recién creado |
| `/ingresar`, `/registro` | Login y registro. Aceptan `?next=/ruta` para volver adonde estaba el cliente |
| `/admin/pedidos` | **Solo ADMIN/STAFF.** Pedidos con filtro por estado (`?estado=CONFIRMED`) y botones para avanzar o cancelar |
| `/admin/productos` | **Solo ADMIN/STAFF.** Productos (incluidos inactivos), búsqueda, desactivar/reactivar |
| `/admin/productos/nuevo`, `/admin/productos/[id]` | Alta y edición. El stock inicial se carga al crear; después se ajusta por inventario |

El primer ADMIN sale del seed de la API (`npm run prisma:seed`, ver `apps/api/README.md`). Con ese usuario, el enlace "Admin" aparece en el encabezado.

## Cómo funciona

- **El navegador nunca llama a la API.** Las páginas (Server Components) y las Server Actions de Next.js la llaman desde el servidor con `API_URL`. Por eso la API no necesita CORS para la web.
- **Sesión en cookies httpOnly** (`src/lib/session.ts`): access token, refresh token y un resumen del usuario (nombre, email, dirección). El JavaScript de la página no puede leerlas, así que un XSS no puede robar la sesión. Si el access token venció, se renueva solo con el refresh token al hacer el pedido.
- **Catálogo cacheado 30 s** (`src/lib/api.ts`). Esas peticiones van **sin** token, porque la respuesta la comparten todos los visitantes. El stock real se valida al crear el pedido.
- **Carrito con Zustand + localStorage** (`src/store/cart-store.ts`): sobrevive a recargas y es solo del navegador. No deja pedir más que el stock conocido ni más de 999 por producto. La lógica está en `src/lib/cart.ts` (funciones puras, con tests).
- **Montos en céntimos enteros** (`src/lib/money.ts`): la API manda `"4.5"` y se suma en céntimos para no acumular errores de coma flotante. Se muestran como `S/ 4.50`.
- **Pedido**: la Server Action `placeOrder` valida la forma del pedido (es un endpoint público) y envía solo `productId` y `quantity`; precios y total los calcula la API. Si falla (por ejemplo, stock insuficiente), el carrito se conserva y se muestra el mensaje de la API.

### Admin (`/admin`)

- **Tres capas de acceso**, de la más rápida a la que decide:
  1. `src/proxy.ts`: sin sesión, `/admin` redirige al login (307) antes de renderizar.
  2. `app/admin/layout.tsx`: pide el usuario a la API (`GET /auth/me`) y muestra "No tienes acceso" a los clientes. El rol que se guarda en la cookie solo decide si se muestra el enlace "Admin".
  3. La API: cada lectura y cada Server Action del admin viajan con el token del usuario, y la API responde 403 si el rol no es ADMIN/STAFF. Llamar a las acciones directamente no saltea nada.
- **Sesión renovada en `proxy.ts`**: el access token dura 15 min y los Server Components no pueden escribir cookies. Cuando venció y queda refresh token, el proxy lo renueva antes de renderizar. No corre en ningún otro caso (ver `config.matcher`).
- **Sin caché**: las lecturas del admin llevan token y usan `cache: 'no-store'`. Al guardar un producto o cancelar un pedido, `updateTag('catalog')` refresca el catálogo público al instante.
- **Estados de pedido**: los botones salen de `ORDER_STATUS_TRANSITIONS` (`src/lib/orders.ts`), copia de la regla de la API (`apps/api/src/orders/order-status.ts`), que es la que manda. Si cambian las transiciones, actualiza las dos.

## Scripts

```bash
npm run dev         # desarrollo
npm run build       # build de producción
npm run typecheck   # genera los tipos de rutas y corre tsc
npm run lint
npm test            # Vitest: lógica de src/lib
```

## Pendiente

- Página "Mis pedidos" (el endpoint `GET /orders/mine` ya existe).
- Tests de componentes y end-to-end (Playwright) una vez que haya una API de prueba con datos.
- Sincronizar el carrito entre pestañas abiertas.
