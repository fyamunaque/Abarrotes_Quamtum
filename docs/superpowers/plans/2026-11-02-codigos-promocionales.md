# Tipos de promoción y códigos promocionales: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sumar cuatro tipos de promoción (%, NxM, unidad extra, regalo) que se acumulan con un cobro por línea, y códigos promocionales que el cliente activa en su cuenta para desbloquear promociones por un tiempo y una cantidad de pedidos.

**Architecture:** Un motor de cobro puro en `promotions/` calcula cada línea (precio, descuentos, regalos) y lo usan `POST /orders`, `POST /orders/quote` y el catálogo a través de `PromotionPricing`. Un dominio nuevo, `promo_codes/`, guarda códigos, canjes y usos, y le pasa a `promotions` los canjes vigentes por la interfaz `CodeBenefits`. La app suma el formulario por tipo, el carrito con cotización real, y los códigos en el panel y en "Mi cuenta".

**Tech Stack:** Serverpod 4 (Dart) + PostgreSQL; Flutter con Riverpod y go_router.

**Spec:** `docs/superpowers/specs/2026-11-02-codigos-promocionales-design.md`

## Global Constraints

- Rama `feature/codigos-promocionales`. Commits Conventional Commits en español, cada uno terminado en `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Sin push, sin PR, sin APK.
- Montos en céntimos enteros (`...Cents`) y como texto en el JSON (`"4.5"`, con `formatMoney`). Días de la tienda como `AAAA-MM-DD` (`toStoredPeriod`/`toDayPeriod`).
- Cada ruta nueva: `guards.require(Permission.x, …)` (o `signedIn`/pública según la tabla) y su fila en `test/unit/auth/route_permissions_test.dart`. Se registran con `addRoutes` en `lib/server.dart`.
- Nada se edita en `lib/src/generated/` ni en `abarrotes_client`: después de tocar un `.spy.yaml`, `dart pub global run serverpod_cli generate` (con `C:\Users\aligh\develop\flutter\bin` en el PATH) y `create-migration --tag <tag>`; se aplica con `dart run bin/main.dart --role maintenance --apply-migrations` y se revisa con `psql` (la contraseña se lee de `config/passwords.yaml` dentro del comando y nunca se imprime).
- Ningún dominio importa la lógica de otro: `promo_codes` implementa una interfaz de `promotions` (`CodeBenefits`); `orders` solo conoce `PromotionPricing`. El modelo `Order`/`OrderItem` y los generados se comparten.
- La documentación va en el mismo commit que el cambio: `apps/server/README.md`, `apps/client/README.md`, `docs/ARQUITECTURA_Y_ROADMAP.md`.
- App: Riverpod (nada de `setState` para datos compartidos), go_router (paths en `router/routes.dart`, permisos en `router/route_guard.dart`/`Routes._panelPermissions`), HTTP solo detrás de repositorios con interfaz + implementación + provider, colores solo desde `lib/theme/`.
- Los estados de pedido no cambian.
- Tests del servidor: `dart test <archivo>` con el Dart de Flutter, desde `apps/server/abarrotes_server`. Tests de la app: `flutter test --no-pub -r json <archivo>` desde `apps/client`; si `flutter_tester` se cae (tests que no terminan sin assert fallido), se reintenta el archivo y, si sigue, test por test con `--plain-name`.
- Textos de UI en español; nombres de código en inglés.

## Review Focus

1. **Cantidad que no completa un grupo** (1 unidad con un 2x1, 3 con un 2.ª al 50 % … ) → se cobra sin ese descuento, sin error. Test en Task 2.
2. **El precio cambia entre la cotización y el pedido** (alguien edita el producto o vence una promoción) → el pedido se cobra con el precio nuevo y la línea va en `priceChanges`; nunca se cobra lo que mandó la app. Test en Task 4.
3. **El producto de regalo está dado de baja o sin stock** → no bloquea el pedido: la línea de regalo no se agrega (o con lo que haya) y el pedido trae el aviso. Test en Task 2 (motor) y Task 4 (pedido).
4. **Se borra una promoción que ya usaron pedidos** → los pedidos siguen mostrando la línea con su foto (`AppliedPromotion`); el borrado no falla por la relación. Test en Task 4.
5. **El administrador pausa un código o le baja el límite después de que hubo canjes** → los canjes existentes dejan de valer mientras está pausado, nadie más lo activa si ya se pasó el nuevo límite, y los usos ya gastados no se recalculan en negativo. Test en Task 13.

---

## Fase 1: servidor (tipos, motor, cotización)

### Task 1: Tipos de promoción en el modelo y su validación

**Files:**
- Create: `apps/server/abarrotes_server/lib/src/promotions/promotion_type.spy.yaml`
- Modify: `apps/server/abarrotes_server/lib/src/promotions/promotion.spy.yaml`
- Modify: `apps/server/abarrotes_server/lib/src/promotions/promotions_service.dart` (`PromotionInput`, `create`, `update`, `_validate`)
- Modify: `apps/server/abarrotes_server/lib/src/promotions/promotions_routes.dart` (lectura del body, `promotionJson`, `activePromotionJson`)
- Create: `apps/server/abarrotes_server/lib/src/promotions/promotion_labels.dart`
- Create: migración `migrations/<ts>-tipos-de-promocion/`
- Test: `apps/server/abarrotes_server/test/integration/promotions_routes_test.dart`, `test/unit/promotions/promotion_labels_test.dart`

**Interfaces:**
- Produces:
  - `enum PromotionType { specialPrice, percentOff, buyXPayY, extraUnit, gift }` (serialized byName, default `specialPrice`).
  - `Promotion` con `type`, `promoPriceCents: int?`, `percent: int?`, `buyQuantity: int?`, `payQuantity: int?`, `giftProduct: Product?` (`relation(name=promotion_gift_product, field=giftProductId, optional, onDelete=Restrict, onUpdate=Cascade)`), `giftQuantity: int?`.
  - `PromotionInput` suma `PromotionType type, int? percent, int? buyQuantity, int? payQuantity, UuidValue? giftProductId, int? giftQuantity`; `promoPriceCents` pasa a `int?`.
  - `String promotionLabel(Promotion p)` en `promotion_labels.dart`: `"Precio especial S/ 19.90"`, `"20 % menos"`, `"2x1"` (N x M), `"2.ª al 50 %"` (N.ª), `"Regalo: <giftProduct.name>"` (requiere `giftProduct` incluido; si no, `"Regalo"`).
  - JSON de `/promotions` y `/promotions/active`: `type`, `label`, `promoPrice` (o null), `percent`, `buyQuantity`, `payQuantity`, `giftProduct: {id, name}` (o null), `giftQuantity`.

- [ ] **Step 1: Write the failing tests**

En `promotions_routes_test.dart`, grupo `'tipos'`:
- `'crea cada tipo con sus campos'`: POST con `{type: percentOff, percent: 20}` → 201, `body['type'] == 'percentOff'`, `body['label'] == '20 % menos'`, `body['promoPrice'] == null`; `{type: buyXPayY, buyQuantity: 2, payQuantity: 1}` → `label == '2x1'`; `{type: extraUnit, buyQuantity: 2, percent: 50}` → `'2.ª al 50 %'`; `{type: gift, buyQuantity: 2, giftProductId: sal.id, giftQuantity: 1}` → `label == 'Regalo: Sal 1 kg'`, `giftProduct == {id, name: 'Sal 1 kg'}`.
- `'sin type es precio especial, como antes'`: el POST de siempre → `type == 'specialPrice'`.
- `'valida los campos de cada tipo'`: 400 con estos mensajes exactos: `percent` 0 y 91 → `'percent debe estar entre 1 y 90'`; `extraUnit` con `percent: 101` → `'percent debe estar entre 1 y 100'`; `buyXPayY` con `payQuantity: 2, buyQuantity: 2` → `'payQuantity debe ser menor que buyQuantity'`; `buyQuantity: 11` → `'buyQuantity debe estar entre 2 y 10'` (en `gift`, entre 1 y 10); `giftQuantity` 0 u 11 → `'giftQuantity debe estar entre 1 y 10'`; `gift` con `giftProductId` del mismo producto → `'El regalo tiene que ser otro producto'`; con uno dado de baja o inexistente → `'El producto de regalo no existe o está dado de baja'`; un campo de otro tipo (p. ej. `percent` en `buyXPayY`) → `'percent no va en una promoción buyXPayY'`; `specialPrice` sin `promoPrice` → `'promoPrice es obligatorio en un precio especial'`.
- `'el tipo no cambia al editar'`: PATCH con `type` → 400 `'La propiedad type no está permitida'`.

En `test/unit/promotions/promotion_labels_test.dart`: un test por tipo con las cadenas de arriba (3x2 → `'3x2'`, 3.ª al 25 % → `'3.ª al 25 %'`).

- [ ] **Step 2: Run tests to verify they fail**

Run: `dart test test/integration/promotions_routes_test.dart test/unit/promotions/promotion_labels_test.dart`
Expected: FAIL (no existe `type`, ni `promotion_labels.dart`).

- [ ] **Step 3: Model, generate and migration**

Escribir `promotion_type.spy.yaml` y los campos de `Promotion`. `generate`, `create-migration --tag tipos-de-promocion`. La migración deja `type = 'specialPrice'` en las filas existentes (default de la columna) y `promoPriceCents` nullable.

- [ ] **Step 4: Implement validation, labels and JSON**

`_validate` revisa por tipo (las reglas de la tabla de la spec, sección 3) antes de la regla de cruce actual; `create` guarda los campos del tipo; el PATCH sigue sin admitir `productId` ni `type`. `promotionJson` y `activePromotionJson` incluyen `giftProduct` (el `_include` suma `giftProduct: Product.include()`).

- [ ] **Step 5: Run tests to verify they pass**

Run: `dart test test/integration/promotions_routes_test.dart test/unit/promotions`
Expected: PASS (también los tests de antes de promociones).

- [ ] **Step 6: Apply migration, docs, commit**

Aplicar la migración y revisar con `psql` que `promotions.type` existe y las filas viejas dicen `specialPrice`. README del servidor (tabla de `/promotions`, campos por tipo). Commit: `feat(server): tipos de promoción`.

### Task 2: El motor de cobro por línea

**Files:**
- Create: `apps/server/abarrotes_server/lib/src/promotions/promotion_engine.dart`
- Create: `apps/server/abarrotes_server/lib/src/promotions/applied_promotion.spy.yaml` (clase serializable, sin tabla)
- Test: `apps/server/abarrotes_server/test/unit/promotions/promotion_engine_test.dart`

**Interfaces:**
- Consumes: `Promotion`, `PromotionType`, `promotionLabel` (Task 1).
- Produces:
  - `AppliedPromotion` (generado): `promotionId: UuidValue`, `label: String`, `savedCents: int`.
  - `typedef PricingLine = ({UuidValue productId, String name, int listUnitPriceCents, int quantity});`
  - `typedef GiftProduct = ({UuidValue id, String name, bool active, int stock});`
  - `class PricedLine { UuidValue productId; String name; int quantity; int listUnitPriceCents; int unitPriceCents; int lineTotalCents; bool isGift; List<AppliedPromotion> promotions; }`
  - `class PricedCart { List<PricedLine> lines; List<String> notices; int subtotalCents; int discountCents; int totalCents; Set<UuidValue> appliedPromotionIds; }` (`lines` incluye los regalos al final; `subtotalCents` = Σ cantidad × precio normal de las líneas compradas; `totalCents` = Σ `lineTotalCents`; `discountCents` = subtotal − total).
  - `PricedCart priceCart(List<PricingLine> lines, Map<UuidValue, List<Promotion>> promotionsByProduct, Map<UuidValue, GiftProduct> giftProducts)`
  - `int unitPriceFor(int listUnitPriceCents, List<Promotion> promotions)` — pasos 1 y 2 solos (lo usa el catálogo).

- [ ] **Step 1: Write the failing tests** (`promotion_engine_test.dart`; precios en céntimos)

- `'el ejemplo de la spec'`: arroz 2490 × 5 con precio especial 2290, 10 % y 2x1 → `unitPriceCents == 2061`, `lineTotalCents == 6183`, `subtotalCents == 12450`, `discountCents == 6267`, promociones aplicadas `['Precio especial S/ 22.90', '10 % menos', '2x1']`.
- `'dos precios especiales: el más bajo'`: 2290 y 1990 → unit 1990, solo la de 1990 en `promotions`.
- `'porcentajes en cadena, redondeo por paso'`: 999 con 20 % y 10 % → unit 719 (999→799→719).
- `'cantidad que no completa un grupo'` (Review Focus 1): 1 unidad con 2x1 → `lineTotalCents == unit`, `promotions` vacía; 3 con 2.ª al 50 % → solo 1 unidad con descuento.
- `'NxM antes que la unidad extra y cada unidad una vez'`: 4 unidades a 1000 con 2x1 y 2.ª al 50 % → `lineTotalCents == 2000`, solo `'2x1'` aplicada.
- `'entre dos NxM gana el que más ahorra'`: 6 a 1000 con 2x1 y 3x2 → `lineTotalCents == 3000`; 5 a 1000 → `3000` (2 grupos de 2x1, sobra 1).
- `'unidad extra'`: 5 a 1000 con 2.ª al 50 % → `4000` (2 unidades a 500).
- `'regalo'`: 5 aceites con "cada 2, 1 sal" y sal con stock 10 → línea de sal `quantity: 2, unitPriceCents: 0, lineTotalCents: 0, isGift: true`, `promotions` con `savedCents == 2 × precio de la sal`.
- `'regalo sin stock suficiente'` (Review Focus 3): stock 1 → 1 sal y `notices == ['Solo quedaba 1 de Sal 1 kg para regalo']`; stock 0 o `active: false` → sin línea de regalo y `notices == ['Sal 1 kg ya no está disponible para regalo']`.
- `'los regalos no entran en otras promociones'`: la sal con un 2x1 propio no cambia la línea de regalo.
- `'sin promociones'`: total = subtotal, `discountCents == 0`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `dart test test/unit/promotions/promotion_engine_test.dart`
Expected: FAIL (no existe `priceCart`).

- [ ] **Step 3: Implement `priceCart` and `unitPriceFor`**

`applied_promotion.spy.yaml` (`class: AppliedPromotion`, sin `table`) y `generate`. El motor sigue el orden de la spec (sección 4). Para los pasos 3 elige con este algoritmo, que los tests no determinan del todo:

```text
units = cantidad
para cada grupo de tipos en orden [buyXPayY, extraUnit]:
  candidatas = promociones de ese tipo
  mientras haya candidatas:
    ahorro(p) = ahorro de p aplicada sola sobre `units` unidades a `unit`
    p = la de mayor ahorro (desempate: id menor); si ahorro(p) == 0, cortar
    aplicar p; units -= unidades que consumió p; quitar p de candidatas
