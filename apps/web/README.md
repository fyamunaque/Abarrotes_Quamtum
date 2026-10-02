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

Para entrar al admin en desarrollo, usa el ADMIN de prueba que crea `npx prisma db seed` (ver `apps/api/README.md`); el seed imprime su email y contraseña. Con ese usuario, el enlace "Admin" aparece en el encabezado.

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

## Sistema de diseño (Neil's Food Services)

Tailwind 4 no usa `tailwind.config`: los tokens están en `src/app/globals.css` (`@theme`). Cada uno genera utilidades (`bg-primary`, `text-ink`, `border-primary-tint`…) y además existe como variable CSS (`var(--color-primary)`). En los componentes usa los tokens, no colores hex.

| Token | Valor | Uso previsto |
|---|---|---|
| `primary` | `#E8652F` | Color de marca (el naranja del logo) |
| `primary-dark` | `#B54F25` | Hover y fondos con texto claro |
| `accent` | `#A1241B` | Acentos (el rojo del logo) |
| `cream` | `#F9F3E7` | Fondo base del sitio (en vez de blanco) |
| `ink` | `#1D0605` | Texto base (en vez de gris) |
| `primary-tint` | `#F6D9C6` | Fondos suaves, chips, selecciones |

- **Tipografía** (con `next/font/google` en `src/app/layout.tsx`): `font-display` = Baloo 2 (600/700/800) para títulos y precios; `font-sans` = Inter (400/500/600), la fuente por defecto. `h1`–`h3` ya usan Baloo 2.
- **Contraste** (WCAG AA pide 4,5:1 para texto normal y 3:1 para texto grande): blanco sobre `primary` da 3,3:1, y crema sobre `primary` o `primary` sobre crema dan 3,0:1. El naranja solo sirve para texto grande (≥ 24 px, o 19 px en negrita) o elementos gráficos. Para texto normal: blanco sobre `primary-dark` (5,1:1), `ink` sobre `primary` (5,9:1), o `accent` sobre crema (6,8:1).
- **Logo**: `public/logo.png` (cabecera y hero de la portada). `src/app/icon.png` y `apple-icon.png` son el favicon y el ícono de iOS.
- **Movimiento**: la página tiene una sola animación al cargar. El swoosh granate del hero (`src/components/HomeHero.tsx`) se dibuja de izquierda a derecha en 650 ms, 200 ms después de que aparece el titular, una sola vez (`animate-draw-swoosh` en `globals.css`). Con `prefers-reduced-motion` se muestra ya dibujado. No agreguen entradas animadas (fade, slide) a otras secciones.
- Los componentes actuales todavía usan la paleta verde anterior (`brand-*`, `accent-600`), que sigue en `globals.css` hasta migrarlos.

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
