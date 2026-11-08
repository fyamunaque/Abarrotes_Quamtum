# Nueva marca, Frecuentes y Sugeridos, y fotos de categorías: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cambiar la identidad de la app (logo, rojo, Poppins, mensaje para negocios) con el estilo de las maquetas en la tienda y en el panel, y sumar las pestañas Frecuentes y Sugeridos y las fotos de categorías.

**Architecture:** El PR 1 es solo la app:
- tokens nuevos en `lib/theme/`;
- un generador de logo e íconos que queda en el repo;
- piezas reutilizables en `lib/features/shared/` y `lib/features/catalog/`;
- cada pantalla rehecha sobre esas piezas.

El PR 2 suma al servidor dos rutas de productos (`frequent`, `suggested`), la foto y la descripción de `Category` (con lo genérico de las fotos movido a `common/`), y en la app la sección "Categorías" del panel y las pestañas de la portada.

**Tech Stack:** Flutter (Riverpod 3, go_router, google_fonts con fuentes empaquetadas). Serverpod 4 (Dart) y PostgreSQL.

**Spec:** `docs/superpowers/specs/2026-11-05-nueva-marca-design.md`

## Global Constraints

**Ramas y commits**
- **PR 1:** `feature/nueva-marca`, desde `feature/codigos-promocionales` (`faf44f0`).
- **PR 2:** `feature/frecuentes-y-categorias`, desde `feature/nueva-marca`.
- **El primer commit del PR 1** sube la spec y este plan: `docs: especificación y plan de la nueva marca`.
- **Commits:** Conventional Commits en español, cada uno terminado en `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Sin** push, PR ni APK hasta que se pidan.

**Colores**
- Solo desde `lib/theme/`.
- Tokens exactos: `primary #C8281E`, `primaryDark #9E1B14`, `primaryTint #FBE3E0`, `background #FBF7F2`, `surface #FFFFFF`, `ink #1F1A17`, `money #276B43`, `moneyTint #E3F2E7`.
- No cambian: `OrderStatusColors`, `StateColors`, `PlaceholderColors`.

**Fuentes**
- Poppins 600/700/800 en `display*`, `headline*`, `title*`, `labelLarge` y precios. Inter 400/500/600 en el resto.
- Empaquetadas en `assets/google_fonts/` con su OFL. `GoogleFonts.config.allowRuntimeFetching = false` sigue igual.
- Bajar los archivos de Poppins es una descarga: se pide permiso al usuario diciendo el archivo, el origen y el tamaño.

**Logo**
- Nunca se recorta el tenedor ni las letras.
- El ícono (Android, web, favicon) es el tenedor y "NEIL'S" en blanco sobre `#C8281E`, sin "FOOD SERVICE'S". En el resto va el logo completo.
- El `semanticLabel` es "Neil's Food Services".

**Textos**
- El nombre en los textos es "Neil's Food Services".
- Los textos para negocios, exactos, son los de la tabla "Textos para negocios" de la spec.
- `lib/legal/legal_texts.dart` no se toca.

**Stock en la tienda**

| Unidades | Texto |
|---|---|
| 0 | "Agotado" |
| 1 | "Última unidad" |
| 2 a 5 | "Últimas N" |
| más de 5 | "Disponible" |

Nunca se muestra el número de unidades fuera de estos textos.

**Anchos**
- Tienda: escritorio desde 840 px (`AccountActions.wideFrom`).
- Panel: menú lateral angosto desde 840 px (`AdminShell.wideFrom`), y ancho, con texto, desde 1200 px.

**App**
- Riverpod: nada de `setState` para datos compartidos.
- go_router: paths en `router/routes.dart`, permisos en `Routes._panelPermissions`.
- HTTP solo detrás de repositorios con interfaz, implementación y provider. Las versiones en memoria van en `test/fakes.dart`.
- Textos de UI en español; nombres de código en inglés.

**Tests de la app**
- Desde `apps/client`: `flutter test --no-pub -r json <archivo>`.
- Si `flutter_tester` se cae (tests que no terminan sin un assert fallido), se reintenta el archivo; si sigue, test por test con `--plain-name`. Si el script de reintentos ya no está en el scratchpad, se vuelve a escribir: corre cada archivo, reintenta dos veces y junta los resultados.
- Capturas temporales: goldens en `apps/client/test_capturas/`, que salen a `capturas/nueva-marca/`. Las dos carpetas están excluidas de git en `.git/info/exclude`.

**Servidor (PR 2)**
- No se edita a mano nada de `lib/src/generated/` ni de `abarrotes_client`.
- Después de tocar un `.spy.yaml`:
  - `export PATH="/c/Users/aligh/develop/flutter/bin:$PATH"; dart pub global run serverpod_cli generate`;
  - `create-migration --tag <tag>`;
  - aplicar con `/c/Users/aligh/develop/flutter/bin/dart run bin/main.dart --role maintenance --apply-migrations`;
  - revisar con `psql`. La contraseña se lee de `config/passwords.yaml` dentro del comando y nunca se imprime.
- Cada ruta nueva lleva `guards.require`, `signedIn` o queda pública, y tiene su fila en `test/unit/auth/route_permissions_test.dart`.
- Ningún dominio importa la lógica de otro: lo común de las fotos va a `common/`.
- Tests: `dart test <archivo>` con el Dart de Flutter, desde `apps/server/abarrotes_server`.

**Documentación**
- Va en el mismo commit que el cambio: `apps/client/README.md`, `apps/server/README.md`, `docs/ARQUITECTURA_Y_ROADMAP.md`, `docs/DEMO.md`.

## Review Focus

1. **Nombres de producto largos y textos grandes.** Con un nombre de 60 caracteres y el texto del sistema al 130 %, `ProductTile` en un teléfono de 360 px no se desborda: el nombre se corta en dos líneas con "…" y los botones siguen visibles. Test en Task 5.
2. **Un producto que ya está en el carrito con todo su stock.** "Editar" muestra la cantidad del carrito, el "+" queda deshabilitado en el máximo, y "Agregar" en un agotado está deshabilitado con "Agotado". Test en Task 5.
3. **La barra fija del carrito tapa el final de la lista en el teléfono.** El último producto queda visible por encima de la `CartBar`: hay un relleno abajo igual a su alto. Test en Task 6.
4. **El cliente nuevo o sin pedidos en 180 días.** Frecuentes no rompe la portada: muestra el texto vacío de la spec y la pestaña inicial es Sugeridos. Test en Task 17.
5. **Una foto de categoría que no carga** (404 o sin red). La tarjeta y el encabezado vuelven al color de la categoría con su inicial, sin un ícono roto. Test en Task 16.

---

## PR 1 · `feature/nueva-marca`

### Task 1: Rama, tokens de color y tema

**Files:**
- Modify: `apps/client/lib/theme/brand_colors.dart` (`NeilsColors`)
- Modify: `apps/client/lib/theme/neils_theme.dart` (`neilsColorScheme`, `neilsTheme`, `neilsAdminTheme`)
- Modify, porque usan `accent` o `cream`: `lib/features/account/my_codes_section.dart`, `lib/features/admin/home/home_cards.dart`, `lib/features/admin/shared/vip_badge.dart`, `lib/features/catalog/offer_badges.dart`, `lib/features/shared/page_title.dart`, `lib/features/shared/vip_tag.dart`
- Test: `apps/client/test/theme/theme_test.dart` (ya tiene `_contrast`, así que reemplaza al `brand_contrast_test.dart` de la spec)

**Interfaces:**
- Produces:
  - `NeilsColors.primary` `#C8281E`, `primaryDark` `#9E1B14`, `primaryTint` `#FBE3E0`, `background` `#FBF7F2`, `surface` `#FFFFFF`, `ink` `#1F1A17`, `money` `#276B43`, `moneyTint` `#E3F2E7`. Se borran `accent` y `cream`.
  - `neilsColorScheme`:
    - `primary` = `NeilsColors.primary`, `onPrimary` blanco;
    - `primaryContainer` = `primaryTint`, `onPrimaryContainer` = `primaryDark`;
    - `secondary` = `primaryDark`, `onSecondary` blanco;
    - `secondaryContainer` = `primaryTint`, `onSecondaryContainer` = `primaryDark`;
    - `surface` = `background`, `onSurface` = `ink`, `onSurfaceVariant` `#5E534D`, `outline` `#8C7F77`, `outlineVariant` `#E5DCD3`;
    - `surfaceContainerLowest` `#FFFFFF`, `Low` `#F7F1EA`, `surfaceContainer` `#F3ECE4`, `High` `#EEE6DD`, `Highest` `#E8DFD5`;
    - `inverseSurface` = `ink`, `onInverseSurface` = `background`;
    - los de error, como hoy.
  - `neilsTheme()`:
    - `scaffoldBackgroundColor` y `appBarTheme.backgroundColor` = `background`;
    - `cardTheme`: blanco, `elevation: 1`, `shadowColor: Color(0x331F1A17)`, sin `surfaceTintColor`, radio 16;
    - botones `Filled`, `Outlined` y `Text`: `RoundedRectangleBorder` de radio 10 y alto mínimo 44;
    - `inputDecorationTheme`: `OutlineInputBorder` de radio 12, relleno blanco;
    - `chipTheme`: forma de píldora (`StadiumBorder`), con `selectedColor` = `primaryTint`.
  - `neilsAdminTheme`: sus tarjetas también pasan a blanco con la misma sombra, sin borde. Lo seleccionado sigue en `primaryTint`.

- [ ] **Step 1: Crear la rama y subir la spec y el plan**