```

Un NxM consume `floor(units / N) × N` unidades y ahorra `floor(units / N) × (N − M) × unit`; una unidad extra consume `floor(units / N) × N` y ahorra `floor(units / N) × round(unit × percent / 100)`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `dart test test/unit/promotions/promotion_engine_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

`feat(server): motor de cobro de promociones por línea`.

### Task 3: Aviso de cruce en vez de rechazo

**Files:**
- Modify: `apps/server/abarrotes_server/lib/src/common/http_json.dart` (`ApiException`, `jsonError`)
- Modify: `apps/server/abarrotes_server/lib/src/promotions/promotions_service.dart` (`_validate`)
- Modify: `apps/server/abarrotes_server/lib/src/promotions/promotions_routes.dart` (`confirmOverlap`)
- Test: `apps/server/abarrotes_server/test/integration/promotions_routes_test.dart`, `test/unit/common/http_json_test.dart` (crear si no existe)

**Interfaces:**
- Produces:
  - `ApiException` suma `final Map<String, Object?>? details;` y `const ApiException.conflict(String message, {Map<String, Object?>? details})`; la respuesta de error suma las claves de `details` al JSON (`{statusCode, message, error, ...details}`).
  - `PromotionInput` suma `bool confirmOverlap` (default `false`).
  - 409 de cruce: `message: 'Se acumula con otras promociones del producto'`, `details: {'overlaps': [{id, type, audience, label, startDate, endDate}]}`.

