# Tipos de promoción y códigos promocionales

Fecha: 2026-11-02 · Rama: `feature/codigos-promocionales` (sale de `feature/pedidos-y-clientes`)

## 1. Qué se quiere

El cliente quiere que el personal cree **códigos promocionales** con un texto que elige él (no
aleatorio). El cliente final activa el código en su cuenta y, desde ese momento, recibe las
promociones del código durante un tiempo y por una cantidad de pedidos.

Además, las promociones dejan de ser solo "precio especial": suman **% de descuento, NxM (2x1,
3x2…), unidad extra con descuento y producto de regalo**. Los cinco tipos valen para todas las
audiencias (todos, VIP, clientes elegidos y, ahora, código).

Decisiones de la persona:

- Un código **desbloquea promociones de producto** de cualquier tipo, y el administrador elige
  libremente cuáles da cada código.
- Las promociones que un cliente puede usar en un producto **se acumulan**. Si una promoción nueva
  se cruza con otras, el panel **avisa** y el administrador decide si la crea igual.
- Un código **se activa en la cuenta** y dura un tiempo, con dos límites: cuántos clientes pueden
  activarlo y cuántos pedidos puede usarlo cada uno.
- Las condiciones de un código (compra mínima, solo clientes nuevos, solo VIP o una lista de
  correos) son **opcionales y las elige el administrador** en cada código.

Fuera de alcance, para después si hace falta: descuento sobre el total del pedido, límite de
intentos de canje, códigos generados en lote y estadísticas de cuánto rindió cada código.

## 2. Entrega por fases

| Fase | Paquete | Qué |
|---|---|---|
| 1 | Servidor | Tipos de promoción, motor de cobro por línea, `POST /orders/quote`, detalle del cobro en el pedido |
| 2 | App | Formulario con tipos, aviso de cruce, insignias, carrito con la cotización, detalle del pedido |
| 3 | Servidor | Códigos, activación, uso en el cobro |
| 4 | App | Códigos en el panel y "Mis códigos" en la tienda |

Cada fase lleva su migración (aplicada en la base de desarrollo y revisada con `psql`), su
documentación en el mismo commit (READMEs y `docs/ARQUITECTURA_Y_ROADMAP.md`) y sus tests. Al
final: suites completas, capturas temporales (teléfono y escritorio), el servidor compilado
reiniciado y sin APK.

## 3. Tipos de promoción

`Promotion` suma `type` (`PromotionType`). Las promociones que ya existen quedan como
`specialPrice`.

| Tipo | `type` | Campos | Validación | Ejemplo |
|---|---|---|---|---|
| Precio especial | `specialPrice` | `promoPriceCents` | menor que el precio normal | Arroz a S/ 19.90 |
| % de descuento | `percentOff` | `percent` | 1–90 | 20 % menos |
| NxM | `buyXPayY` | `buyQuantity` (N), `payQuantity` (M) | 2 ≤ N ≤ 10, 1 ≤ M < N | 2x1, 3x2 |
| Unidad extra | `extraUnit` | `buyQuantity` (cada N.ª), `percent` | 2 ≤ N ≤ 10, 1–100 | 2.ª al 50 % |
| Regalo | `gift` | `buyQuantity` (cada X), `giftProduct`, `giftQuantity` (Y) | X ≥ 1, 1 ≤ Y ≤ 10, otro producto, activo | Por 2 aceites, 1 sal gratis |

`promoPriceCents` pasa a ser opcional (solo lo lleva `specialPrice`). Los campos que no son del
tipo se rechazan con 400. El tipo no cambia al editar: para otro tipo, otra promoción.

## 4. Cómo se cobra una línea

Para cada producto del pedido, con las promociones **vigentes que ese cliente puede usar**:

1. **Precio unitario:** el precio especial más bajo, o el normal si no hay ninguno. Dos precios
   especiales no se suman: los dos son "el precio".
2. **Porcentajes:** todos, en cadena, sobre ese precio (20 % y 10 % → 28 % menos), redondeado al
   céntimo por unidad.
3. **Por cantidad**, sobre el precio del paso 2: primero los NxM, después la unidad extra. Cada
   unidad entra en una sola promoción por cantidad; entre dos que compiten por las mismas unidades,
   gana la que más ahorra. Así nunca se cobra menos que cero ni se regala dos veces la misma
   unidad.