```bash
git switch -c feature/nueva-marca feature/codigos-promocionales
git add docs/superpowers/specs/2026-11-05-nueva-marca-design.md docs/superpowers/plans/2026-11-05-nueva-marca.md
git commit -m "docs: especificación y plan de la nueva marca"
```

- [ ] **Step 2: Write the failing tests**

En `theme_test.dart`, se reemplazan los dos primeros tests:
- `'los tokens de marca son los de la nueva marca'`: los ocho colores de arriba, exactos.
- `'el rojo sirve para botones y para texto'`:
  - `_contrast(Colors.white, primary) >= 5.5`;
  - `_contrast(primary, background) >= 5.0`;
  - `_contrast(primaryDark, primaryTint) >= 6.5`;
  - `_contrast(money, moneyTint) >= 5.5`;
  - `_contrast(ink, background) >= 16`;
  - `_contrast(onSurfaceVariant, Colors.white) >= 4.5`.
- `'el ColorScheme usa el rojo como primary'`: `scheme.primary == NeilsColors.primary`, `scheme.surface == NeilsColors.background`, `scheme.surfaceContainerLowest == Colors.white`.

Los tests de Confirmado y de error se quedan, con `surfaceContainerLowest` blanco.

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test --no-pub -r json test/theme/theme_test.dart`
Expected: FAIL (los colores son los del naranja).

- [ ] **Step 4: Implement the tokens and the themes as in Interfaces**

En los seis archivos que usan `accent` o `cream`:
- `accent` → `primary` o `primaryDark` (donde es texto sobre un fondo claro);
- `cream` → `background` (o blanco, donde es texto sobre rojo).

`SwooshPainter` también usa `accent`: hasta que se borre en el Task 4, usa `primary`.

- [ ] **Step 5: Run the theme test and analyze**

Run: `flutter test --no-pub -r json test/theme/theme_test.dart` → PASS. `flutter analyze` → sin problemas.

- [ ] **Step 6: Commit**

```bash
git add apps/client/lib apps/client/test/theme
git commit -m "feat(client): colores de la nueva marca"
```

### Task 2: Poppins en lugar de Baloo 2

**Files:**
- Create: `apps/client/assets/google_fonts/Poppins-SemiBold.ttf`, `Poppins-Bold.ttf`, `Poppins-ExtraBold.ttf`, `OFL-Poppins.txt`
- Delete: `apps/client/assets/google_fonts/Baloo2-*.ttf`, `OFL-Baloo2.txt`
- Modify: `apps/client/lib/theme/neils_theme.dart` (`neilsTextTheme`, `NeilsText.price`)
- Modify: `apps/client/test/support.dart` (`useBundledFonts`: se va el truco de `Baloo2-SemiBold`)
- Modify: `apps/client/pubspec.yaml` (el comentario de `assets/google_fonts/` dice "Poppins e Inter")
- Test: `apps/client/test/theme/theme_test.dart`

**Interfaces:**
- Produces:
  - `neilsTextTheme()`:
    - `display*` Poppins 800;
    - `headline*` y `titleLarge` Poppins 700;
    - `titleMedium`, `titleSmall` y `labelLarge` Poppins 600;
    - `body*` Inter 400;
    - `labelMedium` y `labelSmall` Inter 500.
  - `NeilsText.price({double fontSize = 22, Color color = NeilsColors.ink})`: Poppins 700.

- [ ] **Step 1: Pedir permiso y bajar las fuentes**

Pedir permiso al usuario para bajar estos archivos de `https://github.com/google/fonts/raw/main/ofl/poppins/`:
- `Poppins-SemiBold.ttf`, `Poppins-Bold.ttf` y `Poppins-ExtraBold.ttf`, unos 150 KB cada uno;
- `OFL.txt`, unos 4 KB, que se guarda como `OFL-Poppins.txt`.

Con el sí, bajarlos a `assets/google_fonts/`. Revisar con `file` que son `TrueType Font data`.

- [ ] **Step 2: Write the failing test**

`'los títulos van en Poppins y el texto en Inter'`:
- `neilsTextTheme().headlineMedium!.fontFamily` contiene `'Poppins'`;
- `labelLarge` contiene `'Poppins'` y tiene `FontWeight.w600`;
- `bodyMedium` contiene `'Inter'`;
- `NeilsText.price().fontFamily` contiene `'Poppins'` y su `color` es `NeilsColors.ink`.

- [ ] **Step 3: Run it and see it fail**

Run: `flutter test --no-pub -r json test/theme/theme_test.dart`
Expected: FAIL (`Baloo2`).

- [ ] **Step 4: Implement**

- `GoogleFonts.poppins` en lugar de `GoogleFonts.baloo2`.
- Borrar los archivos de Baloo 2.
- En `useBundledFonts`, dejar solo el bloqueo de descargas y quitar el manejador de `flutter/assets`. Si un test se cae buscando un peso, revisar que el nombre del archivo es `Poppins-<Peso>.ttf`.

- [ ] **Step 5: Run the theme tests and three screen tests**

Run: `flutter test --no-pub -r json test/theme test/features/home_screen_test.dart test/features/product_card_test.dart`
Expected: PASS. Poppins es más ancha que Baloo 2: si un test de pantalla falla por un desborde, se arregla en este task (texto que se corta con "…" o que pasa a dos líneas), no se deja para después.

- [ ] **Step 6: Commit**

```bash
git add apps/client/assets/google_fonts apps/client/lib/theme apps/client/test apps/client/pubspec.yaml
git commit -m "feat(client): Poppins en títulos, botones y precios"
```

### Task 3: Logo e íconos desde el JPG

**Files:**
- Create: `apps/client/brand/logo.jpg`, copia de `C:\Users\aligh\AppData\Local\Temp\claude\b7502ebd88b9922a\1e17fdf1-c78b-4060-8912-0b8d7268eaa3\images\3.jpg` (o el original que mande el cliente)
- Create: `apps/client/tool/brand_assets_test.dart` (el generador y sus comprobaciones)
- Regenerate:
  - `apps/client/assets/images/neils_logo.png`;
  - `apps/client/assets/images/neils_logo_white.png` (nuevo);
  - `web/favicon.png` (64 px);
  - `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`;
  - `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` (48, 72, 96, 144 y 192 px);
  - `.../mipmap-*/ic_launcher_foreground.png` (108, 162, 216, 324 y 432 px).
- Create: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`, `android/app/src/main/res/values/colors.xml` (`ic_launcher_background` `#C8281E`)
- Modify: `web/manifest.json`, `web/index.html` (`theme_color`/`theme-color` `#C8281E`, `background_color` `#FBF7F2`)
- Modify: `android/app/src/main/res/values/styles.xml` (el fondo de `LaunchTheme`, `#FBF7F2`)
- Modify: `apps/client/lib/features/shared/brand.dart` (`NeilsLogo`)
- Test: `apps/client/test/features/brand_test.dart`

**Interfaces:**
- Produces:
  - `NeilsLogo({double height = 40})`: `assets/images/neils_logo.png`, sin `ClipRRect`.
  - `NeilsLogo.white({double height = 40})`: `assets/images/neils_logo_white.png`.
  - Las dos con `semanticLabel: "Neil's Food Services"`.

**El generador** corre con `flutter test tool/brand_assets_test.dart`. Usa `dart:ui` dentro de `tester.runAsync`, sin paquetes nuevos:
1. **Transparencia:** decodifica `brand/logo.jpg`. Cada píxel queda en el color de la marca (`#C8281E`, o blanco en la versión blanca), con `alfa = clamp((255 − verde) / (255 − 40), 0, 1)`. El verde del rojo del logo es ≈ 40 y el del blanco es 255: así los bordes salen suaves y sin halo.
2. **Bloques:** busca las filas con algún alfa > 0,05. Forman tres bloques separados por filas vacías: el tenedor, "NEIL'S" y "FOOD SERVICE'S".
   - El logo completo es el recorte de los tres, con 2 % de margen.
   - El del ícono es el recorte de los dos primeros.
   - Si no encuentra exactamente tres bloques, el test falla con un mensaje claro: así se nota si llega un original con otra forma.
3. **Íconos:** cada uno es un cuadrado `#C8281E` con el logo del ícono en blanco, centrado. El ancho del logo es:

   | Ícono | Ancho del logo, en % del lado |
   |---|---|
   | Normal y favicon | 76 % |
   | `maskable` | 60 % (zona segura del 80 %) |
   | `ic_launcher_foreground` | 58 % (zona segura de 66/108), con fondo transparente |

4. Escribe los PNG con `toByteData(format: ImageByteFormat.png)`.

- [ ] **Step 1: Write the generator with its checks first**

Los tests de `tool/brand_assets_test.dart`, que antes de escribir los archivos fallan por no existir:
- `'el logo tiene fondo transparente y es rojo'`: en `neils_logo.png`, el píxel (0,0) tiene alfa 0, y algún píxel tiene alfa 255 con color `#C8281E`.
- `'el logo blanco es el mismo, en blanco'`: el mismo tamaño que el rojo, y los píxeles opacos son blancos.
- `'cada ícono tiene su tamaño y fondo rojo'`: para cada archivo de la lista, ancho = alto = el tamaño indicado, y la esquina es `#C8281E` opaca. En `ic_launcher_foreground`, la esquina es transparente.
- `'el ícono lleva el tenedor y NEIL'S, sin FOOD SERVICE'S'`: el recorte del ícono tiene dos bloques de filas.

- [ ] **Step 2: Run it and see it fail**

Run: `flutter test tool/brand_assets_test.dart`
Expected: FAIL (no está `brand/logo.jpg` o no se generaron los archivos).

- [ ] **Step 3: Copy the JPG, implement the generator and run it**