- [ ] **Step 1: Write the failing tests**

- `'una que se cruza avisa con la lista; confirmOverlap la crea'`: crear un 2x1 (todos, días 0–6) y después un 20 % VIP del mismo producto (días 3–9) → 409, `body['overlaps']` con una entrada `{type: 'buyXPayY', audience: 'everyone', label: '2x1', startDate: day(0), endDate: day(6)}`; repetir con `confirmOverlap: true` → 201.
- `'misma audiencia y tipo también se acumula si se confirma'`: dos precios especiales para todos que se cruzan → 409 sin confirmar (antes también era 409, ahora con `overlaps`), 201 con `confirmOverlap`.
- `'no avisan las apagadas, las de otro producto ni las que no se pisan en fechas'` → 201 sin confirmar.
- `'editar no se cruza consigo misma'`: PATCH del precio de una promoción → 200 sin `confirmOverlap`.
- En `http_json_test.dart`: `jsonError` con `details: {'overlaps': []}` → el body tiene `overlaps`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `dart test test/integration/promotions_routes_test.dart`
Expected: FAIL (el 409 actual no trae `overlaps` y `confirmOverlap` no se admite).

- [ ] **Step 3: Implement**

La regla de cruce busca encendidas del mismo `productId` con `startDate < fin` y `endDate > inicio`, de cualquier audiencia y tipo, excepto la misma; si hay y `!input.confirmOverlap`, lanza el 409 con `details`. Se borra la regla vieja (misma audiencia).

- [ ] **Step 4: Run tests to verify they pass**

Run: `dart test test/integration/promotions_routes_test.dart test/unit/common`
Expected: PASS. Los tests viejos que esperaban el mensaje "ya tiene una promoción … que se cruza" se actualizan al nuevo 409.

- [ ] **Step 5: Docs, commit**

README (reglas de las promociones). Commit: `feat(server): avisar del cruce de promociones en vez de rechazarlo`.

### Task 4: El pedido se cobra con el motor y guarda el detalle

**Files:**
- Modify: `apps/server/abarrotes_server/lib/src/orders/order.spy.yaml`, `order_item.spy.yaml`
- Modify: `apps/server/abarrotes_server/lib/src/promotions/promotion_pricing.dart`, `promotions_service.dart`
- Modify: `apps/server/abarrotes_server/lib/src/orders/orders_service.dart` (`create`, `_create`, cancelar), `orders_routes.dart` (body de `POST /orders`, `orderJson`)
- Modify: `apps/server/abarrotes_server/lib/src/stats/providers/top_products_report_provider.dart`
- Create: migración `migrations/<ts>-detalle-del-cobro/` (con el relleno de los pedidos viejos)
- Test: `test/integration/orders_routes_test.dart`, `test/integration/stats_routes_test.dart`

**Interfaces:**
- Consumes: `priceCart`, `PricingLine`, `GiftProduct`, `PricedCart`, `AppliedPromotion` (Task 2).
- Produces:
  - `Order`: `subtotalCents: int, default=0`, `discountCents: int, default=0`.
  - `OrderItem`: `listUnitPriceCents: int`, `lineTotalCents: int`, `isGift: bool, default=false`, `promotions: List<AppliedPromotion>?`.
  - `PromotionPricing.price(Session session, List<PricingLine> lines, Shopper shopper, {Transaction? transaction}) → Future<PricedCart>` (busca las promociones vigentes que `shopper` puede usar para esos productos y los productos de regalo con su stock, y llama a `priceCart`). `bestFor` se reemplaza por `eligibleFor(DateTime now, Shopper shopper) → PromotionIncludeList` sin `limit` (todas las vigentes que puede usar, con `giftProduct` incluido).
  - `POST /orders`: cada ítem acepta `lineTotal` (además de `unitPrice`); `priceChanges` suma `{productId, name, shownLineTotal, lineTotal}` cuando viene `lineTotal`.
  - `orderJson`: `subtotal`, `discount`, `total`; cada ítem con `listUnitPrice`, `unitPrice`, `lineTotal`, `isGift`, `promotions: [{label, saved}]`.

- [ ] **Step 1: Write the failing tests** (`orders_routes_test.dart`, grupo `'promociones por tipo'`)

- `'cobra con el motor: 2x1 y 10 %'`: arroz 450 (stock 8) con 2x1 y 10 % para todos; pedido de 4 → `total == '8.1'` (405 × 2), ítem `{listUnitPrice: '4.5', unitPrice: '4.05', lineTotal: '8.1', isGift: false}`, `promotions` con `'10 % menos'` y `'2x1'`; `subtotal == '18'`, `discount == '9.9'`.
- `'el regalo va como línea a S/ 0 y descuenta stock'`: aceite con "cada 2, 1 arroz"; pedido de 2 aceites → ítem de arroz `{quantity: 1, lineTotal: '0', isGift: true}`; el stock del arroz baja 1 y hay un `InventoryMovement` de salida por el regalo con el `orderId`.
- `'regalo sin stock: el pedido sale igual con el aviso'` (Review Focus 3): arroz con stock 0 → 201, sin línea de regalo, `body['notices'] == ['Arroz ya no está disponible para regalo']`.
- `'lineTotal distinto: va en priceChanges'` (Review Focus 2): mandar `lineTotal: 9.9` cuando el cobro da 8.1 → `priceChanges == [{productId, name: 'Arroz', shownLineTotal: '9.9', lineTotal: '8.1'}]`; el total cobrado es 8.1.
- `'cancelar devuelve también el regalo'`: cancelar el pedido con regalo → el stock de los dos productos vuelve.
- `'borrar una promoción usada no rompe el pedido'` (Review Focus 4): pedido con 2x1, `DELETE /promotions/:id` → 204, `GET /orders/mine` sigue mostrando `promotions: [{label: '2x1', …}]`.
- `'pedidos de antes de la migración'`: un `Order`/`OrderItem` insertado sin los campos nuevos (valores por defecto) se lista con `discount == '0'` y `lineTotal == cantidad × unitPrice`.
- En `stats_routes_test.dart`: `'el top 5 suma lo cobrado por línea'`: un pedido entregado de 2 arroces con 2x1 → revenue del arroz `'4.5'`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `dart test test/integration/orders_routes_test.dart test/integration/stats_routes_test.dart`
Expected: FAIL.

