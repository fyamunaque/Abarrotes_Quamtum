# Modo oscuro y "Mostrador de abasto": plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** agregar a la app un modo oscuro elegible (Sistema, Claro u Oscuro) y rediseñar la tienda con la dirección "Mostrador de abasto", con animaciones cortas.

**Architecture:** los colores dejan de ser constantes en las pantallas y pasan a una `ThemeExtension` (`NeilsPalette`) con una instancia clara y otra oscura. La preferencia se guarda detrás de un repositorio con su provider, y `MaterialApp` recibe `theme`, `darkTheme` y `themeMode`. El rediseño cambia piezas (fila de producto, tarjeta, etiqueta de promoción, franja de campaña, ticket) y pantallas, sin tocar el servidor.

**Tech Stack:** Flutter 3 (Material 3), Riverpod 3, go_router, shared_preferences, google_fonts (empaquetadas).

**Spec:** `docs/superpowers/specs/2026-11-08-modo-oscuro-y-mostrador-design.md`. Las maquetas: el lienzo
[Neil's: rediseño Mostrador de abasto](https://claude.ai/artifact/TmaNsJqzAFswZSmK6wLHUL).

## Global Constraints

- Todo en `apps/client`. Sin cambios en el servidor ni paquetes nuevos.
- Colores y tipografía solo desde `lib/theme/`. Fuera de esa carpeta no se usan `Colors.*` (salvo
  `Colors.transparent`), `Color(0x…)`, `NeilsColors`, `OrderStatusColors`, `StateColors`,
  `PlaceholderColors` ni `neilsCardShadow`.
- Contraste: 4,5:1 para el texto y 3:1 para los puntos de estado, que van siempre con su texto.
- Áreas táctiles de 48 dp como mínimo. Nada se desborda a 320 px ni con el texto al 130 %.
- Todo movimiento respeta `NeilsMotion.reduced(context)`: con esa opción, cada cosa aparece en su estado
  final.
- Curva `Cubic(.2, .8, .2, 1)`, sin rebotes ni sobrepasos. Nada aparece al hacer scroll.
- Textos de interfaz en español y en tono de frase. Los datos que faltan nunca se inventan.
- Firebase, HTTP y el almacenamiento local, solo detrás de repositorios con sus providers.
- Commits en Conventional Commits, en español, terminados en
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Un commit por cambio lógico.
- **Ramas:**
  - PR 1, `feature/modo-oscuro`, sale de `feature/frecuentes-y-categorias`;
  - PR 2, `feature/mostrador-de-abasto`, sale de `feature/modo-oscuro`.
  - Sin push ni PR hasta que se pidan. `AGENTS.md`, en la raíz, no es nuestro: no se toca ni se
    comitea.
- **Tests:**
  - los de un archivo, con `node <scratchpad>/run-each2.js . <archivos>` desde `apps/client`, el
    script que reintenta las caídas de flutter_tester;
  - el análisis, con `flutter analyze lib test tool`.

## Review Focus

1. **Un botón que tome `primary` de fondo en oscuro quedaría salmón (`#FF9A8F`).** Los tests de tema
   comprueban en oscuro el fondo de FilledButton y de la barra del carrito (`#C8281E`) y su texto
   (`#FFFFFF`). Va en el Task 2 y el Task 6.
2. **La preferencia guardada se aplica desde el primer cuadro,** sin pasar por claro: el repositorio
   lee de forma síncrona y el provider arranca con ese valor. Test en el Task 3.
3. **Las piezas nuevas** (fila, tarjeta, etiqueta, franja, ticket) a 320 px y con el texto al 130 %: tests
   en los Tasks 12 a 15 y 19.
4. **"Reducir animaciones":** la entrada de la portada y el hover no ocultan nada. Tests en los Tasks
   11, 14 y 16.
5. **Los pares de categoría y los colores de estado en oscuro:** contraste medido par por par. Tests en
   el Task 1.

---

## PR 1: modo oscuro (`feature/modo-oscuro`)

### Task 1: La paleta

**Files:**
- Create: `lib/theme/palette.dart`
- Modify: `lib/theme/brand_colors.dart`. En `PlaceholderColors.pairs`, el par lavanda pasa a arcilla:
  `(Color(0xFFF1DDCF), Color(0xFF6B3A22))`.
- Test: `test/theme/theme_test.dart`

**Interfaces:**
- Produces:
  - `class NeilsPalette extends ThemeExtension<NeilsPalette>`, con estos campos `Color`:
    - superficies: `background`, `surface`, `surfaceAlt`, `line`;
    - texto: `ink`, `inkMuted`;
    - marca: `brandFill`, `onBrand`, `brandText`, `brandTint`, `onBrandDivider`;
    - total: `money`, `moneyTint`;
    - estados de pedido: `statusPending`, `statusConfirmed`, `statusPreparing`, `statusReady`,
      `statusOnTheWay`, `statusDelivered`, `statusCancelled`;
    - otros estados: `positive`, `caution`;
    - `scrim`.
  - Además, `List<(Color, Color)> placeholderPairs`, más `copyWith` y `lerp`.
  - `(Color, Color) placeholderFor(String key)`, con el mismo hash que `PlaceholderColors.of`.
  - `static const light` (los valores de hoy) y `static const dark` (los de la spec).
  - `extension NeilsPaletteContext on BuildContext { NeilsPalette get palette; }`. Si la extensión falta
    en el tema, usa `NeilsPalette.light`.

- [ ] **Step 1:** en `theme_test.dart`, un `group('paletas', ...)` con estos tests:
  - `'los textos del claro y del oscuro pasan 4,5:1'`: para cada paleta, `ink` e `inkMuted` sobre
    `background`, `surface` y `surfaceAlt`; `brandText` sobre `background` y `surface`; `onBrand` sobre
    `brandFill`; `money` sobre `moneyTint`.
  - `'cada estado pasa 3:1 sobre surface'`, en las dos paletas.
  - `'cada par de categoría pasa 4,5:1'`, en las dos paletas.
  - `'sin lavanda'`: ningún fondo de los pares claros es `#E4DCF0`.
  - `'el oscuro es el de la spec'`: background `#171513`, surface `#24201C`, brandFill `#C8281E` y
    brandText `#FF9A8F`.
- [ ] **Step 2:** correr `theme_test.dart`. Esperado: no compila, porque falta `NeilsPalette`.
- [ ] **Step 3:** escribir `palette.dart` con los valores de la spec.
  - El claro toma los de hoy:
    - background `NeilsColors.background`, surface `NeilsColors.surface`;
    - surfaceAlt `#F3ECE4` (el `surfaceContainer` actual), line `#E5DCD3`;
    - ink `NeilsColors.ink`, inkMuted `#5E534D`;
    - brandText `NeilsColors.primary`, brandTint `NeilsColors.primaryTint`.
  - Los pares oscuros son los mismos tonos apagados, con la letra clara.
  - Cambiar el par lavanda en `brand_colors.dart`.
- [ ] **Step 4:** correr `theme_test.dart`. Esperado: todo pasa. Si un par no llega a 4,5:1, ajustar el
  valor dentro del mismo tono y anotar la decisión en el registro.
- [ ] **Step 5:** commit `feat(client): la paleta de colores clara y oscura`.

### Task 2: Los temas claro y oscuro

**Files:**
- Modify: `lib/theme/neils_theme.dart`
- Test: `test/theme/theme_test.dart`

**Interfaces:**
- Consumes: `NeilsPalette` (Task 1).
- Produces:
  - `ThemeData neilsTheme([Brightness brightness = Brightness.light])`: el `ColorScheme` sale de la
    paleta y `extensions: [palette]`;
  - en oscuro, el esquema usa `primary` = `brandText`, `onPrimary` `#3B0B07`, `surface` = `background`;
  - `filledButtonTheme` fija `backgroundColor` = `brandFill` y `foregroundColor` = `onBrand`, en los dos
    modos;
  - `neilsTextTheme(Color ink)` recibe el color del texto;
  - `neilsAdminTheme(ThemeData base)` toma los colores de `base.extension<NeilsPalette>()`.

- [ ] **Step 1:** tests nuevos:
  - `'el tema oscuro: fondo, texto y extensión'`: `neilsTheme(Brightness.dark).scaffoldBackgroundColor`
    es `#171513`, `extension<NeilsPalette>()` es `NeilsPalette.dark` y `textTheme.bodyMedium.color` es
    `#F4EEE7`;
  - `'el botón relleno es rojo con texto blanco en los dos modos'`: se arma un `FilledButton` con cada
    tema y se mira el `Material` de adentro: color `#C8281E`, texto `#FFFFFF`;
  - `'el claro no cambia'`: los valores que ya comprueba `theme_test` siguen igual.
- [ ] **Step 2:** correrlos. Esperado: fallan, porque `neilsTheme` no recibe el brillo.
- [ ] **Step 3:** implementar. Los llamados actuales a `neilsTheme()` siguen funcionando (el brillo es
  opcional).
- [ ] **Step 4:** correr `test/theme` y `test/admin/admin_home_test.dart`. Esperado: verde.
- [ ] **Step 5:** commit `feat(client): el tema oscuro`.

### Task 3: La preferencia de apariencia

**Files:**
- Create: `lib/appearance/appearance.dart`, `lib/appearance/appearance_repository.dart`,
  `lib/appearance/appearance_providers.dart`
- Modify: `lib/main.dart`, `lib/app.dart`
- Test: `test/appearance/appearance_test.dart`. En `test/fakes.dart`, nada: el repositorio en memoria vive
  en `lib/`, como `MemoryCartStorage`.

**Interfaces:**
- Produces:
  - `enum ThemePreference { system, light, dark }` con `ThemeMode get themeMode`;
  - `abstract interface class AppearanceRepository { ThemePreference read(); Future<void> write(ThemePreference value); }`
    (la lectura es síncrona);
  - `PrefsAppearanceRepository(SharedPreferences)`, con la clave `appearance` y el valor por su `name`;
  - `MemoryAppearanceRepository([ThemePreference initial = ThemePreference.system])`;
  - `appearanceRepositoryProvider`: en el arranque se reemplaza (como `cartStorageProvider`); por
    defecto, uno en memoria;
  - `appearanceProvider = NotifierProvider<AppearanceNotifier, ThemePreference>`, con
    `Future<void> set(ThemePreference)`;
  - `NeilsApp` pasa `theme: neilsTheme()`, `darkTheme: neilsTheme(Brightness.dark)` y
    `themeMode: ref.watch(appearanceProvider).themeMode`.

- [ ] **Step 1:** los tests:
  - `'guarda y lee los tres valores'`, con SharedPreferences de prueba (`SharedPreferences.setMockInitialValues`);
  - `'un valor desconocido cuenta como sistema'`;
  - `'set guarda la preferencia'`;
  - `'la app arranca en oscuro si estaba guardado'`: se arma `NeilsApp` con el repositorio en `dark`; en
    el primer `pump`, `Theme.of(...).brightness` es `dark`;
  - `'en sistema sigue al brillo del dispositivo'`, con `tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark`.
- [ ] **Step 2:** correrlos. Esperado: no compila.
- [ ] **Step 3:** implementar. `main.dart` reemplaza el provider con
  `PrefsAppearanceRepository(prefs)`, usando la misma instancia de SharedPreferences.
- [ ] **Step 4:** correr `test/appearance` y `test/features/home_screen_test.dart`. Esperado: verde.
- [ ] **Step 5:** commit `feat(client): la preferencia de apariencia se guarda en el dispositivo`.

### Task 4: Dónde se elige la apariencia

**Files:**
- Create: `lib/features/shared/appearance_controls.dart`
- Modify:
  - `lib/features/shared/store_menu.dart`: el selector debajo de las secciones;
  - `lib/features/shared/brand.dart`: el botón en las `actions` de escritorio, antes de `CartButton`;
  - `lib/features/admin/admin_shell.dart`: el botón antes de `AccountActions`.
- Test: `test/features/appearance_controls_test.dart`

**Interfaces:**
- Consumes: `appearanceProvider` (Task 3).
- Produces:
  - `AppearanceSelector`: un `SegmentedButton<ThemePreference>` con tres segmentos (íconos
    `smartphone`, `light_mode`, `dark_mode`; etiquetas "Sistema", "Claro" y "Oscuro"); debajo, "Sistema
    sigue al modo de tu teléfono.";
  - `AppearanceButton`: un `MenuAnchor` con un `IconButton` (tooltip "Apariencia"; el ícono es el del
    modo activo) y tres `MenuItemButton`, con la marca en el activo.

- [ ] **Step 1:** los tests:
  - `'el selector marca la opción activa y la cambia'`;
  - `'el botón abre el menú y cambia a oscuro'`;
  - `'el menú lateral muestra Apariencia'` (en `StoreMenu`, a 390 px);
  - `'la barra de escritorio tiene el botón'` (a 1280 px);
  - `'el panel tiene el botón'` (con `pumpPanel`);
  - `'el selector entra en 320 con el texto al 130 %'`.
- [ ] **Step 2:** correrlos. Esperado: fallan, porque los widgets no existen.
- [ ] **Step 3:** implementar y ubicar los controles.
- [ ] **Step 4:** correr el test nuevo, más `store_menu_test`, `brand_test`, `account_bar_test` y
  `admin_shell_test`. Esperado: verde.
- [ ] **Step 5:** commit `feat(client): elegir Sistema, Claro u Oscuro en la tienda y en el panel`.

### Task 5: Arranque sin destello

**Files:**
- Modify: `web/index.html`, `android/app/src/main/res/values/colors.xml`
- Create: `android/app/src/main/res/values-night/colors.xml`
- Test: `test/theme/web_metadata_test.dart`

- [ ] **Step 1:** los tests:
  - `'la web pinta el fondo oscuro antes de cargar'`: `index.html` tiene un `<style>` con
    `@media (prefers-color-scheme: dark)` y `#171513`, y dos `meta name="theme-color"` con `media`;
  - `'Android arranca en oscuro'`: `values-night/colors.xml` define `launch_background` `#171513`.
- [ ] **Step 2:** correrlos. Esperado: fallan.
- [ ] **Step 3:** implementar. El `drawable/launch_background.xml` ya usa `@color/launch_background`.
- [ ] **Step 4:** correr `web_metadata_test`. Esperado: verde.
- [ ] **Step 5:** commit `feat(client): la app arranca en oscuro sin destello blanco`.

### Task 6: Migración de colores, la tienda

**Files:**
- Modify: `test/theme/no_loose_colors_test.dart`. Prohíbe también `NeilsColors.`, `OrderStatusColors.`,
  `StateColors.`, `PlaceholderColors.` y `neilsCardShadow` fuera de `lib/theme/`. Lleva una lista
  `pendientes` con los 35 archivos que hoy los usan; cada tanda la achica.
- Modify (esta tanda):
  - `lib/features/shared/`: `cart_bar`, `brand_hero`, `brand`, `diagonal_band`, `page_title`,
    `vip_tag`;
  - `lib/features/catalog/`: `offer_badges`, `line_total_pill`, `promo_ribbon`, `price_tag`,
    `category_photo`, `category_card`, `stock_note`, `product_photo`, `category_header`;
  - `lib/features/home/`: `promotions_banner`, `product_tabs`, `home_screen`.
- Test: `test/theme/dark_store_test.dart`

- [ ] **Step 1:** ampliar `no_loose_colors_test`, con los 35 archivos en `pendientes`. Correrlo:
  verde.
- [ ] **Step 2:** sacar de `pendientes` los archivos de esta tanda y correrlo. Esperado: falla y los
  lista.
- [ ] **Step 3:** en `dark_store_test.dart`, los tests (los widgets envueltos en
  `neilsTheme(Brightness.dark)`):
  - `'la barra del carrito en oscuro: fondo rojo y texto blanco'`;
  - `'la pastilla del total en oscuro usa money sobre moneyTint'`;
  - `'el precio en oferta en oscuro usa brandText'`.

  Correrlos. Esperado: fallan, porque los widgets usan las constantes claras.
- [ ] **Step 4:** migrar cada archivo a `context.palette` o al `colorScheme`. Los pares de categoría
  salen de `context.palette.placeholderFor(id)`.
- [ ] **Step 5:** correr `test/theme` y `test/features`. Esperado: verde, y en claro sin cambios.
- [ ] **Step 6:** commit `refactor(client): la tienda toma los colores del tema`.

### Task 7: Migración de colores, carrito, pedidos, cuenta e ingreso

**Files:**
- Modify:
  - `lib/features/cart/cart_screen.dart`;
  - `lib/features/orders/`: `order_tracker`, `my_orders_screen`, `order_lines`;
  - `lib/features/auth/auth_form.dart`, `lib/features/account/my_codes_section.dart`.
  - Los estados de pedido salen de un helper `Color statusColor(NeilsPalette, OrderStatus)`, en
    `lib/theme/palette.dart`.
- Test: `test/theme/dark_store_test.dart`

- [ ] **Step 1:** sacar los archivos de `pendientes`, y sumar el test
  `'el seguimiento en oscuro usa los estados oscuros'` (punto de "en camino" `#8CBDE6`). Correr los dos:
  fallan.
- [ ] **Step 2:** migrar.
- [ ] **Step 3:** correr `test/theme`, más `order_tracker_test`, `cart_screen_test`, `checkout_test`,
  `auth_screens_test` y `my_account_test`. Esperado: verde.
- [ ] **Step 4:** commit `refactor(client): carrito, pedidos e ingreso toman los colores del tema`.

### Task 8: Migración de colores, el panel

**Files:**
- Modify:
  - `lib/features/admin/`: `shared/vip_badge`, `shared/emails_add_form`, `home/kpi_card`,
    `home/home_cards`, `team/team_widgets`, `team/admin_roles_screen`,
    `promotions/admin_promotions_screen`, `promotions/admin_promo_codes_screen`,
    `products/admin_products_screen`, `vip/admin_vip_screen`, `inventory/movement_form`;
  - `lib/theme/neils_theme.dart`: `neilsAdminTheme` en los dos modos.
  - Quitar la lista `pendientes` de `no_loose_colors_test`.
- Test: `test/theme/dark_admin_test.dart`

- [ ] **Step 1:** vaciar `pendientes` y sumar `'el inicio del panel en oscuro, sin errores'`, con
  `pumpPanel` y el tema oscuro. Correr los dos: fallan.
- [ ] **Step 2:** migrar.
- [ ] **Step 3:** correr `test/theme` y `test/admin`. Esperado: verde.
- [ ] **Step 4:** commit `refactor(client): el panel toma los colores del tema`.

### Task 9: Las pantallas en oscuro, documentación y cierre del PR 1

**Files:**
- Create: `test/theme/dark_screens_test.dart`
- Modify: `apps/client/README.md` (la apariencia, la paleta, la migración) y
  `docs/ARQUITECTURA_Y_ROADMAP.md` (modo oscuro).

- [ ] **Step 1:** el test `'cada pantalla en oscuro, sin errores ni desbordes'`:
  - la app entera con la preferencia en oscuro, en `/`, `/catalogo`, `/producto/<id>`, `/carrito`,
    `/mis-pedidos`, `/login` y `/admin`;
  - a 390 × 844 y a 1280 × 900;
  - `tester.takeException()` nulo en cada una.
- [ ] **Step 2:** correrlo. Esperado: verde, porque la migración ya está. Si falla, arreglar la causa
  con su test.
- [ ] **Step 3:** la documentación.
- [ ] **Step 4:** la suite completa y `flutter analyze lib test tool`. Esperado: todo verde.
- [ ] **Step 5:** capturas locales en claro y oscuro (fuera del repo), para revisarlas contra el lienzo.
- [ ] **Step 6:** commit `docs: el modo oscuro`.

---

## PR 2: Mostrador de abasto (`feature/mostrador-de-abasto`)

### Task 10: Los tokens nuevos del claro y las formas

**Files:**
- Modify: `lib/theme/palette.dart` (`NeilsPalette.light`) y `lib/theme/neils_theme.dart`
- Test: `test/theme/theme_test.dart`

- [ ] **Step 1:** los tests:
  - `'el claro del mostrador'`: background `#FAF8F5`, surface `#FFFFFF`, surfaceAlt `#F0ECE6`, line
    `#E3DCD4`, ink `#211B17`, inkMuted `#655A52`, brandText `#A61F18`, money `#205B38` y moneyTint
    `#E1F2E7`;
  - `'tarjetas con borde y sin sombra'`: `cardTheme.elevation == 0` y la forma tiene un borde `line`,
    en la tienda y en el panel;
  - `'los radios'`: 12 en tarjetas, 10 en botones y campos.

  Los tests de contraste del Task 1 siguen corriendo con estos valores.
- [ ] **Step 2:** correrlos. Esperado: fallan.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** correr `test/theme`, `test/features` y `test/admin`. Esperado: verde. Si un test viejo
  comprueba la sombra, se ajusta al borde.
- [ ] **Step 5:** commit `feat(client): los colores y las formas del mostrador`.

### Task 11: Los tokens de movimiento

**Files:**
- Modify:
  - `lib/theme/motion.dart`: `press` 90 ms, `fade` 160 ms, `hover` 180 ms, `photoZoom` 600 ms,
    `entrance` 600 ms, `ease = Cubic(.2, .8, .2, 1)`. Sale `bump`;
  - `lib/features/shared/press_scale.dart`: escala 0,985;
  - `lib/features/shared/cart_button.dart`: el número con `AnimatedSwitcher` y un fundido, sin rebote;
  - `lib/features/catalog/line_total_pill.dart`, el número de `quantity_stepper.dart` y el total de
    `cart_bar.dart`: el mismo fundido de 160 ms;
  - la entrada del precio VIP empieza en 0,97 (`VipReveal`, en `price_tag.dart`).
- Test: `test/features/cart_button_test.dart`, `test/features/product_tile_test.dart` y
  `test/features/product_card_test.dart` (que ya cubre `VipReveal`).

- [ ] **Step 1:** los tests:
  - `'el número del carrito cambia con un fundido, sin rebote'`: al agregar, no hay un `ScaleTransition`
    con valor mayor a 1, y sí hay un `FadeTransition`;
  - `'la pastilla cambia de total con un fundido'`;
  - `'la entrada VIP empieza en 0,97'`;
  - `'con reducir animaciones, el número cambia en el acto'`.
- [ ] **Step 2:** correrlos. Esperado: fallan.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** correr `test/features`. Esperado: verde.
- [ ] **Step 5:** commit `feat(client): movimiento sin rebotes, con los tiempos del mostrador`.

### Task 12: La etiqueta de mercado

**Files:**
- Create: `lib/features/catalog/promo_tag.dart`
- Delete: `lib/features/catalog/promo_ribbon.dart`
- Modify: `product_tile.dart`, `product_card.dart`, `product_detail_screen.dart` y `cart_screen.dart`, que
  usan `PromoTag` (en el carrito, "Regalo" va con `PromoTag.gift()`).
- Test: `test/features/promo_tag_test.dart`; en `product_tile_test`, `product_card_test` y
  `cart_screen_test`, `PromoRibbon` pasa a `PromoTag`.

**Interfaces:**
- Produces: `PromoTag(List<ProductOffer> offers)` muestra la primera (con `OfferBadges.badgeText`);
  `PromoTag.gift()` muestra "Regalo". Borde punteado `brandFill`, texto `brandText`. El lector dice las
  descripciones unidas.

- [ ] **Step 1:** los tests:
  - `'muestra la primera promoción y el lector dice todas'`;
  - `'en oscuro, borde rojo y texto brandText'`;
  - `'sin promociones no ocupa lugar'`;
  - `'"2.ª al 50 %" entra a 320 con el texto al 130 %'`.
- [ ] **Step 2:** correrlos: fallan.
- [ ] **Step 3:** implementar y reemplazar los usos. El borde punteado se dibuja con un `CustomPainter`.
- [ ] **Step 4:** correr `test/features`: verde.
- [ ] **Step 5:** commit `feat(client): la etiqueta de mercado reemplaza la cinta de promoción`.

### Task 13: La fila de producto en el teléfono

**Files:**
- Modify: `lib/features/catalog/product_tile.dart`. `ProductTile` se dibuja como fila: sin `Card` y la
  foto con `Hero(tag: 'producto-<id>')`. Suma `ProductRows(children)`, un bloque `surface` con líneas
  finas entre las filas.
- Modify: `catalog_screen.dart`, `product_tabs.dart` y `home_screen.dart`, que usan `ProductRows` en el
  teléfono.
- Test: `test/features/product_tile_test.dart`

- [ ] **Step 1:** los tests:
  - `'la fila no es una tarjeta: sin Card ni sombra'`;
  - `'ProductRows pone una línea entre filas y no al final'`;
  - `'la foto lleva el Hero del producto'`;
  - los de 320 y 390 px con el texto al 130 % siguen pasando.
- [ ] **Step 2:** correrlos: fallan.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** correr `test/features`: verde.
- [ ] **Step 5:** commit `feat(client): los productos en filas en el teléfono`.

### Task 14: La tarjeta de producto en escritorio

**Files:**
- Modify: `lib/features/catalog/product_card.dart`:
  - borde `line`, sin sombra, la foto 4:3 con el `Hero` del producto;
  - con mouse (`MouseRegion`), la tarjeta sube 2 px en 180 ms y la foto pasa a 1,03 en 600 ms, dentro de
    un `ClipRect`;
  - con reducir animaciones, no se mueve.
- Test: `test/features/product_card_test.dart`

- [ ] **Step 1:** los tests:
  - `'al pasar el mouse sube 2 px y la foto se acerca'`, con `TestPointer` de tipo mouse;
  - `'con reducir animaciones no se mueve'`;
  - `'sin sombra y con borde'`.
- [ ] **Step 2:** correrlos: fallan.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** correr `test/features`: verde.
- [ ] **Step 5:** commit `feat(client): la tarjeta de producto responde al mouse`.

### Task 15: La franja de campaña

**Files:**
- Create: `lib/features/home/campaign_band.dart`
- Delete: `lib/features/home/promotions_banner.dart`, después de reemplazar sus usos.
- Test: `test/features/campaign_band_test.dart`

**Interfaces:**
- Consumes: `onSaleProductsProvider`.
- Produces: `CampaignBand()`.
  - El título es la `description` de la primera oferta por cantidad (tipo `buyXPayY` o `extraUnit`) de
    los productos en promoción; si no hay ninguna, "Promociones para tu negocio".
  - El subtítulo es "N productos en promoción hoy" (o "1 producto…").
  - "Ver promociones" lleva a `Routes.promotions`.
  - El fondo es `brandFill` y el texto `onBrand`.
  - Mientras carga o si falla, no ocupa lugar.

- [ ] **Step 1:** los tests:
  - `'el título sale de la primera promoción por cantidad'`;
  - `'sin promociones por cantidad, el título general'`;
  - `'cuenta los productos en promoción'`;
  - `'Ver promociones lleva al catálogo de promociones'`;
  - `'si falla, no ocupa lugar'`;
  - `'entra a 320 con el texto al 130 %'`.
- [ ] **Step 2:** correrlos: fallan.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** correr el test nuevo y `home_screen_test`: verde.
- [ ] **Step 5:** commit `feat(client): la franja de la campaña de la semana`.

### Task 16: La portada

**Files:**
- Modify:
  - `lib/features/home/home_screen.dart`;
  - `lib/features/home/product_tabs.dart`: el título según la pestaña;
  - `lib/features/shared/brand_hero.dart`: texto a la izquierda, la foto o el bloque rojo a la derecha
    con `DiagonalClipper`, y la entrada.
  - Sale `TrustBadges` de la portada; si nadie más lo usa, se borra.
- Create: `lib/features/home/store_footer.dart` (el nombre, la dirección de `storeSettingsProvider` y
  los enlaces) y `lib/features/home/home_entrance.dart` (`homeEntranceProvider`: si la entrada ya se vio
  en esta sesión).
- Test: `test/features/home_screen_test.dart` y `test/features/brand_hero_test.dart`

**Interfaces:**
- Consumes: `storeSettingsProvider` (para `openingHours` y `address`), `greetingFor`, `ProductRows` y
  `CampaignBand`.
- Produces:
  - **teléfono:** "Buenos días, Ana", el buscador, las pestañas con su título ("Reposición habitual",
    "Lo más pedido", "Promociones de hoy"), las filas, la franja y las categorías en una fila que se
    desliza;
  - **escritorio:** el titular "Insumos para restaurantes y cafeterías", la línea "Embutidos, lácteos,
    panes y abarrotes, con entrega a tu negocio o recojo en tienda.", "Atendemos <openingHours>" (sin
    horario, no aparece), los dos botones, la foto en diagonal, las pestañas, la franja, las categorías y
    el pie.

