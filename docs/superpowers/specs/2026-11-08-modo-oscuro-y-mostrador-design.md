# Modo oscuro y rediseño "Mostrador de abasto": especificación

## Qué se busca

El cliente pidió tres cosas para la app (Android y web):

1. Un **modo oscuro** que se pueda elegir.
2. Que la interfaz **no se vea genérica ni monótona**.
3. **Animaciones chicas** donde aporten.

La dirección se eligió entre cuatro opciones, revisadas con la skill Taste y con una segunda opinión de
Codex: **Mostrador de abasto**. La compra de un negocio es reponer, seguido y rápido, así que la portada
pone primero el buscador y lo habitual en filas, con la cantidad a mano. Suma tres piezas de la marca:

- la diagonal del logo en la portada de la web;
- una franja roja para la campaña;
- la etiqueta de mercado en las promociones.

Las maquetas de todas las pantallas, en claro y oscuro, están en el lienzo
[Neil's: rediseño Mostrador de abasto](https://claude.ai/artifact/TmaNsJqzAFswZSmK6wLHUL). Son la
referencia visual de esta spec; cuando no coincidan, manda esta spec.

## Decisiones

| Tema | Decisión |
|---|---|
| Elección del modo | Sistema (por defecto), Claro u Oscuro, guardada en el dispositivo |
| Dónde se elige | El menú lateral del teléfono, un botón "Apariencia" en la barra de escritorio de la tienda y en la del panel |
| Alcance del rediseño | La tienda completa. El panel solo gana el modo oscuro y bordes en lugar de sombras |
| Fondos | Planos: sin patrón, textura ni degradé |
| Superficies | Bordes finos cálidos; sin sombra en las tarjetas |
| La diagonal | Solo en el encabezado de la portada (web) y en el panel rojo de ingreso |
| Promociones | Etiqueta de mercado recta (borde punteado rojo) junto al nombre; reemplaza la cinta de la esquina |
| Fotos | Las del cliente. Mientras faltan, el color de la categoría o un marcador neutro. Las fotos suplentes con licencia quedan para un paso aparte |
| Entrega | Dos PR encadenados sobre el #14: primero el modo oscuro, después el rediseño |

## PR 1: modo oscuro (`feature/modo-oscuro`)

En claro, la app se ve **igual que hoy**, salvo el par lavanda de las categorías sin foto, que se
reemplaza. Este PR solo agrega el oscuro y mueve los colores al tema.

### La preferencia

- `ThemePreference` (`system`, `light`, `dark`) en `lib/appearance/`:
  - `AppearanceRepository`: la interfaz;
  - `PrefsAppearanceRepository`: SharedPreferences en Android y localStorage en la web, con la clave
    `appearance`;
  - `MemoryAppearanceRepository`: la de los tests.
- `appearanceProvider` (Notifier): lee la preferencia al arrancar y la guarda al cambiarla.
- Un valor guardado que no se reconoce cuenta como `system`.
- `main.dart` usa la misma instancia de SharedPreferences que el carrito.
- `NeilsApp` pasa `theme`, `darkTheme` y `themeMode`. El cambio se ve con la transición propia de
  `MaterialApp` (unos 200 ms).

### La paleta

- `NeilsPalette`, una `ThemeExtension` en `lib/theme/palette.dart`, con dos instancias: `light` y `dark`.
  Un getter `context.palette` la lee del tema.
- **Roles:**
  - `background`, `surface`, `surfaceAlt`, `line`;
  - `ink`, `inkMuted`;
  - `brandFill`, `onBrand`, `brandText`, `brandTint`, `onBrandDivider`;
  - `money`, `moneyTint`;
  - los siete estados de pedido;
  - `positive` y `caution`;
  - los pares de las categorías sin foto;
  - `scrim`.
- **Valores del claro:** los de hoy.
- **Valores del oscuro:**

| Rol | Oscuro |
|---|---|
| background / surface / surfaceAlt / line | `#171513` / `#24201C` / `#302A25` / `#3A322C` |
| ink / inkMuted | `#F4EEE7` / `#B9ADA3` |
| brandFill / onBrand | `#C8281E` / `#FFFFFF` |
| brandText / brandTint | `#FF9A8F` / `#4A1E1A` |
| money / moneyTint | `#A9E2B8` / `#183B28` |
| Estados (pendiente, confirmado, preparando, listo, en camino, entregado, cancelado) | `#E3B261`, `#A9B1F0`, `#C6A8E8`, `#7FD3C8`, `#8CBDE6`, `#8FD1AE`, `#F0A49B` |

- **Los pares de las categorías sin foto,** en oscuro: un fondo apagado del mismo tono con la letra
  clara (contraste de 4,5:1 o más).
- **Los colores de estado conservan sus tonos,** incluido el violeta de "preparando": codifican un
  estado (siempre junto a su texto), no decoran. La regla de "nada violeta" de Taste es para el acento
  y los fondos de la marca.
- **Sale el par lavanda:** en los dos modos lo reemplaza "arcilla" (`#F1DDCF` / `#6B3A22` en claro).
- `neilsTheme(Brightness)` y `neilsAdminTheme` arman el `ColorScheme` desde la paleta. En oscuro, el
  `primary` del esquema es `brandText` (`#FF9A8F`), con `onPrimary` oscuro. Los botones rellenos fijan
  su fondo en `brandFill`, con texto blanco.

### La migración

- Los 100 usos directos de `NeilsColors`, `OrderStatusColors`, `StateColors`, `PlaceholderColors` y
  `neilsCardShadow`, en 35 archivos, pasan a `context.palette` o a `Theme.of(context).colorScheme`.
- Las constantes quedan solo dentro de `lib/theme/`, para armar las paletas.
- `no_loose_colors_test` suma esas clases: fuera de `lib/theme/` no puede aparecer ninguna.

### Dónde se elige

- `AppearanceSelector`, un `SegmentedButton` de tres opciones con su ícono: Sistema, Claro y Oscuro.
  Va en el menú lateral de la tienda (`StoreMenu`), debajo de las secciones.
- `AppearanceButton`, un botón de ícono con un menú de las mismas tres opciones.
  - Va en la barra de escritorio de la tienda (`PublicScaffold`) y en la barra del panel (`AdminShell`).
  - El ícono muestra el modo activo.

### Arranque sin destello

- **La web:**
  - `index.html` pinta el fondo de la página con `prefers-color-scheme`: `#FBF7F2` en claro y
    `#171513` en oscuro;
  - lleva dos `theme-color`, uno por modo.
- **Android:**
  - `values-night/colors.xml` define `launch_background` `#171513`;
  - el tema de arranque oscuro usa ese color.

### Tests

- **El repositorio:** guarda y lee los tres valores, y un valor desconocido cuenta como `system`.
- **El provider:** cambiar la preferencia la guarda y cambia el `themeMode` de la app.
- **Los contrastes de las dos paletas** (`theme_test`):
  - texto e inkMuted sobre background, surface y surfaceAlt: 4,5:1;
  - brandText sobre background y surface: 4,5:1;
  - onBrand sobre brandFill: 4,5:1;
  - money sobre moneyTint: 4,5:1;
  - cada estado sobre surface: 3:1, porque va siempre con su texto;
  - cada par de categoría: 4,5:1.
- **Las pantallas en oscuro sin errores ni desbordes:** portada, catálogo, producto, carrito, Mis
  pedidos, ingreso e inicio del panel.
- **`AppearanceSelector` y `AppearanceButton`:** muestran la opción activa y la cambian.
- **La suite completa,** sin cambios visibles en claro.

## PR 2: Mostrador de abasto (`feature/mostrador-de-abasto`)

### Tokens del claro

- **Colores nuevos:**
  - background `#FAF8F5`, surface `#FFFFFF`, surfaceAlt `#F0ECE6`, line `#E3DCD4`;
  - ink `#211B17`, inkMuted `#655A52`;
  - brandText `#A61F18`;
  - money `#205B38` sobre moneyTint `#E1F2E7`.
- **Formas:**
  - radios: 12 en tarjetas y paneles, 10 en botones y campos;
  - las tarjetas sin sombra y con borde `line`, en la tienda y en el panel.

### Piezas

- **`ProductRow`** (la lista del teléfono) reemplaza el aspecto de `ProductTile`:
  - filas en un bloque `surface` separadas por líneas finas, sin tarjeta por producto;
  - la foto de 64 px, el código y el nombre, y debajo la etiqueta de promoción o la disponibilidad;
    el precio a la derecha;
  - en la segunda línea, `ProductQuantityActions` (la cantidad, la pastilla del total y
    Agregar/Editar), que se conserva.
- **`ProductCard`** (la cuadrícula de escritorio):
  - con borde y sin sombra; la foto 4:3 arriba;
  - el nombre (2 líneas), la etiqueta o la disponibilidad, el precio, la cantidad y Agregar.
- **`PromoTag`**, la etiqueta de mercado:
  - recta, con borde punteado `brandFill` y texto `brandText`;
  - muestra "2x1", "3x2", "2.ª al 50 %", "+ regalo" o "Regalo";
  - reemplaza a `PromoRibbon` en la lista, la tarjeta, el detalle y el carrito;
  - el lector dice la descripción de la promoción.
- **`CampaignBand`**, la franja roja de campaña:
  - el título es la descripción de la primera promoción por cantidad del día (por ejemplo, "3x2 en
    Jamonada especial"). Si no hay ninguna, dice "Promociones para tu negocio";
  - el subtítulo dice cuántos productos están en promoción hoy;
  - lleva un enlace "Ver promociones";
  - reemplaza a `PromotionsBanner`. Sale de los datos que ya hay (`onSaleProductsProvider`): sin
    servidor nuevo.
- **`CartTicket`**, el resumen del carrito:
  - el borde de arriba perforado (un `CustomClipper`);
  - Subtotal, Descuentos y "Total estimado", con la nota del precio final;
  - solo en el carrito.

### Pantallas

- **Portada, teléfono:**
  - el saludo corto ("Buenos días, Ana", con `greetingFor`), el buscador y las pestañas;
  - el título según la pestaña: "Reposición habitual", "Lo más pedido" o "Promociones de hoy";
  - las filas, la `CampaignBand` y las categorías en una fila que se desliza.
- **Portada, escritorio:**
  - a la izquierda, el titular "Insumos para restaurantes y cafeterías" y una línea sobre lo que se
    vende;
  - el dato de la tienda, "Atendemos …", con `openingHours` de `GET /store`. Si viene vacío, la línea
    no aparece;
  - "Ver catálogo" y "Ver promociones";
  - a la derecha, `BrandImages.hero` (o el bloque rojo con el logo en blanco, como hoy) recortado en
    diagonal;
  - debajo, las pestañas con las tarjetas, la `CampaignBand`, las categorías y un pie con el nombre, la
    dirección de la tienda y los enlaces.
- **Catálogo:**
  - en el teléfono, las categorías en una sola fila que se desliza;
  - en escritorio, en varias líneas;
  - `CategoryHeader` sobre `surfaceAlt`, con la foto en diagonal.
- **Producto:**
  - en el teléfono, la foto a todo el ancho con Volver y el carrito flotando encima;
  - en escritorio, dos columnas con la ruta "Catálogo › categoría";
  - la explicación de la promoción va en un recuadro `surfaceAlt`.
- **Carrito:**
  - las líneas en filas;
  - el tipo de entrega en un control segmentado;
  - el `CartTicket`;
  - en escritorio, dos columnas: las líneas y, al lado, la entrega, el código, el ticket y "Confirmar
    pedido".
- **Mis pedidos:** el pedido en curso con la línea de seguimiento y el código de entrega en
  `surfaceAlt`. Desde 1100 px, la lista y el pedido elegido van lado a lado.
- **Ingreso y registro:** el panel rojo con la diagonal y el logo blanco, como hoy, con los nuevos
  tokens.
- **Las categorías sin foto:** el bloque de color de la categoría (sin la inicial gigante) con el nombre
  debajo.
- **El panel:** sin cambios de contenido; los tokens nuevos, bordes en lugar de sombras y el menú
  lateral sobre `surfaceAlt`.

### Movimiento

Todo respeta "reducir animaciones": con esa opción, cada cosa aparece en su estado final.

- **Presionar:** escala 0,985, 90 ms (`NeilsMotion.press`).
- **La cantidad, la pastilla y el total de la barra:** un fundido de 160 ms (`AnimatedSwitcher`).
- **Al pasar el mouse** (solo con puntero fino, en la web):
  - la tarjeta con enlace sube 2 px, 180 ms;
  - la foto se acerca a 1,03 dentro de su marco, 600 ms.
- **La entrada de la portada,** una vez por sesión:
  - el titular sube 12 px desde transparente, 600 ms, `Curves.easeOutCubic`;
  - la foto se asienta de 1,03 a 1.
- **La foto del producto** viaja de la fila o la tarjeta al detalle (`Hero`).
- **Lo que sale o cambia:**
  - sale el rebote del carrito (`NeilsMotion.bump`): el número del ícono cambia con el mismo fundido;
  - la entrada del precio VIP empieza en 0,97 en lugar de 0,9.
- **Nada aparece al hacer scroll.** No hay rebotes ni sobrepasos: la curva es
  `Cubic(.2, .8, .2, 1)` y nunca pasa de su valor final.

### Tests

- **Cada pieza nueva**, en claro y oscuro:
  - `ProductRow`, `PromoTag`, `CampaignBand`, `CartTicket` y la tarjeta;
  - a 320 y 390 px y con el texto al 130 %, sin desbordes.
- **El movimiento:**
  - con "reducir animaciones", la portada muestra el titular sin esperar;
  - el número del carrito cambia sin el rebote.
- **Las pantallas:** los tests actuales se adaptan a las piezas nuevas sin perder casos.
- **Las capturas** (goldens locales, fuera del repo) de todas las pantallas en claro y oscuro, para
  revisar contra el lienzo.

## Fuera de alcance

- "Repetir pedido" y escanear códigos.
- Las fotos suplentes con licencia: hacen falta tu permiso para descargarlas y el aviso de licencia.
- Contenido nuevo en el panel.
- Cambios en el servidor.

## Riesgos

- **La migración de colores toca 35 archivos.** Hay que hacerla por piezas, con la suite en verde
  después de cada tanda. El test de colores sueltos avisa si queda alguno.
- **El rojo de la marca sobre el oscuro no llega al contraste de un texto.** Por eso los textos rojos usan
  `brandText` y los botones `brandFill`. Un widget que tome `primary` como fondo de botón en oscuro
  quedaría con fondo salmón: los botones rellenos fijan su color en el tema.
- **La entrada de la portada** no puede demorar la compra: dura 600 ms, una vez por sesión, y el
  buscador funciona desde el primer cuadro.