- [ ] **Step 3: Model, generate and migration with backfill**

Campos de `Order`/`OrderItem`, `generate`, `create-migration --tag detalle-del-cobro`. Agregar al `migration.sql`, antes del registro de versión:

```sql
UPDATE "order_items" SET "listUnitPriceCents" = "unitPriceCents",
  "lineTotalCents" = "quantity" * "unitPriceCents";
UPDATE "orders" SET "subtotalCents" = "totalCents", "discountCents" = 0;
```

(`listUnitPriceCents` y `lineTotalCents` se crean con default 0 en la migración y el UPDATE los completa.)

- [ ] **Step 4: Implement**

`OrdersService._create` reemplaza `unitPrice`/`total` por `await _pricing.price(…)` dentro de la transacción (con los productos ya bloqueados), inserta una `OrderItem` por línea (regalos incluidos), registra la salida de inventario de cada línea (regalos también) y devuelve `notices` en `PlacedOrder`. El top 5 suma `oi."lineTotalCents"`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `dart test test/integration/orders_routes_test.dart test/integration/stats_routes_test.dart test/integration/products_routes_test.dart`
Expected: PASS.

- [ ] **Step 6: Apply migration, docs, commit**

Aplicar y revisar con `psql`: `select count(*) from order_items where "lineTotalCents" <> quantity * "unitPriceCents"` → 0 en los pedidos de antes. README (JSON del pedido, `POST /orders`). Commit: `feat(server): cobrar el pedido con el motor de promociones`.

### Task 5: Cotización y catálogo con los tipos

**Files:**
- Modify: `apps/server/abarrotes_server/lib/src/orders/orders_routes.dart` (ruta `POST /orders/quote`), `orders_service.dart` (`quote`)
- Modify: `apps/server/abarrotes_server/lib/src/products/products_service.dart` (`_include`), `products_routes.dart` (`productJson`)
- Modify: `test/unit/auth/route_permissions_test.dart`
- Test: `test/integration/orders_routes_test.dart`, `test/integration/products_routes_test.dart`

**Interfaces:**
- Consumes: `PromotionPricing.price`, `eligibleFor`, `unitPriceFor`, `promotionLabel`.
- Produces:
  - `OrdersService.quote(Session session, {required Shopper shopper, required List<({UuidValue productId, int quantity})> lines}) → Future<PricedCart>` (sin transacción de escritura; productos inexistentes o de baja van en `notices` como `'Ya no está disponible: <nombre>'` y no entran al cálculo).
  - `POST /orders/quote` pública con token opcional (`optionalIdentity`), body `{items: [{productId, quantity}]}` (1–100, cantidad 1–999). Responde `{lines: [ítem como en orderJson sin ids de pedido], subtotal, discount, total, notices}`.
  - Producto en el catálogo: `unitPrice` (pasos 1 y 2 para 1 unidad) y `promotions: [{id, type, label, audience, title, startDate, endDate, promoPrice, percent, buyQuantity, payQuantity, giftProduct, giftQuantity}]`; `promotion` sigue siendo el precio especial más bajo (o null), para las apps de antes.

- [ ] **Step 1: Write the failing tests**

- `orders_routes_test.dart`, `'POST /orders/quote'`:
  - `'cotiza sin cuenta con las de todos y no toca nada'`: 4 arroces con 2x1 → `total == '9'`, `lines[0]['promotions'][0]['label'] == '2x1'`; el stock y `Order.db.count` no cambian.
  - `'con un VIP suma sus promociones'`: con una de 10 % VIP y token de VIP → `total == '8.1'`.
  - `'producto de baja: aviso y sin línea'`: `notices == ['Ya no está disponible: Aceite']`.
  - `'valida el body'`: `items: []` → 400.
- `route_permissions_test.dart`: fila `('POST', '/orders/quote', público)` como las demás públicas.
- `products_routes_test.dart`, `'el catálogo trae las promociones por tipo'`: un producto con 20 % y 2x1 → `unitPrice == '3.6'` (450 − 20 %), `promotions` con labels `['20 % menos', '2x1']`, `promotion == null` (no hay precio especial).

- [ ] **Step 2: Run tests to verify they fail**