- [ ] **Step 1:** los tests:
  - `'cada pestaña tiene su título'`;
  - `'el horario de la tienda aparece si está cargado'` y `'sin horario no hay línea'`;
  - `'el pie muestra la dirección de la tienda'`;
  - `'la entrada se ve una vez por sesión'`: la segunda visita no anima;
  - `'con reducir animaciones, el titular está desde el primer cuadro'`;
  - `'el buscador responde durante la entrada'`;
  - `'la portada entra en 320 y en 1280 sin desbordes'`.
- [ ] **Step 2:** correrlos: fallan.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** correr `test/features`: verde.
- [ ] **Step 5:** commit `feat(client): la portada del mostrador`.

### Task 17: El catálogo

**Files:**
- Modify:
  - `lib/features/catalog/catalog_screen.dart`: en el teléfono, las categorías en un `ListView`
    horizontal;
  - `category_header.dart`: el fondo `surfaceAlt`, y la foto o el color a la derecha con
    `DiagonalClipper`;
  - `category_photo.dart` y `category_card.dart`: sin foto, el bloque del color de la categoría, sin la
    inicial gigante; el nombre va debajo, como hoy.
- Test: `test/features/catalog_screen_test.dart`, `test/features/category_header_test.dart` y
  `test/features/category_card_test.dart`