4. **Regalos:** cada promoción de regalo agrega `floor(cantidad / X) × Y` unidades del producto de
   regalo, en una línea aparte a S/ 0 que descuenta stock. Si el stock no alcanza, se da lo que
   haya y el pedido trae un aviso. Los regalos no entran en otras promociones.

Ejemplo: Arroz a S/ 24.90, 5 unidades, con precio especial S/ 22.90, 10 % y 2x1. Precio: S/ 20.61.
El 2x1 regala 2 de las 5. Línea: 3 × 20.61 = S/ 61.83.

### Aviso de cruce

Al crear o editar una promoción encendida, el servidor busca otras encendidas **del mismo producto
y con fechas que se pisan**, de cualquier audiencia. Si las hay, responde 409 con
`{message, overlaps: [{id, type, audience, label, startDate, endDate}]}`. El panel muestra la lista
y "Se acumulan: el cliente recibe todas"; con "Crear igual" reenvía con `confirmOverlap: true`.
Esto reemplaza el rechazo actual entre promociones de la misma audiencia.

## 5. Fase 1: servidor

### Modelo

- `Promotion` (`lib/src/promotions/promotion.spy.yaml`): `type`, `promoPriceCents?`, `percent?`,
  `buyQuantity?`, `payQuantity?`, `giftProduct: Product?` (relación opcional, `Restrict`),
  `giftQuantity?`.
- `Order`: `subtotalCents` (a precio normal) y `discountCents`. `totalCents` sigue siendo lo
  cobrado: ventas y estadísticas no cambian.
- `OrderItem`: `listUnitPriceCents` (precio normal), `unitPriceCents` (después de los pasos 1 y
  2), `lineTotalCents` (lo cobrado), `isGift` y `promotions: List<AppliedPromotion>?`, una foto de
  lo aplicado (`promotionId`, `label`, `savedCents`) que se mantiene aunque después se borre la
  promoción.
- Migración: los pedidos de antes quedan con `subtotalCents = totalCents`, `discountCents = 0`,
  `listUnitPriceCents = unitPriceCents`, `lineTotalCents = quantity × unitPriceCents` e
  `isGift = false`.

### Motor

`lib/src/promotions/promotion_engine.dart`: una función pura con el orden de la sección 4. Recibe
las líneas (producto, precio normal, cantidad, stock del regalo) y las promociones aplicables por
producto. Devuelve cada línea con sus precios y promociones aplicadas, las líneas de regalo, los
avisos, y `subtotal`, `discount` y `total`. Se prueba con tests unitarios, sin base de datos.

`PromotionPricing`, lo único que ven `orders` y `products`, suma `price(session, lines, shopper,
{transaction})`: busca las promociones vigentes que el cliente puede usar (con las reglas de
audiencia de siempre) y llama al motor.

### Rutas

- **`POST /orders/quote`**, pública con token opcional: `{items: [{productId, quantity}]}`.
  Devuelve líneas, regalos, `subtotal`, `discount`, `total` y `notices` (regalo sin stock,
  producto no disponible). No guarda ni descuenta stock.
- **`POST /orders`** cobra con el mismo motor dentro de su transacción. Cada ítem puede traer
  `lineTotal` (lo que mostraba el carrito); si difiere, va en `priceChanges`. Las apps de antes,
  que mandan `unitPrice`, se comparan por precio unitario como hoy.
- **`POST`/`PATCH /promotions`**: los campos de cada tipo, `confirmOverlap` y el 409 con
  `overlaps`.
- **JSON del pedido:** `subtotal`, `discount`, `total`; cada línea con `listUnitPrice`,
  `unitPrice`, `lineTotal`, `isGift` y `promotions: [{label, saved}]`.
- **Catálogo:** cada producto trae `promotions` (las que puede usar quien mira, con `type`,
  `label` y sus campos) y su precio por unidad con los pasos 1 y 2. `promotion` se mantiene para
  las apps de antes.
- El top 5 de productos de las estadísticas pasa a sumar `lineTotalCents`.

### Tests