Run: `dart test test/integration/orders_routes_test.dart test/integration/products_routes_test.dart test/unit/auth/route_permissions_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement**

`quote` reusa `price` sin transacción; la ruta usa el `ShopperResolver` como `/promotions/active`. `ProductsService._include` usa `eligibleFor`; `productJson` calcula `unitPrice` con `unitPriceFor`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `dart test` (suite completa del servidor).
Expected: PASS.

- [ ] **Step 5: Docs, commit**

README (rutas `quote` y catálogo) y `ARQUITECTURA_Y_ROADMAP.md` (tipos de promoción, motor, cotización). Recompilar el servidor (`dart build cli --target bin/main.dart`) y probar `POST /orders/quote` con `curl` sin token. Commit: `feat(server): cotización del carrito y catálogo con los tipos de promoción`.

## Fase 2: app con los tipos

### Task 6: Formulario de promoción por tipo y aviso de cruce

**Files:**
- Modify: `apps/client/lib/admin/promotions/promotion.dart` (`PromotionType`, campos, `PromotionInput.toJson`, `label`)
- Modify: `apps/client/lib/admin/promotions/promotions_repository.dart` (`confirmOverlap`, error de cruce)
- Modify: `apps/client/lib/common/api_client.dart` (`ApiFailure.details`)
- Modify: `apps/client/lib/features/admin/promotions/promotion_form.dart`, `admin_promotions_screen.dart`
- Create: `apps/client/lib/features/admin/promotions/promotion_type_fields.dart`, `overlap_dialog.dart`
- Test: `apps/client/test/admin/admin_promotions_test.dart`, `test/admin/admin_repositories_test.dart`, `test/fakes.dart`

**Interfaces:**
- Consumes: JSON de la Task 1 y el 409 de la Task 3.
- Produces:
  - `enum PromotionType { specialPrice('Precio especial'), percentOff('% de descuento'), buyXPayY('NxM'), extraUnit('Unidad extra'), gift('Regalo') }` con `label`.
  - `Promotion` suma `type`, `percent`, `buyQuantity`, `payQuantity`, `giftProductId`, `giftProductName`, `giftQuantity`, `label` (del servidor); `promoPriceCents` pasa a `int?`.
  - `ApiFailure` suma `final Map<String, Object?> details` (lo que venga en el body además de `statusCode`, `message`, `error`).
  - `class PromotionOverlap implements Exception { final List<({String label, String audience, String startDate, String endDate})> overlaps; }` lanzada por `PromotionsRepository.create/update` ante el 409 con `overlaps`; ambos métodos suman `{bool confirmOverlap = false}`.

- [ ] **Step 1: Write the failing tests**

- `admin_repositories_test.dart`: `'el cruce llega como PromotionOverlap'` (409 con `overlaps` → `throwsA(isA<PromotionOverlap>())` con un elemento de label `'2x1'`); `'confirmOverlap va en el body'`; `'cada tipo manda solo sus campos'` (`toJson` de `buyXPayY` → `{type: 'buyXPayY', buyQuantity: 2, payQuantity: 1, …}` sin `promoPrice`).
- `admin_promotions_test.dart`:
  - `'el tipo muestra solo sus campos'`: elegir "NxM" → aparecen "Lleva" y "Paga" y el resumen `'Lleva 3, paga 2: una de cada 3 gratis'`; no aparece "Precio de la promoción".
  - `'unidad extra y regalo'`: resumen `'La 2.ª unidad al 50 %'`; regalo con el buscador de productos y `'Cada 2 lleva 1 de regalo'`.
  - `'valida como el servidor'`: "Paga" ≥ "Lleva" → `'Tiene que ser menor que lo que lleva.'`; % 95 en `% de descuento` → `'Entre 1 y 90.'`.
  - `'el cruce pregunta y "Crear igual" la crea'`: el fake responde `PromotionOverlap` la primera vez; aparece el diálogo con `'2x1 · Todos · 2026-10-01 – 2026-10-07'` y `'Se acumulan: el cliente recibe todas.'`; "Crear igual" reenvía con `confirmOverlap: true` y cierra; "Volver" no envía nada.
  - `'la tabla muestra el tipo'`: filas con `'20 % menos'`, `'2x1'`, `'Regalo: Sal 1 kg'`.
  - En el teléfono (320 px), elegir cada tipo sin desbordes.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test --no-pub -r json test/admin/admin_promotions_test.dart` y `test/admin/admin_repositories_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement**

`PromotionTypeFields` es un widget por tipo con sus `TextFormField` (validadores con el valor del propio campo) y su resumen. El tipo se elige con un `DropdownButtonFormField<PromotionType>` solo al crear (al editar se muestra fijo). `showOverlapDialog(context, overlaps) → Future<bool>`. `FakePromotionsRepository` suma `overlapsNext` para simular el 409.

- [ ] **Step 4: Run tests to verify they pass**

Run: los dos archivos de arriba.
Expected: PASS.

- [ ] **Step 5: Docs, commit**

README de la app (Promociones). Commit: `feat(client): promociones por tipo y aviso de cruce`.

### Task 7: El pedido con su detalle (Mis pedidos y panel)

**Files:**
- Modify: `apps/client/lib/orders/order.dart` (`Order`, `OrderLine`)
- Modify: `apps/client/lib/features/orders/my_orders_screen.dart` (líneas y totales del `_OrderCard`)
- Modify: `apps/client/lib/features/admin/orders/admin_orders_screen.dart` (detalle)
- Create: `apps/client/lib/features/orders/order_lines.dart` (widget compartido de líneas + totales)
- Test: `test/orders/order_test.dart`, `test/features/checkout_test.dart`, `test/admin/admin_orders_test.dart`

**Interfaces:**
- Consumes: `orderJson` de la Task 4.
- Produces:
  - `OrderLine` suma `listUnitPriceCents`, `lineTotalCents`, `isGift`, `promotions: List<({String label, int savedCents})>`; sin los campos (servidor anterior): `lineTotalCents = unitPriceCents × quantity`, `isGift = false`.
  - `Order` suma `subtotalCents`, `discountCents` (sin los campos: `subtotal = total`, `discount = 0`).
  - `OrderLines(order: Order)`: cada línea `"2 × Arroz extra 5 kg  S/ 49.80"` y debajo sus promociones (`"2x1 −S/ 24.90"`); los regalos `"1 × Sal 1 kg  Regalo"`; abajo `Subtotal`, `Descuentos` (solo si > 0) y `Total`.

- [ ] **Step 1: Write the failing tests**

- `order_test.dart`: `'lee el detalle del cobro'` (un ítem con `promotions` y uno con `isGift`) y `'de un servidor anterior: sin descuento'`.
- `checkout_test.dart`: `'Mis pedidos muestra las promociones y el regalo'` → textos `'2x1 −S/ 24.90'`, `'Regalo'`, `'Descuentos'`, `'−S/ 24.90'`.
- `admin_orders_test.dart`: `'el detalle del panel muestra el regalo y los descuentos'`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test --no-pub -r json test/orders/order_test.dart` (y los otros dos).
Expected: FAIL.

- [ ] **Step 3: Implement** `OrderLines` y usarlo en las dos pantallas.

- [ ] **Step 4: Run tests to verify they pass**

Run: los tres archivos.
Expected: PASS.

- [ ] **Step 5: Commit**

`feat(client): el pedido muestra sus promociones y regalos`.

### Task 8: Insignias de promociones en el catálogo

**Files:**
- Modify: `apps/client/lib/catalog/product.dart` (`unitPriceCents`, `offers`)
- Modify: `apps/client/lib/features/catalog/product_card.dart`, `product_detail_screen.dart`, `price_tag.dart`
- Create: `apps/client/lib/features/catalog/offer_badges.dart`
- Test: `test/catalog/http_catalog_repository_test.dart`, `test/features/product_card_test.dart`, `test/features/catalog_screen_test.dart`

**Interfaces:**
- Consumes: catálogo de la Task 5.
- Produces:
  - `Product` suma `List<ProductOffer> offers` con `typedef ProductOffer = ({String type, String label, String? title})` (solo los tipos por cantidad y regalo); el precio final (`finalPriceCents`) sale de `unitPrice` si viene, si no de `promotion.promoPrice` como hoy. `onSale` = `finalPriceCents < priceCents`. `vipPrice` sigue igual.
  - `OfferBadges(offers)`: chips cortos (`'2x1'`, `'2.ª al 50 %'`, `'+ regalo'`) con colores de `lib/theme/`.

- [ ] **Step 1: Write the failing tests**

`'lee unitPrice y las ofertas'` (repositorio); `'la tarjeta muestra la insignia 2x1'`; `'el detalle explica cada oferta'` (`'2x1 en este producto'`, `'Regalo: Sal 1 kg por cada 2'`); un producto con 20 % → precio tachado y `'S/ 3.60'`.

- [ ] **Step 2: Run to fail** — `flutter test --no-pub -r json` de los tres archivos. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to pass.** Expected: PASS.
- [ ] **Step 5: Commit** — `feat(client): insignias de promociones en el catálogo`.

### Task 9: Carrito con la cotización real

**Files:**
- Modify: `apps/client/lib/orders/order_repository.dart`, `http_order_repository.dart` (`quote`, `place` con `lineTotal`)
- Create: `apps/client/lib/orders/quote.dart` (modelo)
- Create: `apps/client/lib/cart/cart_quote_provider.dart`
- Modify: `apps/client/lib/cart/cart_provider.dart` (`placeOrder` manda `lineTotal`), `apps/client/lib/features/cart/cart_screen.dart` (`_CartLineTile`, `_Total`, regalos, aviso)
- Test: `test/orders/http_order_repository_test.dart`, `test/features/cart_screen_test.dart`, `test/features/checkout_test.dart`, `test/fakes.dart`