- [ ] **Step 1:** los tests:
  - `'en el teléfono las categorías van en una fila que se desliza'` (un `Scrollable` horizontal a
    390 px);
  - `'en escritorio van en varias líneas'`;
  - `'el encabezado de la categoría sobre surfaceAlt'`;
  - `'sin foto, el color de la categoría sin la inicial'` (reemplaza el caso que hoy busca la "E").

  Los de 130 % siguen.
- [ ] **Step 2:** correrlos: fallan.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** correr `test/features`: verde.
- [ ] **Step 5:** commit `feat(client): el catálogo del mostrador`.

### Task 18: El detalle del producto

**Files:**
- Modify: `lib/features/catalog/product_detail_screen.dart`:
  - en el teléfono, la foto a todo el ancho con Volver y el carrito flotando;
  - en escritorio, dos columnas y la ruta "Catálogo › <categoría>";
  - la explicación de la promoción en un recuadro `surfaceAlt`;
  - el `Hero` del producto.
- Test: `test/features/product_detail_test.dart`

- [ ] **Step 1:** los tests:
  - `'en el teléfono, Volver y el carrito sobre la foto'`;
  - `'en escritorio, la ruta lleva a la categoría'`;
  - `'la promoción se explica en su recuadro'`;
  - `'la foto es el mismo Hero que la fila'`.