El motor, tipo por tipo y combinados (el ejemplo de la sección 4, NxM contra unidad extra, regalo
sin stock, cantidades que no completan un grupo); la validación de cada tipo; el 409 de cruce y
`confirmOverlap`; `quote` sin token, con VIP y sin tocar stock; `POST /orders` con regalo
(descuenta el stock de los dos productos) y con `priceChanges`; la migración de los pedidos de
antes; el top 5 con un 2x1.

## 6. Fase 2: app

### Panel

- **Formulario de promoción:** "Tipo de promoción" arriba y, debajo, solo los campos de ese tipo,
  cada uno con un resumen ("Lleva 3, paga 2: una de cada 3 gratis", "La 2.ª unidad al 50 %",
  "Precio normal S/ 24.90 · 20 % menos"). El regalo usa el buscador de productos que ya existe.
- **Diálogo de cruce:** la lista ("2x1 · Todos · 1–15 nov"), "Se acumulan: el cliente recibe
  todas", "Volver" y "Crear igual".
- **Tabla de Promociones:** el tipo de cada una ("S/ 24.90 → S/ 19.90", "20 % menos", "2x1",
  "2.ª al 50 %", "Regalo: Sal 1 kg").
- **Detalle del pedido:** cada línea con sus promociones, los regalos, y subtotal, descuento y
  total.

### Tienda

- **Catálogo y detalle:** el precio por unidad (precio especial y %), como hoy, e insignias para
  las promociones por cantidad y los regalos ("2x1", "2.ª al 50 %", "+ regalo"). En el detalle,
  una línea que explica cada una.
- **Carrito:** con cada cambio de cantidad pide `POST /orders/quote` (con una pausa breve). Cada
  línea muestra lo que se ahorra ("2x1 −S/ 24.90"), los regalos van como líneas a S/ 0 y abajo
  "Subtotal, Descuentos, Total". Si la cotización falla, el carrito vuelve a la estimación de hoy
  con un aviso.
- **Mis pedidos:** cada línea con sus promociones, los regalos, y subtotal, descuento y total.

La cotización vive detrás de un repositorio con su provider, como el resto: las pantallas no
llaman HTTP.

### Tests

El formulario de cada tipo y sus validaciones; el diálogo de cruce ("Crear igual" y "Volver");
las insignias; el carrito con la cotización (descuentos, regalo sin stock, fallo); el detalle del
pedido; que todo entre en el teléfono.

## 7. Fase 3: códigos en el servidor

Dominio nuevo: `lib/src/promo_codes/`. Usa `promotions.manage` para el panel.

### Modelo

- **`PromoCode`:**
  - `code`: lo elige el administrador. De 3 a 20 letras, números o guiones; se guarda en
    mayúsculas y es único (409 si ya existe). El cliente lo escribe como quiera y vale igual.
  - `active`: el interruptor. Apagado, el código no se activa y sus promociones dejan de valer.
  - `startDate` y `endDate`: días de la tienda en que se puede activar.
  - `benefitDays?`: cuántos días dura el beneficio desde que cada cliente lo activa. Sin valor,
    dura hasta el fin de la vigencia.
  - `maxRedemptions?`: cuántos clientes pueden activarlo. `usesPerCustomer?`: cuántos pedidos
    puede usarlo cada uno. Sin valor, sin límite.
  - Condiciones, todas opcionales: `minPurchaseCents?`, `newCustomersOnly`, `eligibility`
    (`everyone`, `vip` o `listed`) con `PromoCodeAllowedEmail` (correos normalizados) para
    `listed`.
- **Promociones del código:** `PromotionAudience` suma `code`, y `Promotion` suma
  `promoCode: PromoCode?` (relación opcional). Una promoción `code` pertenece a un solo código; un
  código tiene una o más. Hace falta al menos una para encenderlo.
- **`PromoCodeRedemption`:** `promoCode`, `user`, `activatedAt`, `expiresAt`. Una por cliente y
  código (índice único).
- **`OrderPromoCodeUse`:** `order` y `redemption`. Los usos de un cliente son los pedidos no
  cancelados que usaron su canje: cancelar un pedido devuelve el uso.

### Activación

**`POST /promo-codes/redeem {code}`**, con cuenta y correo verificado:

- Si no existe, está apagado o fuera de fechas: siempre "El código no existe o ya no está
  vigente", para no revelar cuáles existen.