**Interfaces:**
- Consumes: `POST /orders/quote` (Task 5), `OrderLine` (Task 7).
- Produces:
  - `class Quote { List<OrderLine> lines; int subtotalCents; int discountCents; int totalCents; List<String> notices; }` con `Quote.fromJson`.
  - `OrderRepository.quote(List<({String productId, int quantity})> lines, {String? idToken}) → Future<Quote>`.
  - `cartQuoteProvider`: `AsyncNotifierProvider<CartQuoteNotifier, Quote?>` que escucha `cartProvider` y pide la cotización 400 ms después del último cambio (carrito vacío → `null`); con sesión manda el token.
  - `placeOrder` manda por ítem `unitPrice` (como hoy) y `lineTotal` si hay cotización para esa línea.

- [ ] **Step 1: Write the failing tests**

- Repositorio: `'quote manda los ítems y lee la respuesta'`.
- `cart_screen_test.dart`: `'el carrito muestra el 2x1 y el total cotizado'` (`'2x1 −S/ 24.90'`, `'Descuentos'`, total `'S/ 24.90'`); `'el regalo aparece como línea'`; `'el aviso de regalo sin stock'`; `'si la cotización falla, la estimación con aviso'` (`'No pudimos calcular las promociones. El total final se confirma al pedir.'`); `'cambiar la cantidad vuelve a cotizar'` (después de 400 ms, una sola llamada).
- `checkout_test.dart`: `'el pedido manda lineTotal de la cotización'`.

- [ ] **Step 2: Run to fail.** Expected: FAIL.
- [ ] **Step 3: Implement.** `FakeOrderRepository.quote` calcula como el servidor para los casos de los tests (2x1 y regalo) o devuelve lo que se le configure (`quoteResult`, `quoteFailure`).
- [ ] **Step 4: Run to pass.** Expected: PASS.
- [ ] **Step 5: Phase 2 wrap-up and commit**

`flutter analyze`, la suite completa de la app (archivo por archivo, con reintentos), README de la app y `ARQUITECTURA_Y_ROADMAP.md`. Commit: `feat(client): carrito con la cotización de promociones`.

## Fase 3: códigos en el servidor

### Task 10: Modelo de códigos, canjes y usos

**Files:**
- Create: `apps/server/abarrotes_server/lib/src/promo_codes/promo_code.spy.yaml`, `promo_code_eligibility.spy.yaml`, `promo_code_allowed_email.spy.yaml`, `promo_code_redemption.spy.yaml`, `order_promo_code_use.spy.yaml`
- Modify: `apps/server/abarrotes_server/lib/src/promotions/promotion_audience.spy.yaml` (`code`), `promotion.spy.yaml` (`promoCode`)
- Create: migración `migrations/<ts>-codigos-promocionales/`
- Test: `test/integration/promo_codes_model_test.dart`

**Interfaces:**
- Produces (todo generado):
  - `PromoCode`: `id`, `code: String` (único, mayúsculas), `active: bool, default=true`, `startDate: DateTime`, `endDate: DateTime` (límite exclusivo, como las promociones), `benefitDays: int?`, `maxRedemptions: int?`, `usesPerCustomer: int?`, `minPurchaseCents: int?`, `newCustomersOnly: bool, default=false`, `eligibility: PromoCodeEligibility, default=everyone`, `createdAt`, `promotions: List<Promotion>?` (relación `promo_code_promotions`), `allowedEmails: List<PromoCodeAllowedEmail>?`.
  - `enum PromoCodeEligibility { everyone, vip, listed }`.
  - `PromoCodeAllowedEmail`: `promoCode` (Cascade), `email` (normalizado); único por (código, correo).
  - `PromoCodeRedemption`: `promoCode` (Restrict), `user` (Restrict), `activatedAt`, `expiresAt`; único por (código, usuario).
  - `OrderPromoCodeUse`: `order` (Restrict), `redemption` (Restrict); único por (pedido, canje).
  - `PromotionAudience.code` y `Promotion.promoCode: PromoCode?` (`relation(name=promo_code_promotions, optional, onDelete=Restrict)`).

- [ ] **Step 1: Write the failing test**: `'un canje por cliente y código'` (insertar dos `PromoCodeRedemption` iguales → `DatabaseUniqueViolationException`) y `'el texto del código es único'`.
- [ ] **Step 2: Run to fail.** Expected: FAIL (no existen los modelos).
- [ ] **Step 3: Models, generate, migration** (`--tag codigos-promocionales`).
- [ ] **Step 4: Run to pass, apply migration, check with psql** (las tablas `promo_codes`, `promo_code_redemptions`, `order_promo_code_uses`, `promo_code_allowed_emails`).
- [ ] **Step 5: Commit** — `feat(server): modelo de códigos promocionales`.

### Task 11: Gestión de códigos en el panel

**Files:**
- Create: `apps/server/abarrotes_server/lib/src/promo_codes/promo_codes_service.dart`, `promo_codes_routes.dart`
- Modify: `apps/server/abarrotes_server/lib/src/promotions/promotions_service.dart`, `promotions_routes.dart` (audiencia `code` con `promoCodeId`)
- Modify: `apps/server/abarrotes_server/lib/server.dart`, `test/unit/auth/route_permissions_test.dart`
- Test: `test/integration/promo_codes_routes_test.dart`

**Interfaces:**
- Produces:
  - `String normalizePromoCode(String text)` → sin espacios en los extremos, en mayúsculas; válido si cumple `^[A-Z0-9-]{3,20}$`.
  - `enum PromoCodeStatus { active, scheduled, expired, paused }` (como `PromotionStatus`).
  - Rutas (`Permission.promotionsManage`): `GET /promo-codes` (`status`, `search`, paginado), `GET /promo-codes/:id`, `POST /promo-codes`, `PATCH /promo-codes/:id`, `DELETE /promo-codes/:id`.
  - JSON: `{id, code, active, status, startDate, endDate, benefitDays, maxRedemptions, usesPerCustomer, minPurchase, newCustomersOnly, eligibility, allowedEmails: [..], promotions: [promotionJson…], redemptions: n, orders: n}`.
  - `/promotions` acepta `audience: 'code'` solo con `promoCodeId` (400 `'promoCodeId es obligatorio en una promoción de código'` / `'promoCodeId solo va en una promoción de código'`).

- [ ] **Step 1: Write the failing tests**

- `'crea un código con su texto y condiciones'`: `code: ' verano-10 '` → `code == 'VERANO-10'`; JSON con los campos; `eligibility: 'listed'` con `allowedEmails: ['Ana@Tienda.pe']` → `['ana@tienda.pe']`.
- `'valida'`: texto `'ab'` o con espacios internos → `'code debe tener de 3 a 20 letras, números o guiones'`; repetido (en otra forma: `'Verano-10'`) → 409 `'Ya existe el código VERANO-10'`; `endDate < startDate`; `maxRedemptions: 0`; `listed` sin correos → `'Escribe al menos un correo'`; `encender sin promociones` → `'Agrega al menos una promoción antes de encender el código'`.
- `'promociones del código'`: POST `/promotions` con `audience: 'code', promoCodeId` → aparece en `GET /promo-codes/:id`; validaciones de `promoCodeId`.
- `'estado y conteos'`: un código vencido → `status == 'expired'`; con 2 canjes y 1 pedido → `redemptions == 2, orders == 1`; filtro `?status=paused`.
- `'con canjes, el texto no cambia y no se borra'`: PATCH `code` → 409 `'El código ya se activó: no se puede cambiar el texto'`; DELETE → 409 `'El código ya se activó: apágalo en vez de borrarlo'`; sin canjes, DELETE → 204 (borra sus promociones).
- `route_permissions_test.dart`: las cinco filas con `promotions.manage`.