- [ ] **Step 2:** correrlos: fallan.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** correr `test/features`: verde.
- [ ] **Step 5:** commit `feat(client): el detalle del producto del mostrador`.

### Task 19: El carrito

**Files:**
- Create: `lib/features/cart/cart_ticket.dart`. `CartTicket(subtotal, discount, total)`, con el borde
  perforado (un `CustomClipper`).
- Modify: `lib/features/cart/cart_screen.dart`:
  - las líneas en filas;
  - el tipo de entrega en un `SegmentedButton`;
  - el ticket;
  - en escritorio, dos columnas.
- Test: `test/features/cart_ticket_test.dart`, más `cart_screen_test` y `checkout_test`.

- [ ] **Step 1:** los tests:
  - `'el ticket muestra subtotal, descuentos y total estimado'`;
  - `'sin descuentos no hay línea de descuentos'`;
  - `'el ticket entra a 320 con el texto al 130 %'`;
  - `'en escritorio, las líneas y el resumen van lado a lado'`;
  - `'el tipo de entrega es un control segmentado'`.

  Los tests del carrito y de la confirmación siguen pasando.
- [ ] **Step 2:** correrlos: fallan.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** correr `test/features`: verde.
- [ ] **Step 5:** commit `feat(client): el carrito del mostrador, con su ticket`.