Run: `flutter test tool/brand_assets_test.dart` → PASS. Los archivos quedan escritos.

Mirar `neils_logo.png` y `Icon-512.png` con Read (son imágenes): el tenedor y las letras completos, sin halo blanco.

- [ ] **Step 4: Android, web and `NeilsLogo`**

- `ic_launcher.xml` con `<adaptive-icon>`: `<background android:drawable="@color/ic_launcher_background"/>` y `<foreground android:drawable="@mipmap/ic_launcher_foreground"/>`.
- Los colores de `manifest.json`, `index.html` y `styles.xml`.

`brand_test.dart`:
- `'NeilsLogo usa el logo rojo y se anuncia con el nombre'`: un `Image` con `AssetImage('assets/images/neils_logo.png')` y `find.bySemanticsLabel("Neil's Food Services")`.
- `'NeilsLogo.white usa el logo blanco'`.

- [ ] **Step 5: Run the tests**

Run: `flutter test --no-pub -r json test/features/brand_test.dart` → PASS. `flutter analyze` → sin problemas.

- [ ] **Step 6: Commit**

```bash
git add apps/client/brand apps/client/tool/brand_assets_test.dart apps/client/assets/images apps/client/web apps/client/android/app/src/main/res apps/client/lib/features/shared/brand.dart apps/client/test/features/brand_test.dart
git commit -m "feat(client): logo nuevo, íconos y colores del navegador"
```

### Task 4: Franja diagonal, portada de marca y sellos (adiós al trazo)

**Files:**
- Create: `apps/client/lib/features/shared/diagonal_band.dart` (`DiagonalBand`)
- Create: `apps/client/lib/features/shared/brand_hero.dart` (`BrandHero`, `TrustBadges`)
- Create: `apps/client/lib/theme/brand_images.dart`
- Delete: `apps/client/lib/features/shared/swoosh.dart`, `apps/client/test/features/swoosh_test.dart`, lo del trazo en `lib/theme/motion.dart`
- Test: `apps/client/test/features/brand_hero_test.dart`

**Interfaces:**
- Produces:
  - **`abstract final class BrandImages`** con `static const String? hero = null;` y `static const String? promotionsBanner = null;`: la ruta de un asset, o `null` mientras el cliente no mande la foto.
  - **`DiagonalBand({String? image, Color color = NeilsColors.primary, Widget? child})`:**
    - corta su contenido en diagonal: el borde izquierdo va del 18 % arriba al 0 % abajo;
    - muestra `image` con `BoxFit.cover`;
    - sin imagen, el bloque `color` con `child`, que en la portada es el tenedor del logo blanco (`NeilsLogo.white`) al 70 % de opacidad.
  - **`BrandHero({required String titleStart, required String titleAccent, required String body, required List<Widget> actions, String? image})`:**
    - desde 840 px: el texto a la izquierda y `DiagonalBand` a la derecha, al 45 %;
    - más angosto: la banda arriba (alto 160) y el texto debajo.
  - **`TrustBadges()`:** "Entrega confiable" (`local_shipping_outlined`), "Calidad garantizada" (`verified_outlined`) y "Atención personalizada" (`support_agent`), separados por divisores. En el teléfono, en columna.

- [ ] **Step 1: Write the failing tests**

- `'BrandHero muestra el titular con la parte en rojo'`: un `RichText` cuyo `TextSpan` de `titleAccent` tiene color `NeilsColors.primary`.
- `'sin foto, la franja es roja con el logo blanco'`: hay un `NeilsLogo.white` dentro de `DiagonalBand`.
- `'en el teléfono la franja va arriba'` (390 × 844): la posición vertical de `DiagonalBand` es menor que la del titular.
- `'TrustBadges muestra los tres sellos'`.

- [ ] **Step 2: Run them and see them fail**

Run: `flutter test --no-pub -r json test/features/brand_hero_test.dart`
Expected: FAIL (no existen).

- [ ] **Step 3: Implement**

`DiagonalBand` con `ClipPath` y un `CustomClipper<Path>`. Borrar `swoosh.dart`, su test y su uso en `motion.dart`.

Hasta el Task 8, `home_screen.dart`, `price_tag.dart` y `product_card.dart` quedan sin el trazo: se quitan sus usos sin rediseñar todavía. También salen de `home_screen_test.dart` y `product_card_test.dart` las comprobaciones del trazo.

- [ ] **Step 4: Run tests and analyze**

Run: `flutter test --no-pub -r json test/features/brand_hero_test.dart test/features/home_screen_test.dart test/features/product_card_test.dart` → PASS. `flutter analyze` → sin problemas.

- [ ] **Step 5: Commit**

```bash
git add -A apps/client/lib apps/client/test
git commit -m "feat(client): franja diagonal y portada de marca en lugar del trazo"
```

### Task 5: Producto en lista y en tarjeta

**Files:**
- Create: `apps/client/lib/features/catalog/promo_ribbon.dart` (`PromoRibbon`)
- Create: `apps/client/lib/features/catalog/stock_note.dart` (`StockNote`, `stockText`)
- Create: `apps/client/lib/features/catalog/line_total_pill.dart` (`LineTotalPill`)
- Create: `apps/client/lib/features/catalog/product_tile.dart` (`ProductTile`)
- Modify: `apps/client/lib/features/catalog/price_tag.dart` (`PriceTag`, la `PriceText` de la spec: se renueva sin cambiarle el nombre)
- Modify: `apps/client/lib/features/catalog/product_card.dart` (`ProductCard`)
- Modify: `apps/client/lib/features/catalog/offer_badges.dart` (`OfferBadges` queda para el detalle y el carrito; las tarjetas usan `PromoRibbon`)
- Test: `apps/client/test/features/product_tile_test.dart`, `apps/client/test/features/product_card_test.dart`

**Interfaces:**
- Consumes: `cartProvider` (`Cart.quantityOf(id)`, `CartNotifier.add`/`setQuantity`), `addToCart(context, ref, product, quantity)`, `QuantityStepper(quantity, max, onChanged)`, `ProductPhoto`, `Product.sku/offers/finalPriceCents/maxQuantity/inStock`.
- Produces:
  - **`String stockText(int stock)`:** `0` → `'Agotado'`, `1` → `'Última unidad'`, `2..5` → `'Últimas $stock'`, más → `'Disponible'`.
  - **`StockNote(Product product)`:** `stockText` en `labelMedium`: en rojo si `stock <= 5`, si no en `onSurfaceVariant`.
  - **`PromoRibbon(List<ProductOffer> offers)`:** la etiqueta de la primera oferta (`'+ regalo'` para `gift`, como hoy en `OfferBadges`), en blanco sobre `primary`, en la esquina superior derecha con el borde inferior en V. Sin ofertas, `SizedBox.shrink()`.
  - **`LineTotalPill(int cents)`:** `formatSoles(cents)` en `money` sobre `moneyTint`, en píldora.
  - **`PriceTag`:**
    - sin el trazo;
    - el precio final con `NeilsText.price`: tinta, o `primary` si está en oferta;
    - el de lista tachado en `onSurfaceVariant`;
    - la insignia VIP como hoy.
  - **`ProductTile({required Product product, VoidCallback? onTap})`:** un `ConsumerStatefulWidget`. Su cantidad local arranca en la del carrito, o en 1. De izquierda a derecha:
    - foto de 88 × 88;
    - `'${product.sku} – ${product.name}'` en dos líneas como máximo, con "…";
    - `PriceTag` y `StockNote`;
    - debajo, `QuantityStepper` (máximo `maxQuantity`), `LineTotalPill(finalPriceCents * cantidad)` y el botón:
      - sin el producto en el carrito: `'Agregar'` (`FilledButton`, llama a `addToCart` con la cantidad);
      - con el producto en el carrito: `'Editar'` (`OutlinedButton` con ícono de lápiz, que fija esa cantidad en el carrito);
      - agotado: `'Agotado'`, deshabilitado.
    - `PromoRibbon` arriba a la derecha.
  - **`ProductCard({required Product product, VoidCallback? onTap})`:** los mismos elementos en columna: foto arriba con `PromoRibbon`, el código y el nombre, el precio y el stock, y la fila de cantidad, total y botón. Ya no recibe `onAdd`: agrega solo. Se actualizan sus usos en `catalog_screen.dart`, `product_strip.dart`, `exclusive_offers.dart` y `showcase_screen.dart`.

- [ ] **Step 1: Write the failing tests**

`product_tile_test.dart`, con `ProviderScope` y el carrito en memoria de `test/fakes.dart`:
- `'muestra el código y el nombre'`: `find.text('3580 – Jamonada especial')`.
- `'stockText avisa solo lo necesario'`: `stockText(0)`, `(1)`, `(3)` y `(40)` dan los cuatro textos. Además, `find.textContaining('40')` no encuentra nada en un tile con stock 40.
- `'el total de la línea sigue a la cantidad'`: precio S/ 4.40; tocar "+" dos veces → `find.text(formatSoles(1320))`.
- `'Agregar suma la cantidad al carrito'`: cantidad 3, tocar `'Agregar'` → `cart.quantityOf(id) == 3`.
- `'con el producto en el carrito dice Editar y su cantidad'`: el carrito tiene 2 → se ven `'Editar'` y `'2'`. Tocar "+" y `'Editar'` → `quantityOf == 3`.
- `'en el máximo el + se deshabilita'` (stock 2, carrito 2): el botón "+" tiene `onPressed == null`.
- `'agotado no se puede agregar'`: `'Agotado'` en un botón deshabilitado.
- `'la cinta muestra la promoción'`: con una oferta `2x1` → `find.text('2x1')` dentro de `PromoRibbon`.
- `'un nombre largo no se desborda en 360 px con texto al 130 %'` (Review Focus 1): `tester.view.physicalSize = Size(360, 800)`, `MediaQuery(textScaler: TextScaler.linear(1.3))`, nombre de 60 caracteres → `tester.takeException()` es null, y `'Agregar'` es visible (`hitTestable`).