- [ ] **Step 2: Run to fail.** Expected: FAIL.
- [ ] **Step 3: Implement.** `PromoCodesService` con la lógica; `promo_codes_routes.dart` con `InputReader`. Registrar en `server.dart`.
- [ ] **Step 4: Run to pass.** Run: `dart test test/integration/promo_codes_routes_test.dart test/integration/promotions_routes_test.dart test/unit/auth`. Expected: PASS.
- [ ] **Step 5: Commit** — `feat(server): gestión de códigos promocionales`.

### Task 12: Activar un código

**Files:**
- Modify: `apps/server/abarrotes_server/lib/src/promo_codes/promo_codes_service.dart` (`redeem`, `mine`), `promo_codes_routes.dart`
- Modify: `test/unit/auth/route_permissions_test.dart`
- Test: `test/integration/promo_codes_redeem_test.dart`

**Interfaces:**
- Consumes: `VipService.isActiveVip` NO se importa (otro dominio): el `ShopperResolver` ya trae `shopper.isVip`; la ruta pasa `isVip` al servicio.
- Produces:
  - `PromoCodesService.redeem(Session session, {required User customer, required bool isVip, required String code}) → Future<PromoCodeRedemption>` (con `promoCode` y sus promociones incluidas).
  - `PromoCodesService.mine(Session session, User customer) → Future<List<PromoCodeRedemption>>` (vigentes).
  - `POST /promo-codes/redeem` (`signedIn`, correo verificado; si no, 403 como `POST /orders`), `GET /promo-codes/mine` (`signedIn`).
  - JSON del canje: `{code, expiresAt, usesLeft (null = sin límite), minPurchase, promotions: [{label, product: {id, name}}]}`.
  - `expiresAt = min(activatedAt + benefitDays días, endDate del código)`; sin `benefitDays`, el `endDate`.

- [ ] **Step 1: Write the failing tests**

Mensajes exactos de la spec (sección 7): inexistente, apagado, antes de `startDate` y después de `endDate` → los cuatro `'El código no existe o ya no está vigente'` (404); `' verano-10 '` con espacios y minúsculas se activa; límite alcanzado → 409 `'Se acabaron los canjes de este código'`; `newCustomersOnly` con un pedido no cancelado → 403 `'Este código es solo para clientes nuevos'` (con solo pedidos cancelados, se activa); `vip` sin ser VIP → 403 `'Este código es solo para clientes VIP'`; `listed` con otro correo → 403 `'Este código no está disponible para tu cuenta'`; dos veces → 409 `'Ya activaste este código'`; correo sin verificar → 403.
`'dos activaciones a la vez no pasan el límite'`: sin rollback (`RollbackDatabase.disabled`), `maxRedemptions: 1`, dos sesiones a la vez → una 200 y una 409.
`'benefitDays'`: `expiresAt == activatedAt + 7 días` y nunca después del fin del código.
`'mine'`: devuelve el canje con `usesLeft == usesPerCustomer`; no incluye los vencidos ni los de códigos apagados.
`route_permissions_test.dart`: las dos filas como `signedIn`.

- [ ] **Step 2: Run to fail.** Expected: FAIL.
- [ ] **Step 3: Implement.** `redeem` en una transacción con el `PromoCode` bloqueado (`LockMode.forUpdate`) antes de contar canjes.
- [ ] **Step 4: Run to pass.** Expected: PASS.
- [ ] **Step 5: Commit** — `feat(server): activar códigos promocionales`.

### Task 13: Las promociones del código en el cobro

**Files:**
- Create: `apps/server/abarrotes_server/lib/src/promotions/code_benefits.dart`
- Create: `apps/server/abarrotes_server/lib/src/promo_codes/db_code_benefits.dart`
- Modify: `apps/server/abarrotes_server/lib/src/promotions/promotions_service.dart` (`price`, `eligibleFor`), `promotion_engine.dart` (segunda pasada)
- Modify: `apps/server/abarrotes_server/lib/src/orders/orders_service.dart` (anotar usos), `lib/server.dart`
- Test: `test/integration/promo_codes_pricing_test.dart`, `test/unit/promotions/promotion_engine_test.dart`

**Interfaces:**
- Consumes: modelos de la Task 10; `price` de la Task 4.
- Produces:
  - `typedef CodeBenefit = ({UuidValue redemptionId, UuidValue promoCodeId, String code, int? minPurchaseCents});`
  - `abstract interface class CodeBenefits { Future<List<CodeBenefit>> activeFor(Session session, UuidValue customerId, {Transaction? transaction, bool lock = false}); }` y `class NoCodeBenefits implements CodeBenefits` (lista vacía). `DbCodeBenefits` (en `promo_codes/`) devuelve los canjes con código encendido, `expiresAt > now` y usos < `usesPerCustomer` (los usos cuentan `OrderPromoCodeUse` de pedidos no cancelados); con `lock`, bloquea las filas de esos canjes.
  - `PromotionsService({…, CodeBenefits codeBenefits = const NoCodeBenefits()})`.
  - `PromotionPricing.price(…, {Transaction? transaction, UuidValue? customerId, bool lockCodes = false})`; `PricedCart` suma `Set<UuidValue> usedRedemptionIds` (canjes cuyas promociones ahorraron algo) y, en `notices`, `'Con S/ 12.40 más se aplica tu código VERANO-10'` cuando falta la compra mínima.
  - En `AppliedPromotion.label`, las del código van como `'Código VERANO-10: 2x1'`.

- [ ] **Step 1: Write the failing tests**

- Motor: `'segunda pasada con la compra mínima'` (sin llegar al mínimo, las del código no se aplican y queda el aviso con el monto exacto; llegando, se aplican).
- `promo_codes_pricing_test.dart`:
  - `'quien lo activó paga con el 2x1 del código; otro cliente no'` (quote y `POST /orders`).
  - `'un pedido gasta un uso y cancelarlo lo devuelve'`: `usesPerCustomer: 1` → después del pedido, `mine` no lo trae; cancelar → vuelve con `usesLeft == 1`.
  - `'un pedido que no usa sus promociones no gasta el uso'`.
  - `'la cotización no gasta usos'`.
  - `'dos pedidos a la vez no pasan usesPerCustomer'` (sin rollback, `usesPerCustomer: 1` → un pedido con el 2x1 y otro sin él).
  - `'vencido por benefitDays, ya no aplica'` (reloj de prueba).
  - Review Focus 5: `'pausar el código corta el beneficio; bajar el límite no rompe nada'`: con un canje activo, `PATCH active: false` → la cotización ya no lo aplica; volver a encenderlo → aplica; `PATCH maxRedemptions` por debajo de los canjes existentes → 200, el canje sigue valiendo y un cliente nuevo recibe `'Se acabaron los canjes de este código'`.