### Task 20: Mis pedidos

**Files:**
- Modify: `lib/features/orders/my_orders_screen.dart`:
  - el pedido en curso con la línea de seguimiento y el código en `surfaceAlt`;
  - desde 1100 px, la lista a la izquierda y el pedido elegido a la derecha (estado local con el id
    elegido; por defecto, el primero).
- Test: `test/features/my_orders_test.dart`, nuevo (hoy Mis pedidos se prueba dentro de
  `checkout_test.dart`, que debe seguir pasando).

- [ ] **Step 1:** los tests:
  - `'desde 1100 px, la lista y el pedido elegido lado a lado'`;
  - `'tocar otro pedido lo muestra a la derecha'`;
  - `'en el teléfono sigue la lista'`.
- [ ] **Step 2:** correrlos: fallan.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** correr `my_orders_test`, `checkout_test` y `order_tracker_test`: verde.
- [ ] **Step 5:** commit `feat(client): Mis pedidos con la lista y el detalle lado a lado`.

### Task 21: Ingreso, registro y el panel

**Files:**
- Modify:
  - `lib/features/auth/auth_form.dart`: el panel rojo con la diagonal, como hoy, con los tokens nuevos;
  - `lib/features/admin/admin_shell.dart`: el menú lateral sobre `surfaceAlt`;
  - `lib/features/admin/home/kpi_card.dart`: la cifra en `ink`.
- Test: `auth_screens_test`, `admin_shell_test` y `admin_home_test`.

- [ ] **Step 1:** los tests:
  - `'el menú del panel va sobre surfaceAlt'`;
  - `'las tarjetas del panel tienen borde y no sombra'`;
  - `'el ingreso mantiene el panel rojo en los dos modos'`.
- [ ] **Step 2:** correrlos: fallan.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** correr `test/features` y `test/admin`: verde.
- [ ] **Step 5:** commit `feat(client): ingreso y panel con los tokens del mostrador`.

### Task 22: Documentación, capturas y cierre del PR 2

**Files:**
- Modify: `apps/client/README.md` (las piezas nuevas y el movimiento), `docs/ARQUITECTURA_Y_ROADMAP.md`
  y `docs/DEMO.md` (lo que se ve en la demo).

- [ ] **Step 1:** la documentación.
- [ ] **Step 2:** la suite completa de la app y `flutter analyze lib test tool`: verde.
- [ ] **Step 3:** capturas locales (fuera del repo) de todas las pantallas en claro y oscuro, en el
  teléfono y en escritorio. Revisarlas contra el lienzo y anotar en el registro cada diferencia
  decidida.
- [ ] **Step 4:** commit `docs: el mostrador de abasto`.