`product_card_test.dart`: se actualiza a la tarjeta nueva, con los mismos casos de Agregar, Editar, Agotado y la cinta. Se borra el caso del trazo.

- [ ] **Step 2: Run them and see them fail**

Run: `flutter test --no-pub -r json test/features/product_tile_test.dart test/features/product_card_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement as in Interfaces**

- [ ] **Step 4: Run the tests, the catalog test and analyze**

Run: `flutter test --no-pub -r json test/features/product_tile_test.dart test/features/product_card_test.dart test/features/catalog_screen_test.dart test/features/exclusive_offers_test.dart`
Expected: PASS. Si `catalog_screen_test` busca el `onAdd` de antes, se actualiza aquí. `flutter analyze` → sin problemas.

- [ ] **Step 5: Commit**

```bash
git add apps/client/lib/features apps/client/test/features
git commit -m "feat(client): producto en lista y en tarjeta con cinta, total y Editar"
```

### Task 6: Barra fija del carrito

**Files:**
- Create: `apps/client/lib/features/shared/cart_bar.dart` (`CartBar`)
- Modify: `apps/client/lib/features/shared/brand.dart` (`PublicScaffold`: suma `showCartBar`)
- Modify: `apps/client/lib/features/cart/cart_screen.dart` (`_CheckoutBar` usa `CartBar`)
- Test: `apps/client/test/features/cart_bar_test.dart`, `apps/client/test/features/cart_screen_test.dart`

**Interfaces:**
- Consumes: `cartProvider` (`Cart.lines`, total estimado), `shownQuote`/`cartQuoteProvider` (el total cotizado, como hoy en el carrito), `Routes.cart`.
- Produces:
  - **`CartBar({required String label, required int totalCents, required VoidCallback? onPressed, int? count})`:** fondo `primary`, alto 64 con margen de 12 y radio 16. De izquierda a derecha:
    - el ícono del carrito con el número `count` en un círculo blanco;
    - `label`;
    - un divisor vertical;
    - `formatSoles(totalCents)`.

    Todo en blanco. Con `onPressed == null`, al 50 % de opacidad.
  - **`StoreCartBar()`** (`ConsumerWidget`): con el carrito vacío, `SizedBox.shrink()`. Si no, `CartBar(label: 'Continuar', count: <unidades>, totalCents: <total cotizado si hay, si no el estimado>, onPressed: () => context.go(Routes.cart))`.
  - **`PublicScaffold({..., bool showCartBar = true})`:**
    - en el teléfono (< 840 px), sin `bottomBar` propio y con `showCartBar`, pone `StoreCartBar` abajo;
    - le suma al contenido un relleno inferior igual al alto de la barra (88);
    - en escritorio, no.

    El carrito, el ingreso, el registro y Mi cuenta pasan `showCartBar: false`.
  - **`_CheckoutBar`:** `CartBar(label: 'Confirmar pedido', ...)`, con el mismo `onPressed` y las mismas reglas de habilitado de hoy.

- [ ] **Step 1: Write the failing tests**

- `'con el carrito vacío no hay barra'`.
- `'con productos muestra Continuar, la cantidad y el total, y lleva al carrito'` (390 × 844): 3 unidades a S/ 4.40 → `'Continuar'`, `'3'`, `formatSoles(1320)`. Al tocarla, la ruta es `/carrito`.
- `'en escritorio no hay barra'` (1280 × 900).
- `'el último producto queda visible sobre la barra'` (Review Focus 3): en el catálogo, con 10 productos, se hace scroll hasta el final → el rectángulo del último `ProductTile` termina por encima del borde superior de `CartBar`.
- En `cart_screen_test.dart`: la barra del teléfono dice `'Confirmar pedido'` y sigue confirmando; los casos que buscaban la barra vieja se actualizan.

- [ ] **Step 2: Run them and see them fail**

Run: `flutter test --no-pub -r json test/features/cart_bar_test.dart test/features/cart_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement**

- [ ] **Step 4: Run tests, checkout test and analyze**

Run: `flutter test --no-pub -r json test/features/cart_bar_test.dart test/features/cart_screen_test.dart test/features/checkout_test.dart` → PASS. `flutter analyze` → sin problemas.

- [ ] **Step 5: Commit**

```bash
git add apps/client/lib/features apps/client/test/features
git commit -m "feat(client): barra fija del carrito en la tienda"
```

### Task 7: Barra superior, menú de la tienda y "Promociones"

**Files:**
- Modify: `apps/client/lib/features/shared/brand.dart` (`PublicScaffold`: la barra nueva)
- Create: `apps/client/lib/features/shared/store_menu.dart` (`StoreMenu`)
- Create: `apps/client/lib/features/shared/store_search_field.dart` (`StoreSearchField`)
- Modify: `apps/client/lib/router/routes.dart` (`Routes.catalogOf(..., onSale)`, `Routes.promotions`)
- Modify: `apps/client/lib/router/router.dart` (lee `promos=1`)
- Modify: `apps/client/lib/catalog/catalog_providers.dart` (`CatalogQuery` suma `onSale`)
- Modify: `apps/client/lib/features/catalog/catalog_screen.dart` (`CatalogScreen(onSale)`, chip "En promoción")
- Test: `apps/client/test/features/account_bar_test.dart`, `test/router/router_test.dart`, `test/features/catalog_screen_test.dart`, `test/features/store_menu_test.dart`

**Interfaces:**
- Produces:
  - **`typedef CatalogQuery = ({String? categoryId, String? search, bool onSale})`:** `ProductListNotifier` pasa `onSale` al repositorio.
  - **`Routes.catalogOf(String? categoryId, {String? search, bool onSale = false})`:** con `onSale` suma `promos=1`.
  - **`Routes.promotions`** = `'/catalogo?promos=1'`.
  - **`CatalogScreen({String? categoryId, String? search, bool onSale = false})`:** el chip `'En promoción'` va después de `'Todas'` y antes de las categorías. Elegirlo lleva a `catalogOf(null, onSale: true)`. Elegir una categoría lo quita.
  - **`StoreSearchField({String? initial})`:** en forma de píldora, con el ícono de lupa y `'Buscar por código o nombre del producto…'`. Al enviar, `context.go(Routes.catalogOf(null, search: texto))`.
  - **Barra en escritorio (≥ 840):**
    - `NeilsLogo` (40);
    - los enlaces `'Inicio'`, `'Catálogo'` y `'Promociones'`. El activo, según la ruta, va en `primary` con un subrayado de 2 px;
    - `StoreSearchField` (ancho 280);
    - `'Mis pedidos'`, si hay cuenta;
    - `AccountActions`, o `'Ingresar'`;
    - `CartButton`.
  - **Barra en el teléfono:** a la izquierda, el botón de menú (`Icons.menu`, tooltip `'Menú'`) que abre `StoreMenu` como `Drawer`; al centro, `NeilsLogo` (32); a la derecha, `CartButton`.
  - **`StoreMenu`:**
    - arriba, el logo y, con cuenta, `'¡Hola, <nombre>!'`;
    - `'Inicio'`, `'Catálogo'`, `'Promociones'`, `'Mis pedidos'` y `'Mi cuenta'` (estos dos solo con cuenta);
    - `'Panel de la tienda'` (solo personal, como hoy en `AccountActions`);
    - `'Ingresar'` o `'Salir'`.

- [ ] **Step 1: Write the failing tests**

- `router_test`: `'/catalogo?promos=1 abre el catálogo en promoción'` → `CatalogScreen.onSale == true`. Y `Routes.catalogOf(null, onSale: true) == '/catalogo?promos=1'`.
- `catalog_screen_test`:
  - `'el chip En promoción pide solo los productos en promoción'`: el repositorio en memoria recibe `onSale: true`.
  - `'elegir una categoría quita En promoción'`.
- `account_bar_test`:
  - en escritorio, se ven `'Inicio'`, `'Catálogo'` y `'Promociones'`, y en la portada `'Inicio'` está activo (en `primary`);
  - el buscador lleva a `/catalogo?q=arroz`;
  - con cuenta, `'Mis pedidos'`;
  - los casos de hoy (Ingresar, menú de la cuenta) siguen.
- `store_menu_test`:
  - en el teléfono, el botón `'Menú'` abre el menú;
  - sin cuenta: `'Ingresar'`, y no `'Mis pedidos'`;
  - con cuenta: `'¡Hola, Ana!'`, `'Mis pedidos'` y `'Salir'`;
  - con personal: `'Panel de la tienda'`.

- [ ] **Step 2: Run them and see them fail**

