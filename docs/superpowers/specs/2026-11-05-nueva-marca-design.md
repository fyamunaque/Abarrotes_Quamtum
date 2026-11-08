# Nueva marca: logo, color, fuente y rediseño de la tienda y el panel

**Fecha:** 2026-11-05
**Base:** `feature/codigos-promocionales` (PR #12)
**Referencias del cliente:** tres imágenes. Las dos maquetas (app en el teléfono, y la web con el panel y el ingreso) son una idea a seguir, no a copiar. La tercera es el logo nuevo (JPG de 1254 × 1254, fondo blanco).

## Objetivo

La app cambia de identidad:
- **Logo:** el tenedor y "NEIL'S / FOOD SERVICE'S".
- **Color:** rojo, en vez del naranja.
- **Fuente:** Poppins para los títulos.
- **Público:** la tienda pasa a hablarle a negocios (restaurantes, fast foods, cocinas), no a hogares.

Cada pantalla de la tienda y del panel toma un estilo parecido al de las maquetas y lo mejora donde se pueda: contraste, teléfono y escritorio, estados vacíos. Además se suman dos funciones que muestran las maquetas: las pestañas **Frecuentes y Sugeridos**, y las **fotos de categorías**.

## Decisiones tomadas con el cliente

| Tema | Decisión |
|---|---|
| Alcance | El rediseño de todo lo que ya existe, más Frecuentes y Sugeridos y las fotos de categorías. El pedido mínimo, la cotización por WhatsApp y la página "Nosotros" quedan fuera |
| Fuente | Poppins en títulos, botones y precios. Inter, la de hoy, en textos y tablas |
| Fotos grandes (portada, banda de promociones, encabezados) | Las manda el cliente, con derecho de uso. Mientras tanto, composición con la franja roja y el tenedor |
| Logo | Se trabaja con el JPG y se pide el original. Cuando llegue, se regenera todo con la misma herramienta |
| Identidad del logo | Nunca se recorta el tenedor ni las letras de "NEIL'S" |
| Ícono de la app (Android, web, favicon) | Tenedor y "NEIL'S", en blanco sobre rojo. Sin la línea "FOOD SERVICE'S", que no se lee a ese tamaño |
| Logo en barras, ingreso y portada | El completo, con "FOOD SERVICE'S" |
| Nombre en textos | Sigue siendo "Neil's Food Services" (pestaña del navegador, Android, avisos). El apóstrofo de "SERVICE'S" queda solo en el logo |
| Mensaje | Para negocios. Los textos nuevos están en [Textos](#textos-para-negocios) |
| Stock | No se muestra el total. Se avisa solo lo necesario: "Disponible", "Últimas 5", "Agotado" |

## Dos PR

1. **`feature/nueva-marca`** (desde `feature/codigos-promocionales`). Solo la app:
   - marca, tipografía y logo;
   - las piezas reutilizables;
   - todas las pantallas de la tienda y del panel con el estilo nuevo;
   - los textos para negocios.

   No cambia el servidor ni la base.
2. **`feature/frecuentes-y-categorias`** (desde `feature/nueva-marca`). Servidor y app:
   - Frecuentes y Sugeridos;
   - las fotos y descripciones de categorías;
   - la sección "Categorías" del panel.

   Trae una migración.

Así se revisan aparte el cambio visual, grande pero sin riesgo para los datos, y lo que toca la base.

## PR 1: la nueva marca

### Colores

Todo sale de `lib/theme/`, como hoy.

| Token | Color | Uso | Contraste |
|---|---|---|---|
| `primary` | `#C8281E` (rojo del logo) | Botones rellenos, enlaces, elemento activo, precios en oferta | Blanco encima: 5,6:1. Sobre el fondo: 5,2:1 |
| `primaryDark` | `#9E1B14` | Botón presionado, texto sobre el rojo claro | Sobre `primaryTint`: 6,5:1 |
| `primaryTint` | `#FBE3E0` | Fondo de lo seleccionado (menú del panel, chips, pestañas) | — |
| `background` | `#FBF7F2` (hueso) | Fondo de la app | — |
| `surface` | `#FFFFFF` | Tarjetas, con sombra cálida suave en lugar del borde | — |
| `ink` | `#1F1A17` | Texto | 16:1 sobre el fondo |
| `money` | `#276B43` sobre `moneyTint` `#E3F2E7` | Pastilla del total de cada línea, como en las maquetas | 5,5:1 |

- **Lo que se elimina:**
  - el naranja (`#E8652F`, `#B54F25`) y el crema (`#F9F3E7`);
  - el trazo de pincel (`SwooshPainter`, `swoosh.dart`), que era del logo viejo. Lo usan el titular de la portada y la línea bajo los precios.
- **Lo que lo reemplaza:** la **franja roja diagonal** de las maquetas, un `CustomClipper` que corta en diagonal la foto o el bloque de color.
- **Lo que no cambia:**
  - los colores de los estados de pedido (`OrderStatusColors`) y de estado (`StateColors`);
  - los pares de color de los productos y categorías sin foto (`PlaceholderColors`).
- **Ya no sirve:** el truco de usar `primaryDark` como `primary` porque el naranja no alcanzaba el contraste. Con el rojo, `primary` sirve para botones y para texto.
- **Un test** (`test/theme/brand_contrast_test.dart`) comprueba los contrastes de esta tabla. Si alguien cambia un color y baja de 4,5:1 en un texto, el test falla.

### Tipografía

- **Poppins** (600, 700 y 800): títulos (`display*`, `headline*`, `title*`), botones (`labelLarge`) y precios (`NeilsText.price`).
- **Inter** (400, 500 y 600): textos, etiquetas y tablas.
- **Empaquetadas en `assets/google_fonts/`** con su licencia OFL, como hoy: `google_fonts` las toma de ahí y no descarga nada al abrir la app.
- **Descarga:** los tres TTF de Poppins y su `OFL.txt` vienen de github.com/google/fonts, unos 150 KB cada uno. Antes de bajarlos se pide permiso.
- **Se eliminan** los archivos de Baloo 2.

### Logo e íconos

- **Original:** el JPG del cliente va a `apps/client/brand/logo.jpg`, fuera de `assets/`, así no viaja dentro de la app.
- **Generador:** `apps/client/tool/brand_assets_test.dart`. Se corre con `flutter test tool/brand_assets_test.dart` y usa `dart:ui`, sin paquetes nuevos. Escribe:

  | Archivo | Qué es |
  |---|---|
  | `assets/images/neils_logo.png` | El logo completo, rojo, sin el fondo blanco (el blanco pasa a transparencia) y recortado a su contenido |
  | `assets/images/neils_logo_white.png` | El mismo logo en blanco, para los fondos rojos |
  | `web/favicon.png` y `web/icons/Icon-192.png`, `Icon-512.png` | Ícono: tenedor y "NEIL'S" en blanco sobre `#C8281E` |
  | `web/icons/Icon-maskable-192.png`, `Icon-maskable-512.png` | El mismo, dentro de la zona segura del 80 % |
  | `android/.../mipmap-*/ic_launcher.png` | Los PNG de siempre, para Android 7 o anterior |
  | `android/.../mipmap-anydpi-v26/ic_launcher.xml` y su `ic_launcher_foreground` | Ícono adaptable (Android 8 o posterior): fondo rojo y el logo blanco en la zona segura del 66 % |

- **Cuando llegue el original** (SVG o PNG), se reemplaza `brand/logo.jpg` y se vuelve a correr el generador.
- **`web/manifest.json` e `index.html`:** `theme_color` pasa a `#C8281E` y `background_color` a `#FBF7F2`.
- **Pantalla de carga de Android:** fondo hueso. Desde Android 12, el sistema muestra ahí el ícono nuevo.
- **`NeilsLogo`:** pierde las esquinas redondeadas, que eran del logo viejo. Gana la variante `NeilsLogo.white()`. Su `semanticLabel` sigue siendo "Neil's Food Services".

### Fotos grandes

- **Mientras no lleguen las del cliente:**
  - **Portada y banda de promociones:** un bloque rojo con la franja diagonal y el tenedor del logo en blanco.
  - **Encabezado de una categoría:** su color de siempre con la franja.
- **Cuando lleguen,** se agregan a `assets/images/` y se activan en un solo lugar: `lib/theme/brand_images.dart`, con una constante por foto (`null` hasta que llegue).

### Piezas reutilizables nuevas

Van en `lib/features/shared/` o en la sección que las usa, y todas se ven en `/vitrina`.

| Pieza | Qué es |
|---|---|
| `DiagonalBand` | El corte diagonal rojo, sobre una foto o sobre un bloque de color |
| `BrandHero` | Título (con una parte en rojo), texto, acciones y la foto con `DiagonalBand`. En escritorio, dos columnas; en el teléfono, apilado y compacto |
| `TrustBadges` | Los tres sellos de la portada, con su ícono |
| `CategoryCard` | Foto arriba (o el color de la categoría con la inicial), nombre y flecha. En el PR 2 la foto viene del servidor |
| `CategoryHeader` | Encabezado del catálogo filtrado por una categoría: nombre, descripción (PR 2) y foto o color con la franja |
| `PromoRibbon` | La cinta roja en la esquina de un producto ("2×1", "16 + 2", "20 % menos"). Reemplaza las insignias de `offer_badges.dart` en las tarjetas |
| `ProductTile` | Producto en lista (teléfono). Ver el detalle abajo |
| `ProductCard` (renovada) | Lo mismo en tarjeta, para la cuadrícula de escritorio |
| `PriceText` | Precio unitario en tinta. En oferta, en rojo con el precio de lista tachado. Sin el trazo de pincel |
| `LineTotalPill` | El total de la línea en la pastilla verde |
| `StockNote` | "Disponible", "Últimas N" (N ≤ 5), "Agotado" |
| `CartBar` | Barra fija abajo (teléfono): ícono del carrito con el número de productos, "Continuar" y el total. En el carrito: "Confirmar pedido" |
| `StoreMenu` | El menú lateral de la tienda en el teléfono |
| `KpiCard` | Indicador del panel: ícono, título, número grande en rojo, detalle y una barra |

**`ProductTile`**, de izquierda a derecha:
- la foto (o su marcador);
- el código (SKU) y el nombre, en una línea con guion ("3580 – Jamonada especial");
- `PriceText` y `StockNote`;
- debajo, los botones − / + , `LineTotalPill` con lo que costarían esas unidades, y "Agregar". Si el producto ya está en el carrito, el botón es "Editar" y la cantidad muestra la del carrito;
- `PromoRibbon` en la esquina, si tiene una promoción.

### Textos para negocios

| Dónde | Texto nuevo |
|---|---|
| Portada, titular | "Tu negocio siempre abastecido con Neil's." ("con Neil's." en rojo) |
| Portada, texto | "Insumos gastronómicos de calidad, con precios competitivos y entrega confiable." |
| Portada, botones | "Ver catálogo" y "Ver promociones" |
| Sellos | "Entrega confiable", "Calidad garantizada", "Atención personalizada" |
| Banda de promociones | "Promociones para tu negocio" y "Soluciones prácticas para restaurantes, fast foods y dark kitchens." con "Ver promociones" |
| Saludo (teléfono) | "¡Hola, Nombre!" (sin cuenta, "¡Hola!") y "Abastece tu negocio con los mejores productos." |
| Ingreso, panel rojo | "Tu abastecimiento gastronómico, más fácil." con tres beneficios: "Precios y promociones exclusivas", "Entrega a tu negocio" y "Sigue tus pedidos". Reemplaza a "Tus abarrotes, a la puerta de tu casa" |
| `web/index.html` (descripción) | "Insumos gastronómicos para tu negocio: el catálogo, las promociones y tus pedidos de Neil's Food Services." |

**Los términos y la política** (`legal_texts.dart`) no se tocan: tienen versión, y cambiarlos obliga a todos los clientes a aceptarlos de nuevo. Si el cliente quiere actualizarlos al nuevo público, es un cambio aparte.

### La tienda

**Barra superior**
- **Escritorio (≥ 840 px):**
  - a la izquierda, el logo;
  - después, Inicio, Catálogo y Promociones, con la activa subrayada en rojo;
  - un buscador redondo, que lleva al catálogo con lo buscado;
  - Mis pedidos, la cuenta (nombre y menú) y el carrito.
- **Teléfono:** a la izquierda el menú (`StoreMenu`: Inicio, Catálogo, Promociones, Mis pedidos, Mi cuenta, el panel si es del personal, e Ingresar o Salir); al centro el logo; a la derecha el carrito.

**Promociones:** lleva a `/catalogo?promos=1`, el catálogo con los productos en promoción (el `onSale` que el servidor ya tiene). Suma el chip "En promoción" junto a las categorías.

**Portada**
- **Escritorio:**
  - `BrandHero` y `TrustBadges`;
  - "Nuestras categorías" con `CategoryCard`;
  - la banda de promociones;
  - "Promociones de hoy", que en el PR 2 pasa a ser las pestañas Frecuentes · Sugeridos · Promos.
- **Teléfono:**
  - el saludo con su foto o bloque rojo;
  - el buscador;
  - las pestañas (en el PR 1, solo Promos) con `ProductTile`;
  - las categorías en una fila que se desliza.
- **Con productos en el carrito,** la `CartBar`.

**Catálogo**
- buscador redondo y chips (Todas, En promoción y las categorías);
- con una categoría elegida, arriba su `CategoryHeader`;
- teléfono: lista de `ProductTile`; escritorio: cuadrícula de `ProductCard`.

**Detalle del producto**
- foto grande, con `PromoRibbon`;
- código y nombre;
- `PriceText` y `StockNote`;
- botones − / + , `LineTotalPill` y "Agregar" o "Editar";
- después, "Más de <categoría>", como hoy.

**Carrito**
- las líneas con el estilo de `ProductTile`;
- los avisos y los regalos de la cotización, como hoy, en tarjetas nuevas;
- la `CartBar` con "Confirmar pedido". No cambia cómo se confirma.

**Ingresar y Crear cuenta**
- **Escritorio:** dos columnas. A la izquierda, el panel rojo con `NeilsLogo.white()`, el lema y los tres beneficios. A la derecha, el formulario.
- **Teléfono:** una franja roja con el logo blanco, y debajo el formulario.
- **Los campos** llevan su ícono (persona, correo, candado), como en las maquetas. No cambia qué se pide ni cómo se valida.

**Mis pedidos, Mi cuenta, Mis códigos, seguimiento y "Ofertas exclusivas":** no cambia su estructura. Toman colores, fuente, tarjetas, chips y botones nuevos.

**Stock:** en ninguna pantalla de la tienda aparece el número de unidades, salvo "Últimas N" con 5 o menos. El JSON público sigue mandando `currentStock`: la app lo necesita para no pasar del máximo. Si el cliente quiere sacarlo también del JSON, es un cambio aparte del servidor.

### El panel

**Barra superior:** blanca, con el logo, "Ir a la tienda", "Mis pedidos" y el usuario con "Salir".

**Menú**
- **≥ 1200 px:** lateral ancho, con ícono y texto. El elemento activo va con fondo `primaryTint` y texto `primaryDark`, como "Tienda" en la maqueta.
- **840 a 1200 px:** el menú angosto de hoy, con los colores nuevos.
- **Teléfono:** la barra de abajo de hoy.

**Inicio**
- arriba, "Buenos días", "Buenas tardes" o "Buenas noches", según la hora de Lima, con el nombre y la fecha ("Miércoles, 5 de noviembre");
- las cuatro cifras de ventas, con `KpiCard`;
- el resto, como hoy, con las tarjetas y colores nuevos.

**Formularios** (productos, promociones, códigos, tienda, equipo, roles): campos con borde e ícono cuando ayuda, y el botón principal rojo abajo a la derecha, como "Guardar cambios".

**Tablas:** encabezado sobre hueso, filas blancas y el texto secundario en gris cálido.

### Pruebas del PR 1

- **Los tests de la app que hoy buscan textos o colores** se actualizan a los nuevos ("Ver catálogo", el titular, los botones).
- **Tests nuevos:**
  - de cada pieza nueva (`ProductTile` con y sin carrito, "Editar", `StockNote`, `PromoRibbon`, `CartBar` visible solo con productos, `StoreMenu`);
  - del filtro `promos=1`;
  - del contraste de los tokens.
- **Capturas temporales** (goldens) de cada pantalla, en teléfono (390 × 844) y escritorio (1280 × 800). Se revisan con el cliente y van a `capturas/nueva-marca/`.
- **`flutter analyze`** sin problemas y la suite completa en verde.

## PR 2: Frecuentes, Sugeridos y fotos de categorías

### Frecuentes y Sugeridos (servidor)

Las dos rutas van en el dominio `products/`, junto a `/products`: devuelven el mismo JSON, con los precios y promociones de quien mira. El orden lo calcula una consulta sobre `order_items` y `orders`, como la de los más vendidos de `stats/`.

**`GET /products/frequent`** (`signedIn`: 401 sin cuenta)
- **Qué trae:** los productos de las líneas de los pedidos del cliente de los últimos 180 días, en cualquier estado salvo `cancelled`.
- **Sin:** los regalos (`isGift`) ni los productos dados de baja.
- **Orden:** primero el que aparece en más pedidos; si empatan, el pedido más reciente; si sigue el empate, el nombre.
- **Límite:** 20.

**`GET /products/suggested`** (pública; con token, usa las promociones del cliente)
- **Qué trae:** los productos más vendidos en unidades en los últimos 30 días, en pedidos no cancelados.
- **Sin:** los regalos, los dados de baja ni los agotados.
- **Con cuenta:** sin los que ya salen en sus Frecuentes.
- **Orden:** unidades, y después el nombre.
- **Límite:** 20.

Cada ruta suma su fila en `test/unit/auth/route_permissions_test.dart`.

**Tests de integración:**
- el orden;
- que no salen los cancelados ni los regalos;
- la ventana de días;
- que no se mezclan los pedidos de otro cliente;
- que Sugeridos no repite los Frecuentes;
- que un agotado no sale en Sugeridos;
- 401 sin cuenta en Frecuentes;
- el precio con la promoción del cliente.

### Frecuentes y Sugeridos (app)

- **Pestañas en la portada:** Frecuentes · Sugeridos · Promos, en el teléfono y en escritorio.
- **Pestaña inicial:** Frecuentes si el cliente tiene alguno; si no, Sugeridos.
- **Sin cuenta:** no hay Frecuentes.
- **Frecuentes vacía** (cliente sin pedidos): "Cuando hagas tu primer pedido, aquí verás lo que más pides."
- **Datos:** repositorio con interfaz (`CatalogRepository` suma `frequent()` y `suggested()`), providers con `autoDispose`, y versiones en memoria en `test/fakes.dart`.

### Fotos y descripción de categorías (servidor)

- **Modelo:** `Category` suma `imageUrl: String?` y `description: String?` (hasta 80 caracteres). Migración `fotos-de-categorias`.
- **Procesar fotos:** el código que hoy procesa y guarda las fotos de productos (`products/product_images.dart`) se separa. Lo genérico (validar, JPEG, nombre al azar, almacenamiento `public`) pasa a `common/photos.dart`, así lo usan los dos dominios sin importarse entre sí. Cada dominio fija su prefijo de URL y su tamaño: productos 800 px, como hoy; categorías 1200 px, porque se ven anchas.
- **Rutas:**
  - `PUT /categories/:id/image` (`categories.manage`): la foto tal cual, como la de productos;
  - `GET /images/categories/:categoryId/:file`: pública, con caché para siempre;
  - `POST` y `PATCH /categories` aceptan `description`;
  - el JSON de la categoría suma `imageUrl` y `description`.
- **Tests:** subir, reemplazar, servir, rechazar lo que no es imagen, el permiso y la descripción (largo y vacía).

### Categorías en el panel (app)

- **Sección nueva "Categorías"** (`/admin/categorias`, con `categories.manage`), en el menú después de Productos.
- **Lista:** foto, nombre, descripción y cantidad de productos.
- **Formulario:** nombre, descripción y foto (con `image_picker`, como en productos).
- **Borrar:** pide confirmar. Si la categoría tiene productos, muestra el 409 del servidor.
- **En la tienda:** `CategoryCard` y `CategoryHeader` usan la foto y la descripción. Sin foto, el color de siempre.

### Pruebas del PR 2

- **Servidor:** `dart analyze --fatal-infos` y `dart test` completo.
- **App:** la sección "Categorías", las pestañas y los repositorios.
- **Migración:** se aplica en la base de desarrollo y se revisa con psql.
- **Seed:** suma descripciones a las categorías de ejemplo.
- **Capturas** de la portada con las pestañas y de la sección "Categorías".

## Documentación

En el mismo PR que la cambia:
- **`apps/client/README.md`:** tema, fuentes, logo y su generador, fotos provisionales.
- **`apps/server/README.md`:** las rutas nuevas.
- **`docs/ARQUITECTURA_Y_ROADMAP.md`:** marca, Frecuentes y Sugeridos, categorías.
- **`docs/DEMO.md`:** el recorrido con la portada nueva.

## Fuera de este cambio

- El pedido mínimo con su barra de avance.
- "Solicitar cotización" por WhatsApp y la página "Nosotros".
- La presentación del producto ("Caja × 90"): el modelo no la guarda.
- La cuota, la cobertura y las tendencias (flechas de %) de la maqueta del vendedor.
- Los términos y la política para el nuevo público.
- Sacar `currentStock` del JSON público.
- Un modo oscuro (la app sigue siempre clara).

## Pendiente del cliente

- El logo original en SVG o en PNG transparente.
- Las fotos grandes con derecho de uso:
  - portada (horizontal, al menos 1600 px);
  - banda de promociones;
  - una por categoría (se suben desde el panel en el PR 2).

## Riesgos

- **Muchos tests de widgets buscan textos de la portada y del ingreso.** Se actualizan en el mismo commit que cambia cada pantalla.
- **El logo desde un JPG:** los bordes del rojo sobre blanco dejan un halo al quitar el fondo. El generador convierte la claridad de cada píxel en transparencia, en vez de cortar por un umbral, y se revisa la captura sobre el rojo y sobre el hueso.
- **`flutter_tester` se cae al azar** en suites largas. Se corre con el script de reintentos de siempre.