- [ ] **Step 2: Run to fail.** Expected: FAIL.
- [ ] **Step 3: Implement.** `price` pide `codeBenefits.activeFor(customerId, lock: lockCodes)`, suma las promociones `code` de esos códigos para la segunda pasada, y `OrdersService._create` llama con `lockCodes: true` e inserta un `OrderPromoCodeUse` por cada `usedRedemptionIds`. `server.dart` pasa `DbCodeBenefits()` a `PromotionsService`.
- [ ] **Step 4: Run to pass.** Run: `dart test` (suite completa). Expected: PASS.
- [ ] **Step 5: Phase 3 wrap-up and commit**

Aplicar migraciones pendientes; README (rutas `/promo-codes`, el cobro con códigos) y `ARQUITECTURA_Y_ROADMAP.md` (dominio `promo_codes`); recompilar el servidor y probar `POST /promo-codes/redeem` sin token → 401. Commit: `feat(server): las promociones de los códigos en el cobro`.

## Fase 4: códigos en la app

### Task 14: Códigos en el panel

**Files:**
- Create: `apps/client/lib/admin/promo_codes/promo_code.dart`, `promo_codes_repository.dart`, `promo_codes_providers.dart`
- Create: `apps/client/lib/features/admin/promotions/promotions_tabs.dart`, `admin_promo_codes_screen.dart`, `promo_code_form.dart`
- Modify: `apps/client/lib/features/admin/promotions/admin_promotions_screen.dart` (pestañas), `promotion_form.dart` (audiencia fija en un código)
- Modify: `apps/client/lib/router/routes.dart` (`adminPromoCodes = '/admin/promociones/codigos'`, permiso `promotionsManage`), `router/router.dart`
- Test: `test/admin/admin_promo_codes_test.dart`, `test/admin/admin_repositories_test.dart`, `test/router/route_guard_test.dart`, `test/fakes.dart`

**Interfaces:**
- Consumes: rutas de la Task 11.
- Produces:
  - `enum PromoCodeStatus { active('Activo'), scheduled('Programado'), expired('Vencido'), paused('Pausado') }`, `enum PromoCodeEligibility { everyone('Todos'), vip('Solo VIP'), listed('Lista de correos') }`.
  - `class PromoCode` (los campos del JSON) y `class PromoCodeInput` con `toJson`.
  - `PromoCodesRepository`: `list({page, status, search})`, `get(id)`, `create(input)`, `update(id, input)`, `delete(id)`.
  - `promoCodesProvider` (familia por filtro, `PagedNotifier`), `promoCodeProvider(id)`.
  - `PromotionForm` suma `String? promoCodeId`: con él, la audiencia no se muestra y se manda `audience: 'code'`.

- [ ] **Step 1: Write the failing tests**

`'la tabla: código, estado, vigencia y activaciones'` (`'Activado por 47 de 100'`, `'Sin límite'`); `'chips por estado y búsqueda'`; `'crear: el texto va en mayúsculas al escribir'`; `'condiciones: compra mínima y lista de correos'` (casilla + monto; `'Lista de correos'` con chips; sin correos → `'Escribe al menos un correo.'`); `'agregar una promoción al código'` (abre `PromotionForm` sin audiencia y el repositorio de promociones recibe `audience: 'code', promoCodeId`); `'encenderlo sin promociones muestra el error del servidor'`; `'con canjes, el texto no se edita'`; el guard (`/admin/promociones/codigos` sin `promotions.manage` → sin acceso); en el teléfono sin desbordes.

- [ ] **Step 2: Run to fail.** Expected: FAIL.
- [ ] **Step 3: Implement.** Las pestañas reusan `PanelTabs` como Pedidos.
- [ ] **Step 4: Run to pass.** Expected: PASS.
- [ ] **Step 5: Commit** — `feat(client): códigos promocionales en el panel`.

### Task 15: "Mis códigos" y el código en el carrito

**Files:**
- Create: `apps/client/lib/promo_codes/my_promo_code.dart`, `my_promo_codes_repository.dart`, `my_promo_codes_providers.dart`
- Create: `apps/client/lib/features/account/my_codes_section.dart`
- Modify: `apps/client/lib/features/account/my_account_screen.dart`, `apps/client/lib/features/cart/cart_screen.dart`, `apps/client/lib/cart/cart_quote_provider.dart` (volver a cotizar al activar un código)
- Test: `test/features/my_account_test.dart`, `test/features/cart_screen_test.dart`, `test/promo_codes/my_promo_codes_repository_test.dart`, `test/fakes.dart`

**Interfaces:**
- Consumes: rutas de la Task 12; `Quote.notices` (Task 9) con el aviso de compra mínima.
- Produces:
  - `class MyPromoCode { String code; DateTime expiresAt; int? usesLeft; int? minPurchaseCents; List<String> promotions; }`.
  - `MyPromoCodesRepository`: `mine(idToken)`, `redeem(idToken, code)`.
  - `myPromoCodesProvider` (`AsyncNotifier`, se recarga al cambiar la sesión) con `redeem(code)` que, al terminar, invalida `cartQuoteProvider`.
  - `MyCodesSection`: campo `'Escribe tu código'`, botón `'Activar'`, error del servidor debajo del campo, y cada código con `'2x1 en Arroz extra 5 kg'`, `'Vence el 30 nov'`, `'Te quedan 2 usos'` (o `'Sin límite de usos'`).

- [ ] **Step 1: Write the failing tests**

`'activar un código lo agrega a la lista'`; `'el error del servidor queda en el campo'` (`'El código no existe o ya no está vigente'`); `'el carrito lleva a activar y vuelve'` (`'¿Tienes un código?'` → `/mi-cuenta?from=/carrito`); `'el carrito muestra la línea del código y el aviso de compra mínima'` (`'Código VERANO-10: 2x1'`, `'Con S/ 12.40 más se aplica tu código VERANO-10'`); repositorio (`redeem` manda `{code}` con el token); en el teléfono sin desbordes.

- [ ] **Step 2: Run to fail.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to pass.** Expected: PASS.
- [ ] **Step 5: Commit** — `feat(client): activar códigos en Mi cuenta y verlos en el carrito`.

### Task 16: Verificación final

**Files:**
- Modify: `apps/client/README.md`, `apps/server/README.md`, `docs/ARQUITECTURA_Y_ROADMAP.md`, `docs/DEMO.md` (paso de la demo con un código)

- [ ] **Step 1:** `flutter analyze` y `dart analyze --fatal-infos` sin problemas.
- [ ] **Step 2:** Suite completa del servidor (`dart test`) y de la app (archivo por archivo, con reintentos). Expected: todo PASS.
- [ ] **Step 3:** Capturas temporales (goldens en `apps/client/test_capturas/`, excluida en `.git/info/exclude`; salida en `capturas/codigos-promocionales/`): formulario de cada tipo, diálogo de cruce, carrito con 2x1 y regalo, código en el panel, "Mis códigos" y el carrito con el código, en teléfono (390 × 844) y escritorio (1280 × 900). Revisarlas y corregir lo que se vea mal; borrar `test_capturas/` al terminar.
- [ ] **Step 4:** Recompilar el servidor (`dart build cli`), levantarlo (`server-exe`) y probar con `curl` `POST /orders/quote`; apagarlo al terminar.
- [ ] **Step 5:** Commit de la documentación que falte — `docs: códigos promocionales en la guía de la demo`.