Run: `flutter test --no-pub -r json test/router/router_test.dart test/features/catalog_screen_test.dart test/features/account_bar_test.dart test/features/store_menu_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement**

- [ ] **Step 4: Run tests, the route guard test and analyze**

Run: los mismos más `test/router/route_guard_test.dart` → PASS. `flutter analyze` → sin problemas.

- [ ] **Step 5: Commit**

```bash
git add apps/client/lib apps/client/test
git commit -m "feat(client): barra y menú de la tienda, y la sección Promociones"
```

### Task 8: Portada para negocios

**Files:**
- Modify: `apps/client/lib/features/home/home_screen.dart`
- Create: `apps/client/lib/features/catalog/category_card.dart` (`CategoryCard`)
- Create: `apps/client/lib/features/home/promotions_banner.dart` (`PromotionsBanner`)
- Modify: `apps/client/web/index.html` (`description`)
- Test: `apps/client/test/features/home_screen_test.dart`, `test/features/category_card_test.dart`

**Interfaces:**
- Consumes: `BrandHero`, `TrustBadges`, `DiagonalBand`, `BrandImages`, `ProductTile`, `ProductCard`, `StoreSearchField`, `categoriesProvider`, `onSaleProductsProvider`, `ExclusiveOffers`, `sessionProvider`.
- Produces:
  - **`CategoryCard({required Category category, required VoidCallback onTap})`:**
    - arriba, un bloque de 4:3 con el color de `PlaceholderColors.of(category.id)` y la inicial (el PR 2 le suma la foto);
    - abajo, el nombre en `titleSmall` y `Icons.arrow_forward` en `primary`;
    - tarjeta blanca con sombra.
  - **`PromotionsBanner()`:**
    - `DiagonalBand` (`BrandImages.promotionsBanner`) a la derecha y el texto a la izquierda sobre `primary`;
    - `'Promociones para tu negocio'` en blanco `headlineSmall`;
    - `'Soluciones prácticas para restaurantes, fast foods y dark kitchens.'`;
    - `OutlinedButton` blanco `'Ver promociones'` → `Routes.promotions`.
  - **Portada en escritorio (≥ 840):**
    - `BrandHero(titleStart: 'Tu negocio siempre abastecido ', titleAccent: "con Neil's.", body: 'Insumos gastronómicos de calidad, con precios competitivos y entrega confiable.', actions: [FilledButton 'Ver catálogo' → catálogo, OutlinedButton 'Ver promociones' → Routes.promotions], image: BrandImages.hero)`;
    - `TrustBadges`;
    - `'Nuestras categorías'`: una cuadrícula de `CategoryCard` con 4 columnas;
    - `PromotionsBanner`;
    - `'Promociones de hoy'` con `ProductCard`;
    - `ExclusiveOffers`.
  - **Portada en el teléfono:**
    - `'¡Hola, <primer nombre>!'` (sin cuenta, `'¡Hola!'`) y `'Abastece tu negocio con los mejores productos.'`, junto a una `DiagonalBand` chica;
    - `StoreSearchField`;
    - `'Promociones de hoy'` con `ProductTile` (el PR 2 lo convierte en pestañas);
    - `'Nuestras categorías'` en `CardStrip` con `CategoryCard` de 140 px;
    - `PromotionsBanner`;
    - `ExclusiveOffers`.
  - **Se borran:** el logo grande de la portada, `_Headline` y el texto de abarrotes. `PublicScaffold` vuelve a mostrar el logo en la barra de la portada (`showLogo` se elimina).
  - **`web/index.html`:** la `description` es la de la spec.

- [ ] **Step 1: Write the failing tests**

`home_screen_test.dart`, actualizado:
- `'escritorio: el titular para negocios y sus botones'`:
  - `find.textContaining('Tu negocio siempre abastecido')`, más `'Ver catálogo'` y `'Ver promociones'`;
  - `find.textContaining('abarrotes')` no encuentra nada;
  - tocar `'Ver promociones'` → `/catalogo?promos=1`.
- `'los tres sellos'`.
- `'Nuestras categorías lleva al catálogo de la categoría'`: tocar `'Lácteos'` → `/catalogo?categoria=<id>`.
- `'teléfono: saluda con el nombre de la cuenta'`: `'¡Hola, Ana!'`; sin cuenta, `'¡Hola!'`.
- `'Promociones de hoy en lista en el teléfono y en tarjetas en escritorio'`: `ProductTile` en 390 px, `ProductCard` en 1280 px.

`category_card_test.dart`: `'muestra el nombre, la inicial y la flecha, y se toca'`.

- [ ] **Step 2: Run them and see them fail**

Run: `flutter test --no-pub -r json test/features/home_screen_test.dart test/features/category_card_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement**

- [ ] **Step 4: Run tests and analyze**

Run: los mismos más `test/features/exclusive_offers_test.dart` → PASS. `flutter analyze` → sin problemas.

- [ ] **Step 5: Commit**

```bash
git add apps/client/lib apps/client/web/index.html apps/client/test
git commit -m "feat(client): portada para negocios con categorías y promociones"
```

### Task 9: Catálogo con encabezado de categoría y detalle del producto

**Files:**
- Create: `apps/client/lib/features/catalog/category_header.dart` (`CategoryHeader`)
- Modify: `apps/client/lib/features/catalog/catalog_screen.dart` (lista en el teléfono, cuadrícula en escritorio, encabezado, buscador en píldora)
- Modify: `apps/client/lib/features/catalog/product_detail_screen.dart` (`_stockText` se va y entra `StockNote`; código, cinta, cantidad, total, Agregar o Editar)
- Test: `apps/client/test/features/catalog_screen_test.dart`, `test/features/product_detail_test.dart` (nuevo)

**Interfaces:**
- Consumes: `ProductTile`, `ProductCard`, `StockNote`, `PromoRibbon`, `LineTotalPill`, `DiagonalBand`, `CategoryCard`.
- Produces:
  - **`CategoryHeader({required Category category})`:** el nombre en `headlineSmall` y, a la derecha, una `DiagonalBand` con el color de `PlaceholderColors.of(category.id)`. Alto 120 en el teléfono y 160 en escritorio. El PR 2 le suma la descripción y la foto.
  - **Catálogo:**
    - con `categoryId`, `CategoryHeader` arriba;
    - en el teléfono, la lista de `ProductTile` con divisores; desde 840, la cuadrícula de `ProductCard`;
    - "Ver más" y los mensajes de vacío y de error, como hoy.
  - **Detalle:**
    - la foto grande con `PromoRibbon`;
    - `'<sku> – <nombre>'`;
    - `PriceTag` grande y `StockNote`;
    - `OfferDescriptions`, como hoy;
    - la fila de cantidad, `LineTotalPill` y `'Agregar'` o `'Editar'`, que reutiliza la lógica de `ProductTile` con una pieza común: `ProductQuantityActions` en `product_tile.dart`;
    - `'Más de <categoría>'`.

- [ ] **Step 1: Write the failing tests**

- `catalog_screen_test`:
  - `'con una categoría elegida muestra su encabezado'`;
  - `'en el teléfono los productos van en lista'` (`ProductTile`);
  - `'en escritorio en cuadrícula'` (`ProductCard`).
- `product_detail_test`:
  - `'el detalle no muestra las unidades en stock'`: stock 40 → `'Disponible'`, sin `'40'`;
  - stock 3 → `'Últimas 3'`;
  - `'con el producto en el carrito dice Editar'`;
  - `'muestra el código antes del nombre'`.

- [ ] **Step 2: Run them and see them fail**

Run: `flutter test --no-pub -r json test/features/catalog_screen_test.dart test/features/product_detail_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement**

`ProductQuantityActions({required Product product})` saca de `ProductTile` la fila de cantidad, total y botón. `ProductTile`, `ProductCard` y el detalle la usan.

- [ ] **Step 4: Run tests and analyze**

Run: los mismos más `test/features/product_tile_test.dart test/features/product_card_test.dart` → PASS. `flutter analyze` → sin problemas.

- [ ] **Step 5: Commit**

```bash
git add apps/client/lib apps/client/test
git commit -m "feat(client): catálogo con encabezado de categoría y detalle renovado"
```

### Task 10: Carrito con el estilo nuevo

**Files:**
- Modify: `apps/client/lib/features/cart/cart_screen.dart` (`_CartLineTile`, `_GiftLine`, `_QuoteNotice`, `_Total`, `_Checkout`)
- Test: `apps/client/test/features/cart_screen_test.dart`

**Interfaces:**
- Consumes: `ProductPhoto`, `PriceTag`, `LineTotalPill`, `QuantityStepper`, `PromoRibbon`, `OfferBadges`.
- Produces:
  - **Cada línea:**
    - en una tarjeta blanca: foto de 72, `'<sku> – <nombre>'`, `PriceTag` unitario;
    - abajo, `QuantityStepper`, `LineTotalPill` con el total cotizado de la línea (o el estimado), y quitar (`Icons.delete_outline`, tooltip `'Quitar'`, como hoy);
    - las ofertas aplicadas, con `OfferBadges`, como hoy.
  - **Los regalos:** una línea con la cinta `'Regalo'` y `'S/ 0.00'` en la pastilla.
  - **Los avisos y el total:** en tarjetas con el estilo nuevo.
  - **Sin cambios:** el flujo, los textos de los avisos y las reglas de habilitado.

- [ ] **Step 1: Write the failing tests**

En `cart_screen_test`:
- `'cada línea muestra el código, la pastilla con su total y Quitar'`;
- `'el regalo va con su cinta y S/ 0.00'`.

Los casos de hoy (cotización, avisos, confirmar, recojo) siguen pasando.

- [ ] **Step 2: Run them and see them fail**

Run: `flutter test --no-pub -r json test/features/cart_screen_test.dart`
Expected: FAIL en los dos nuevos.

- [ ] **Step 3: Implement**

- [ ] **Step 4: Run tests and analyze**

Run: `flutter test --no-pub -r json test/features/cart_screen_test.dart test/features/checkout_test.dart test/cart` → PASS. `flutter analyze` → sin problemas.

- [ ] **Step 5: Commit**

```bash
git add apps/client/lib/features/cart apps/client/test/features/cart_screen_test.dart
git commit -m "feat(client): carrito con el estilo de la nueva marca"
```

### Task 11: Ingresar y Crear cuenta con el panel rojo

**Files:**
- Modify: `apps/client/lib/features/auth/auth_form.dart` (`_BrandPanel`, `EmailField`, `PasswordField`, el diseño del teléfono)
- Modify: `apps/client/lib/features/auth/register_screen.dart` (íconos de los campos)
- Test: `apps/client/test/features/auth_screens_test.dart`, `test/features/register_test.dart`

**Interfaces:**
- Produces:
  - **`_BrandPanel`:**
    - fondo `primary` y radio 20;
    - `NeilsLogo.white(height: 96)`;
    - `'Tu abastecimiento gastronómico, más fácil.'` en blanco `headlineSmall`;
    - los tres beneficios con ícono blanco: `'Precios y promociones exclusivas'` (`sell_outlined`), `'Entrega a tu negocio'` (`local_shipping_outlined`) y `'Sigue tus pedidos'` (`inventory_2_outlined`).
  - **Teléfono (< 900, `AuthForm.twoColumnsFrom`):** arriba una franja `primary` de alto 120 con `NeilsLogo.white(height: 56)` y la esquina inferior en diagonal (`DiagonalBand`); debajo el formulario.
  - **Íconos de los campos:** nombre `person_outline`, correo `mail_outline`, contraseña `lock_outline`, celular `phone_outlined`, DNI `badge_outlined`.
  - **Sin cambios:** las validaciones, los textos de error y el flujo.

- [ ] **Step 1: Write the failing tests**

- `auth_screens_test`:
  - `'escritorio: el panel rojo con el lema para negocios'`: `'Tu abastecimiento gastronómico, más fácil.'` y los tres beneficios;
  - `find.text('Tus abarrotes, a la puerta de tu casa')` no encuentra nada;
  - `'teléfono: la franja con el logo blanco'`: `NeilsLogo.white` presente y el formulario visible.
- `register_test`: `'los campos llevan su ícono'` (`Icons.mail_outline` dentro del campo de correo).

- [ ] **Step 2: Run them and see them fail**

Run: `flutter test --no-pub -r json test/features/auth_screens_test.dart test/features/register_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement**