- Si alcanzó `maxRedemptions`: "Se acabaron los canjes de este código". La fila del código se
  bloquea al activarlo, así dos activaciones a la vez no pasan el límite.
- Si no cumple una condición, cuál: "Este código es solo para clientes nuevos", "Este código es
  solo para clientes VIP", "Este código no está disponible para tu cuenta".
- Si ya lo activó: "Ya activaste este código".
- Responde el canje: el código, sus promociones, `expiresAt` y los usos que quedan.

**`GET /promo-codes/mine`**: los canjes vigentes (sin vencer y con usos), con sus promociones,
`expiresAt` y los usos que quedan.

### Uso en el cobro

- Las promociones `code` valen para quien tiene un canje vigente de ese código: código encendido,
  sin vencer y con usos.
- El motor calcula primero sin ellas; si ese total llega a la compra mínima del código, las suma.
- Un pedido gasta un uso de cada código que **le ahorró algo**. La fila del canje se bloquea en
  la transacción del pedido, así dos pedidos a la vez no pasan `usesPerCustomer`.
- La cotización muestra lo mismo pero no gasta usos. Si falta la compra mínima, trae un aviso con
  cuánto falta.

### Panel

`GET/POST/PATCH/DELETE /promo-codes` (`promotions.manage`):

- La lista trae el estado (activo, programado, vencido o pausado), "activado por N de M" y
  cuántos pedidos lo usaron, con filtro por estado y búsqueda por texto.
- Si alguien ya lo activó, el texto no cambia y en vez de borrarlo se apaga (409 con el motivo).
- Las promociones del código se crean y editan con `/promotions`, con `audience: code` y
  `promoCodeId`.
- Cada ruta con su fila en `test/unit/auth/route_permissions_test.dart`.

### Tests

Cada condición y límite; dos activaciones a la vez contra `maxRedemptions`; el pedido gasta un uso
y cancelar lo devuelve; dos pedidos a la vez contra `usesPerCustomer`; la compra mínima; código
apagado o vencido; `benefitDays`; las promociones del código no les salen a otros; un pedido que
no usa ninguna promoción del código no gasta usos.

## 8. Fase 4: códigos en la app

### Panel

- Promociones gana la pestaña **"Promociones | Códigos"** (`/admin/promociones/codigos`), con el
  mismo permiso.
- **Tabla:** código, estado, vigencia, "Activado por 47 de 100" y pedidos que lo usaron; chips por
  estado y buscador.
- **Formulario:** texto (en mayúsculas al escribir), vigencia, "Dura N días desde que se activa"
  (opcional), límite de clientes y usos por cliente (vacío = sin límite), interruptor.
  "Condiciones": compra mínima con su monto, "Solo clientes nuevos", "¿Quién puede activarlo?"
  (Todos, Solo VIP o Lista de correos, con chips para escribir o pegar). "Promociones que da": la
  lista y "Agregar promoción", que abre el formulario de promociones con la audiencia fija en el
  código.

### Tienda

- **"Mi cuenta" → "Mis códigos":** "Escribe tu código" con "Activar" (el error del servidor en el
  mismo lugar) y los códigos activos con lo que dan ("2x1 en Arroz extra 5 kg"), "Vence el 30
  nov" y "Te quedan 2 usos".
- **Carrito:** "¿Tienes un código?" lleva a activarlo y vuelve. Las líneas con promociones de un
  código dicen "Código VERANO-10". Si falta la compra mínima: "Con S/ 12.40 más se aplica tu
  código VERANO-10".

### Tests

El formulario (validaciones, condiciones, promociones del código); la tabla; activar con éxito y
con cada error; la lista de "Mis códigos"; el carrito con un código y con la compra mínima
pendiente; que todo entre en el teléfono.

## 9. Convenciones que se respetan

- Ningún dominio importa la lógica de otro: `promo_codes` le da a `promotions` lo que necesita
  (los canjes vigentes de un cliente) por una interfaz que recibe por constructor, como hoy
  `PromotionPricing` llega a `orders`.
- Montos en céntimos y como texto en el JSON; días de la tienda como `AAAA-MM-DD`.
- Los estados de pedido no cambian.
- En la app: Riverpod, go_router, repositorios detrás de interfaces y colores solo de `lib/theme/`.