- [ ] **Step 4: Run tests and analyze**

Run: los mismos más `test/features/password_reset_test.dart test/features/verify_email_test.dart` → PASS. `flutter analyze` → sin problemas.

- [ ] **Step 5: Commit**

```bash
git add apps/client/lib/features/auth apps/client/test/features
git commit -m "feat(client): ingreso y registro con el panel rojo de la marca"
```

### Task 12: El panel: barra, menú ancho, saludo e indicadores

**Files:**
- Modify: `apps/client/lib/features/admin/admin_shell.dart`
- Create: `apps/client/lib/features/admin/home/kpi_card.dart` (`KpiCard`)
- Create: `apps/client/lib/features/admin/home/greeting.dart` (`greetingFor`, `PanelGreeting`)
- Modify: `apps/client/lib/features/admin/home/home_cards.dart` (`KpiSection` usa `KpiCard`)
- Modify: `apps/client/lib/features/admin/admin_home_screen.dart` (el saludo arriba)
- Modify: `apps/client/lib/features/admin/shared/admin_form.dart` (`FormActions` alineado a la derecha, si no lo está) y `admin_table.dart` (encabezado sobre `surfaceContainerLow`)
- Test: `apps/client/test/admin/admin_shell_test.dart`, `test/admin/admin_home_test.dart`, `test/admin/greeting_test.dart`

**Interfaces:**
- Produces:
  - **`String greetingFor(DateTime utc)`:** a la hora de Lima (UTC−5, sin horario de verano), `< 12` → `'Buenos días'`, `< 19` → `'Buenas tardes'`, si no `'Buenas noches'`.
  - **`PanelGreeting()`:**
    - `'<saludo>, <primer nombre>!'` en `headlineSmall`, con el "¡" adelante;
    - debajo, la fecha de `MaterialLocalizations.formatFullDate` con la primera letra en mayúscula ("Miércoles, 5 de noviembre de 2026"), con `Icons.calendar_today_outlined`.
  - **`KpiCard({required IconData icon, required String title, required String value, String? detail})`:** tarjeta blanca; el ícono en `primary` sobre `primaryTint`; el título en `labelLarge`; `value` en Poppins 700 tamaño 24 en `primary`; `detail` en `bodySmall`.

    La spec habla de "una barra": no entra, porque las cifras de hoy (ventas de hoy, semana y mes, ticket promedio) no tienen un 100 % contra el cual medir. Los íconos: `point_of_sale_outlined`, `date_range_outlined`, `calendar_month_outlined`, `receipt_long_outlined`.
  - **`AdminShell`:**
    - barra blanca (`surfaceContainerLowest`) con una sombra fina abajo;
    - `NeilsLogo` y `'Panel de la tienda'`, `'Ir a la tienda'` y la cuenta, como hoy;
    - desde 1200 px, `NavigationRail(extended: true, minExtendedWidth: 220)`. Entre 840 y 1200, el angosto de hoy;
    - el destino activo con indicador `primaryTint` y el texto e ícono en `primaryDark`.

- [ ] **Step 1: Write the failing tests**

- `greeting_test`:
  - `greetingFor(DateTime.utc(2026, 11, 5, 14))` (9:00 en Lima) → `'Buenos días'`;
  - `(…, 20)` (15:00) → `'Buenas tardes'`;
  - `(…, 2)` (21:00 del día anterior) → `'Buenas noches'`.
- `admin_home_test`:
  - `'el inicio saluda con el nombre'`: `find.textContaining('Ana!')`;
  - `'las cifras van en KpiCard'`: 4 `KpiCard`, con `'Ventas de hoy'` y su monto.
- `admin_shell_test`:
  - `'desde 1200 px el menú lleva los textos al lado'`: `NavigationRail.extended == true` a 1280;
  - a 1000 px, `extended == false` y `labelType == all`;
  - los casos de hoy siguen.

- [ ] **Step 2: Run them and see them fail**

Run: `flutter test --no-pub -r json test/admin/greeting_test.dart test/admin/admin_home_test.dart test/admin/admin_shell_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement**

- [ ] **Step 4: Run the whole admin folder and analyze**

Run: `flutter test --no-pub -r json test/admin` (con reintentos) → PASS. `flutter analyze` → sin problemas.

- [ ] **Step 5: Commit**

```bash
git add apps/client/lib/features/admin apps/client/test/admin
git commit -m "feat(client): panel con menú ancho, saludo e indicadores"
```

### Task 13: El resto de las pantallas, vitrina, capturas y documentación del PR 1

**Files:**
- Modify, si las capturas muestran algo fuera de la marca: `lib/features/orders/*`, `lib/features/account/*`, `lib/features/offers/exclusive_offers.dart`, `lib/features/admin/**`
- Modify: `apps/client/lib/features/showcase/showcase_screen.dart` (las piezas nuevas: `ProductTile`, `ProductCard`, `PromoRibbon`, `StockNote`, `CartBar`, `CategoryCard`, `CategoryHeader`, `BrandHero`, `TrustBadges`, `PromotionsBanner`, `KpiCard`)
- Create (temporal, fuera de git): `apps/client/test_capturas/nueva_marca_test.dart`
- Modify: `apps/client/README.md` (tema, fuentes, logo y su generador, `BrandImages`), `docs/ARQUITECTURA_Y_ROADMAP.md` (la marca), `docs/DEMO.md` (la portada nueva)

- [ ] **Step 1: Capturas**

Goldens en teléfono (390 × 844) y escritorio (1280 × 800), con `useBundledFonts`, los repositorios en memoria y fotos de producto en blanco. Salen a `capturas/nueva-marca/`:
- portada sin cuenta y con cuenta;
- catálogo, catálogo con categoría y "En promoción";
- detalle;
- carrito con regalos;
- ingresar y crear cuenta;
- Mis pedidos, Mi cuenta y Mis códigos;
- panel: inicio, pedidos, productos, el formulario de producto, promociones y tienda;
- vitrina.

Mirar cada captura con Read. Cada problema de marca que se vea (un naranja que quedó, texto sin contraste, algo que se desborda) se arregla con su test, si el arreglo cambia el comportamiento, y vuelve a la captura.

- [ ] **Step 2: Buscar restos de la marca vieja**

Run, desde `apps/client`, `grep -rn "E8652F\|B54F25\|F9F3E7\|baloo\|Baloo\|swoosh\|Swoosh\|abarrotes, a la puerta" lib web test`
Expected: nada. `Abarrotes` como nombre de una categoría de ejemplo en los tests está bien.

- [ ] **Step 3: Documentación**

- `README` de la app: la sección del tema con la tabla de tokens, las fuentes y el generador (`flutter test tool/brand_assets_test.dart`). Cómo activar una foto en `BrandImages`.
- `ARQUITECTURA_Y_ROADMAP.md`: la identidad nueva y lo que queda pendiente del cliente (logo original, fotos).
- `DEMO.md`: el recorrido por la portada nueva.

- [ ] **Step 4: Suite completa y analyze**

Run: `flutter analyze` → sin problemas. `flutter test --no-pub -r json` con reintentos → todos pasan. Anotar el número de tests.

- [ ] **Step 5: Commit**

```bash
git add apps/client docs/ARQUITECTURA_Y_ROADMAP.md docs/DEMO.md
git commit -m "docs: la nueva marca en la app, la vitrina y la guía de la demo"
```

---

## PR 2 · `feature/frecuentes-y-categorias`

### Task 14: Fotos y descripción de categorías (servidor)

**Files:**
- Create: `apps/server/abarrotes_server/lib/src/common/photos.dart` (`Photos`)
- Modify: `apps/server/abarrotes_server/lib/src/products/product_images.dart` (usa `Photos`; su API pública no cambia)
- Create: `apps/server/abarrotes_server/lib/src/categories/category_images.dart` (`CategoryImages`)
- Modify: `apps/server/abarrotes_server/lib/src/categories/category.spy.yaml`, `categories_service.dart`, `categories_routes.dart`
- Create: migración `migrations/<ts>-fotos-de-categorias/`
- Modify: `apps/server/abarrotes_server/lib/src/dev/dev_seed.dart` (descripciones de ejemplo)
- Modify: `apps/server/abarrotes_server/test/unit/auth/route_permissions_test.dart`, `apps/server/README.md`
- Test: `apps/server/abarrotes_server/test/integration/categories_routes_test.dart`, `test/integration/products_routes_test.dart` (las fotos de productos siguen igual)

**Interfaces:**
- Produces:
  - **`class Photos`** (`common/photos.dart`):
    - `Photos({required String urlPrefix, required int maxSide, Random? random})`;
    - `static const storageId = 'public'`, `maxUploadBytes = 8 MB`, `maxPixels = 40 MP`, `jpegQuality = 82`;
    - `Uint8List process(Uint8List bytes)`: lo de hoy de `ProductImages.process`, con `maxSide` del objeto;
    - `bool isStored(String? url)`;
    - `Future<String> store(Session session, String ownerId, Uint8List jpeg)`: guarda y devuelve la URL relativa;
    - `Future<Uint8List?> read(Session session, String ownerId, String file)`;
    - `Future<void> delete(Session session, String url)`;
    - más una función de primer nivel `Future<Uint8List> readPhotoBody(Request request)`, que sale de `_readPhoto` de `products_routes.dart`.
  - **`ProductImages`:** envuelve `Photos(urlPrefix: '/images/products/', maxSide: 800)`.
  - **`CategoryImages`:** envuelve `Photos(urlPrefix: '/images/categories/', maxSide: 1200)`.
  - **`Category`** suma `imageUrl: String?` y `description: String?`.
  - **`CategoriesService`:**
    - `create(session, String name, {String? description})`;
    - `update(session, id, String? name, {String? description, bool clearDescription = false})`;
    - `setImage(session, id, Uint8List photo)`, que borra la foto anterior si era de aquí;
    - `image(session, categoryId, file)`.
  - **Rutas:**
    - `PUT /categories/:id/image` (`categories.manage`): 200 con `categoryJson`;
    - `GET /images/categories/:categoryId/:file`: pública, `Cache-Control: public, max-age=31536000, immutable`, y 404 si no existe;
    - `POST` y `PATCH /categories` aceptan `description`: texto de hasta 80 caracteres. Vacío o `null` en el PATCH la borran.
  - **`categoryJson`:** `{id, name, description, imageUrl}`.

- [ ] **Step 1: Write the failing tests**

`categories_routes_test.dart`, grupo `'foto y descripción'`:
- `'crea con descripción y la devuelve'`: `POST {name: 'Embutidos', description: 'Hot dogs, jamonadas y más'}` → 201 con esa `description` e `imageUrl == null`.
- `'la descripción tiene hasta 80 caracteres'`: 81 → 400 con `'description debe tener como máximo 80 caracteres'`, el mensaje que da `InputReader.text` con `maxLength: 80`; si el texto real difiere, el test usa el real.
- `'PATCH con description vacía la borra'`.
- `'sube una foto y la sirve'`: PUT con un PNG de 2000 × 1000 → 200, `imageUrl` empieza con `/images/categories/<id>/`. Un GET a esa URL → 200, `image/jpeg`, ancho 1200, y la cabecera de caché.
- `'reemplazar la foto borra la anterior'`: la URL vieja da 404.
- `'no es una imagen'` → 400 `'La foto tiene que ser una imagen JPEG, PNG o WebP'`.
- `'sin categories.manage'` → 403.

`route_permissions_test.dart`: `'PUT /categories/:id/image': 'categories.manage'` y `'GET /images/categories/:categoryId/:file': 'pública'`.

`products_routes_test.dart`: los tests de fotos de hoy no cambian y tienen que seguir pasando.

- [ ] **Step 2: Run them and see them fail**

Run: `dart test test/integration/categories_routes_test.dart test/unit/auth/route_permissions_test.dart`
Expected: FAIL.

- [ ] **Step 3: Model, generate and migration**

1. Crear la rama:
   ```bash
   git switch -c feature/frecuentes-y-categorias feature/nueva-marca
   ```
2. Editar `category.spy.yaml`.
3. `generate`, `create-migration --tag fotos-de-categorias`, aplicar y revisar con psql que `categories` tiene `imageUrl` y `description`.

- [ ] **Step 4: Implement `Photos`, the service, the routes and the seed**

El seed pone una descripción a cada categoría de ejemplo, p. ej. "Lácteos": `'Leches, yogures y derivados'`.

- [ ] **Step 5: Run the tests**

Run: `dart test test/integration/categories_routes_test.dart test/integration/products_routes_test.dart test/unit/auth/route_permissions_test.dart test/integration/dev_seed_test.dart` → PASS. `dart analyze --fatal-infos` → sin problemas.

- [ ] **Step 6: Commit (con el README del servidor)**

```bash
git add apps/server/abarrotes_server apps/server/README.md
git commit -m "feat(server): fotos y descripción de las categorías"
```

### Task 15: Frecuentes y Sugeridos (servidor)

**Files:**
- Modify: `apps/server/abarrotes_server/lib/src/products/products_service.dart` (`frequent`, `suggested`)
- Modify: `apps/server/abarrotes_server/lib/src/products/products_routes.dart` (las dos rutas, antes de `/products/:id`)
- Modify: `apps/server/abarrotes_server/test/unit/auth/route_permissions_test.dart`, `apps/server/README.md`
- Test: `apps/server/abarrotes_server/test/integration/products_suggestions_test.dart` (nuevo)

**Interfaces:**
- Consumes: `request.currentUser` en las rutas `signedIn`; `optionalIdentity` y `User.db.findFirstRow(firebaseUid)`, como en `/orders/quote`; `ShopperResolver`; `_include(now, shopper)`.
- Produces:
  - **`Future<List<Product>> frequent(Session session, {required UuidValue customerId, Shopper shopper = Shopper.anonymous, int limit = 20})`.**
  - **`Future<List<Product>> suggested(Session session, {UuidValue? customerId, Shopper shopper = Shopper.anonymous, int limit = 20})`.**
  - Las dos sacan los ids en orden con `session.db.unsafeQuery`, como `TopProductsReportProvider`, y después cargan los productos con `Product.db.find(where: id.inSet(ids), include: _include(now, shopper))`, respetando el orden de la consulta.
  - **SQL de `frequent`:**
    ```sql
    SELECT oi."productId"::text AS id
    FROM order_items oi
    JOIN orders o ON o.id = oi."orderId"
    JOIN products p ON p.id = oi."productId"
    WHERE o."customerId" = @customer AND o.status <> 'cancelled'
      AND o."createdAt" >= @since AND NOT oi."isGift" AND p.active
    GROUP BY oi."productId", p.name
    ORDER BY COUNT(DISTINCT o.id) DESC, MAX(o."createdAt") DESC, p.name
    LIMIT @limit
    ```
    Con `since = now − 180 días`.
  - **SQL de `suggested`:**
    - lo mismo sin el filtro de cliente;
    - `since = now − 30 días`;
    - `p.active AND p."currentStock" > 0`;
    - `ORDER BY SUM(oi.quantity) DESC, p.name`;
    - con `customerId`, además `AND oi."productId" NOT IN (<los ids de frequent de ese cliente>)`, pasados como `@exclude::uuid[]`.
  - **Rutas:**
    - `GET /products/frequent` (`signedIn`) → `{'items': [productJson…]}`;
    - `GET /products/suggested` (pública; con un token válido, su shopper y su `customerId`) → `{'items': [...]}`.
    - Ninguna acepta parámetros (`InputReader.query(request, allowed: {})`).

- [ ] **Step 1: Write the failing tests**

En `products_suggestions_test.dart`, con pedidos creados por la base de los tests, como en `stats_routes_test`:
- `'Frecuentes ordena por cantidad de pedidos'`: arroz en 3 pedidos, leche en 1 → `[arroz, leche]`.
- `'a igual cantidad de pedidos, primero el más reciente'`.
- `'Frecuentes no cuenta cancelados, regalos, dados de baja ni pedidos de hace más de 180 días'`.
- `'Frecuentes no mezcla los pedidos de otro cliente'`.
- `'Frecuentes sin cuenta da 401'`.
- `'Sugeridos son los más vendidos de 30 días, con stock'`: un agotado no sale.
- `'con cuenta, Sugeridos no repite sus Frecuentes'`.
- `'trae el precio con la promoción del cliente'`: un VIP ve `unitPrice` con su promoción VIP en las dos listas.
- `'hasta 20'`.

`route_permissions_test`: `'GET /products/frequent': 'cuenta'` y `'GET /products/suggested': 'pública'`.

- [ ] **Step 2: Run them and see them fail**

Run: `dart test test/integration/products_suggestions_test.dart test/unit/auth/route_permissions_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement**

- [ ] **Step 4: Run the tests**

Run: `dart test test/integration/products_suggestions_test.dart test/integration/products_routes_test.dart test/unit/auth/route_permissions_test.dart` → PASS. `dart analyze --fatal-infos` → sin problemas.

- [ ] **Step 5: Commit (con el README del servidor)**

```bash
git add apps/server/abarrotes_server apps/server/README.md
git commit -m "feat(server): productos frecuentes y sugeridos"
```

### Task 16: Categorías con foto en la tienda y sección "Categorías" del panel

**Files:**
- Modify: `apps/client/lib/catalog/category.dart` (`imageUrl`, `description`)
- Create: `apps/client/lib/features/catalog/category_photo.dart` (`CategoryPhoto`)
- Modify: `apps/client/lib/features/catalog/category_card.dart`, `category_header.dart`
- Create: `apps/client/lib/admin/categories/admin_categories_repository.dart` (interfaz y HTTP), `admin_categories_providers.dart`
- Create: `apps/client/lib/features/admin/categories/admin_categories_screen.dart`, `category_form.dart`
- Modify: `apps/client/lib/router/routes.dart` (`Routes.adminCategories = '/admin/categorias'`, en `panelSections` después de `adminProducts`, con `_panelPermissions` en `{StaffPermission.categoriesManage}`), `router.dart`, `apps/client/lib/features/admin/admin_shell.dart` (`AdminSection.categories`: `Icons.category_outlined` y `Icons.category`, `'Categorías'`)
- Modify: `apps/client/test/fakes.dart` (`FakeAdminCategoriesRepository`; las categorías de ejemplo con descripción)
- Test: `apps/client/test/admin/admin_categories_test.dart`, `test/features/category_card_test.dart`, `test/catalog/http_catalog_repository_test.dart`

**Interfaces:**
- Consumes: el JSON `{id, name, description, imageUrl}` del Task 14. La URL relativa se completa con `apiBaseUrl`, como hoy en `ProductPhoto`.
- Produces:
  - **`Category({required String id, required String name, String? description, String? imageUrl})`:** `fromJson` acepta que falten `description` e `imageUrl`.
  - **`CategoryPhoto({required Category category, double? height})`:** la foto (`Image.network`, `BoxFit.cover`). Sin foto, o si falla (`errorBuilder`), el color de `PlaceholderColors.of(id)` con la inicial.
  - **`CategoryCard` y `CategoryHeader`:** usan `CategoryPhoto`. El encabezado muestra `description` debajo del nombre si la hay.
  - **`abstract interface class AdminCategoriesRepository`:**
    - `Future<List<AdminCategory>> list()`, con `productCount`. Si `/categories` no lo trae, se cuenta con `/products?categoryId=&pageSize=1` y su `total`. Antes de decidir, mirar qué devuelve hoy `/categories`;
    - `create(name, {description})`;
    - `update(id, {name, description})`;
    - `uploadImage(id, bytes, {contentType})`;
    - `delete(id)`.
  - **Pantalla `AdminCategoriesScreen`:**
    - `AdminTable` con foto (48), nombre, descripción y productos;
    - el botón `'Nueva categoría'`;
    - al tocar una fila, el formulario: nombre, descripción (contador /80) y la foto con `image_picker` (`'Cambiar foto'`, como en productos);
    - `'Borrar'` con confirmación. El 409 del servidor se muestra en el formulario.

- [ ] **Step 1: Write the failing tests**

- `http_catalog_repository_test`: `'lee la descripción y la foto de una categoría'`.
- `category_card_test`:
  - `'con foto usa la foto'`;
  - `'si la foto falla vuelve al color y la inicial'` (Review Focus 5): un `Image.network` que da error → se ve la inicial y `tester.takeException()` es null.
- `admin_categories_test`:
  - `'lista las categorías con su cantidad de productos'`;
  - `'crea una categoría con descripción'`;
  - `'la descripción tiene hasta 80'`: 81 caracteres → el mensaje del campo, sin llamar al repositorio;
  - `'sube la foto'`;
  - `'borrar una con productos muestra el aviso del servidor'`;
  - `'sin categories.manage no aparece en el menú'`.

- [ ] **Step 2: Run them and see them fail**

Run: `flutter test --no-pub -r json test/admin/admin_categories_test.dart test/features/category_card_test.dart test/catalog/http_catalog_repository_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement**

- [ ] **Step 4: Run the tests and analyze**

Run: los mismos más `test/admin/admin_shell_test.dart test/admin/admin_access_test.dart test/router` → PASS. `flutter analyze` → sin problemas.

- [ ] **Step 5: Commit (con el README de la app)**

```bash
git add apps/client
git commit -m "feat(client): fotos de categorías y sección Categorías del panel"
```

### Task 17: Pestañas Frecuentes, Sugeridos y Promos en la portada

**Files:**
- Modify: `apps/client/lib/catalog/catalog_repository.dart`, `http_catalog_repository.dart` (`frequent()`, `suggested()`)
- Modify: `apps/client/lib/catalog/catalog_providers.dart` (`frequentProductsProvider`, `suggestedProductsProvider`)
- Create: `apps/client/lib/features/home/product_tabs.dart` (`ProductTabs`)
- Modify: `apps/client/lib/features/home/home_screen.dart` (`'Promociones de hoy'` pasa a ser `ProductTabs`)
- Modify: `apps/client/test/fakes.dart` (el repositorio en memoria suma las dos listas)
- Test: `apps/client/test/catalog/http_catalog_repository_test.dart`, `test/features/home_screen_test.dart`, `test/features/product_tabs_test.dart`

**Interfaces:**
- Produces:
  - **`CatalogRepository`:**
    - `Future<List<Product>> frequent()`: `GET /products/frequent`, con token;
    - `Future<List<Product>> suggested()`: `GET /products/suggested`, con el token si hay.
  - **`frequentProductsProvider`:** `FutureProvider.autoDispose<List<Product>>`. Sin cuenta, `[]` sin llamar al servidor. Vigila `isVipProvider` y la cuenta.
  - **`suggestedProductsProvider`:** igual, siempre llama.
  - **`ProductTabs()`:** `ConsumerStatefulWidget`.
    - **Pestañas** en forma de píldora: `'Frecuentes'` (`Icons.shopping_cart_outlined`, solo con cuenta), `'Sugeridos'` (`Icons.star_outline`) y `'Promos'` (`Icons.local_offer_outlined`). Elegida, en `primary` con texto blanco.
    - **Pestaña inicial:** `'Frecuentes'` si hay cuenta y su lista no está vacía al cargar; si no, `'Sugeridos'`. Mientras carga, `'Sugeridos'`. Una vez que el usuario elige una, no se cambia sola.
    - **Contenido:** en el teléfono, `ProductTile` en lista; en escritorio, `ProductCard` en cuadrícula. Hasta 8, con `'Ver más'`: en Promos lleva a `Routes.promotions`; en las otras abre la lista completa (20) en la misma pestaña.
    - **Frecuentes vacía:** `'Cuando hagas tu primer pedido, aquí verás lo que más pides.'`.
    - **Error:** `ErrorMessage` con `'Reintentar'`.

- [ ] **Step 1: Write the failing tests**

- `http_catalog_repository_test`: `'frequent y suggested piden su ruta con el token'`.
- `product_tabs_test`:
  - `'sin cuenta no hay Frecuentes y arranca en Sugeridos'`;
  - `'con pedidos arranca en Frecuentes'`;
  - `'un cliente sin pedidos ve Sugeridos y el texto vacío al tocar Frecuentes'` (Review Focus 4);
  - `'Promos muestra los productos en promoción'`;
  - `'Ver más en Promos lleva a /catalogo?promos=1'`;
  - `'si falla, Reintentar vuelve a pedir'`.
- `home_screen_test`: `'la portada muestra las tres pestañas con cuenta'`.

- [ ] **Step 2: Run them and see them fail**

Run: `flutter test --no-pub -r json test/catalog/http_catalog_repository_test.dart test/features/product_tabs_test.dart test/features/home_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement**

- [ ] **Step 4: Run the tests and analyze**

Run: los mismos → PASS. `flutter analyze` → sin problemas.

- [ ] **Step 5: Commit (con el README de la app)**

```bash
git add apps/client
git commit -m "feat(client): pestañas Frecuentes, Sugeridos y Promos en la portada"
```

### Task 18: Verificación final del PR 2

**Files:**
- Modify: `docs/ARQUITECTURA_Y_ROADMAP.md` (Frecuentes y Sugeridos, fotos de categorías), `docs/DEMO.md` (la portada con pestañas y la sección "Categorías")
- Create (temporal, fuera de git): capturas de la portada con pestañas y de "Categorías" en `capturas/nueva-marca/`

- [ ] **Step 1: Servidor**

Run, desde `apps/server/abarrotes_server`: `dart analyze --fatal-infos` y `dart test`.
Expected: todo pasa. Anotar el número de tests.

- [ ] **Step 2: Migración en la base de desarrollo**

Aplicar y revisar con psql las columnas de `categories`. Correr `dart run bin/seed_dev.dart --reiniciar` solo si el usuario lo pide: rehace los datos de ejemplo.

- [ ] **Step 3: App**

`flutter analyze` → sin problemas. `flutter test --no-pub -r json` con reintentos → todo pasa. Anotar el número de tests.

- [ ] **Step 4: Capturas**

La portada con pestañas, en teléfono y en escritorio, con cuenta y sin cuenta; el catálogo con el encabezado con foto; "Categorías" y su formulario. Mirarlas con Read.

- [ ] **Step 5: Documentation and commit**

```bash
git add docs/ARQUITECTURA_Y_ROADMAP.md docs/DEMO.md
git commit -m "docs: Frecuentes, Sugeridos y fotos de categorías"
```

- [ ] **Step 6: Revisión final de las dos ramas**

Según la skill de ejecución: un revisor nuevo sobre cada rama (`feature/codigos-promocionales..feature/nueva-marca` y `feature/nueva-marca..feature/frecuentes-y-categorias`). Los hallazgos Critical e Important se arreglan con un test que falla primero y la suite completa en verde.
