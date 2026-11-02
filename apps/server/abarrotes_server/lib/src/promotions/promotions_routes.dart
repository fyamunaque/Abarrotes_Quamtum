import 'package:serverpod/serverpod.dart';

import '../auth/firebase_auth_middleware.dart';
import '../auth/guards.dart';
import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/input_reader.dart';
import '../common/money.dart';
import '../common/pagination.dart';
import '../common/shopper.dart';
import '../generated/protocol.dart';
import 'promotion_labels.dart';
import 'promotion_rules.dart';
import 'promotions_service.dart';

/// Rutas de promociones: la gestión, con `promotions.manage`; y
/// `/promotions/active`, pública, con las que puede usar quien pregunta.
List<RouteEntry> promotionsRoutes(
  PromotionsService promotions,
  Guards guards, {
  required ShopperResolver shoppers,
}) {
  Route staffOnly(Method method, ApiHandler handler) =>
      guards.require(Permission.promotionsManage, ApiRoute(method, handler));

  Map<String, Object?> json(Promotion promotion) =>
      promotionJson(promotion, promotions.now());

  return [
    (
      '/promotions/active',
      // Pública: sin token (o con uno que no sirve), las de todos. Las de una
      // audiencia que el cliente no cumple no salen ni en el total.
      ApiRoute(Method.get, (session, request) async {
        final query = InputReader.query(request, allowed: PageQuery.fields);
        final page = PageQuery.read(query);
        query.check();

        final shopper = await shoppers.resolve(
          session,
          await optionalIdentity(guards.verifier, request),
        );
        final (list, total) = await promotions.activeFor(
          session,
          shopper,
          page,
        );
        return jsonResponse(
          200,
          page.wrap(list.map(activePromotionJson).toList(), total),
        );
      }),
    ),
    (
      '/promotions',
      staffOnly(Method.get, (session, request) async {
        final query = InputReader.query(
          request,
          allowed: {...PageQuery.fields, 'productId', 'status'},
        );
        final page = PageQuery.read(query);
        final productId = query.uuid('productId', required: false);
        final status = query.oneOf(
          'status',
          PromotionStatus.values,
          required: false,
        );
        query.check();

        final (list, total) = await promotions.list(
          session,
          page,
          productId: productId,
          status: status,
        );
        return jsonResponse(200, page.wrap(list.map(json).toList(), total));
      }),
    ),
    (
      '/promotions/:id',
      staffOnly(Method.get, (session, request) async {
        return jsonResponse(
          200,
          json(await promotions.get(session, idParam(request))),
        );
      }),
    ),
    (
      '/promotions',
      staffOnly(Method.post, (session, request) async {
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: {..._fields, 'productId', 'type'},
        );
        final productId = body.uuid('productId');
        final type =
            body.oneOf('type', PromotionType.values, required: false) ??
            PromotionType.specialPrice;
        final fields = _readTypeFields(body);
        final startDate = body.day('startDate');
        final endDate = body.day('endDate');
        final active = body.boolean('active', required: false) ?? true;
        final audience = _readAudience(body);
        final title = _readTitle(body);
        final recipientIds = _readRecipientIds(body);
        final confirmOverlap =
            body.boolean('confirmOverlap', required: false) ?? false;
        body.check();

        final promotion = await promotions.create(session, productId!, (
          type: type,
          promoPriceCents: fields.promoPriceCents,
          percent: fields.percent,
          buyQuantity: fields.buyQuantity,
          payQuantity: fields.payQuantity,
          giftProductId: fields.giftProductId,
          giftQuantity: fields.giftQuantity,
          startDate: startDate!,
          endDate: endDate!,
          active: active,
          audience: audience ?? PromotionAudience.everyone,
          title: title,
          recipientIds: recipientIds ?? const [],
          confirmOverlap: confirmOverlap,
        ));
        return jsonResponse(201, json(promotion));
      }),
    ),
    (
      '/promotions/:id',
      staffOnly(Method.patch, (session, request) async {
        final id = idParam(request);
        // El producto y el tipo no cambian: para otro, otra promoción.
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: _fields,
        );
        final fields = _readTypeFields(body);
        final startDate = body.day('startDate', required: false);
        final endDate = body.day('endDate', required: false);
        final active = body.boolean('active', required: false);
        final audience = _readAudience(body);
        final title = _readTitle(body);
        final recipientIds = _readRecipientIds(body);
        final confirmOverlap =
            body.boolean('confirmOverlap', required: false) ?? false;
        body.check();

        final promotion = await promotions.update(
          session,
          id,
          (current) => (
            type: current.type,
            promoPriceCents: fields.promoPriceCents ?? current.promoPriceCents,
            percent: fields.percent ?? current.percent,
            buyQuantity: fields.buyQuantity ?? current.buyQuantity,
            payQuantity: fields.payQuantity ?? current.payQuantity,
            giftProductId: fields.giftProductId ?? current.giftProductId,
            giftQuantity: fields.giftQuantity ?? current.giftQuantity,
            startDate: startDate ?? current.startDate,
            endDate: endDate ?? current.endDate,
            active: active ?? current.active,
            audience: audience ?? current.audience,
            // Un title en null lo borra.
            title: body.has('title') ? title : current.title,
            // Sin recipientIds, los mismos elegidos mientras siga siendo de
            // clientes elegidos; si pasa a otra audiencia, ninguno.
            recipientIds:
                recipientIds ??
                ((audience ?? current.audience) == PromotionAudience.selected
                    ? current.recipientIds
                    : const []),
            confirmOverlap: confirmOverlap,
          ),
        );
        return jsonResponse(200, json(promotion));
      }),
    ),
    (
      '/promotions/:id',
      staffOnly(Method.delete, (session, request) async {
        await promotions.delete(session, idParam(request));
        return Response.noContent();
      }),
    ),
  ];
}

const _fields = {
  'promoPrice',
  'percent',
  'buyQuantity',
  'payQuantity',
  'giftProductId',
  'giftQuantity',
  'startDate',
  'endDate',
  'active',
  'audience',
  'title',
  'recipientIds',
  'confirmOverlap',
};

/// Los campos de cada tipo, todos opcionales aquí: cuáles lleva cada tipo
/// y sus rangos los revisa `PromotionsService`. El precio promocional, de
/// 0.01 en adelante.
({
  int? promoPriceCents,
  int? percent,
  int? buyQuantity,
  int? payQuantity,
  UuidValue? giftProductId,
  int? giftQuantity,
})
_readTypeFields(InputReader body) => (
  promoPriceCents: body.cents('promoPrice', minCents: 1, required: false),
  percent: body.integer('percent', required: false),
  buyQuantity: body.integer('buyQuantity', required: false),
  payQuantity: body.integer('payQuantity', required: false),
  giftProductId: body.uuid('giftProductId', required: false),
  giftQuantity: body.integer('giftQuantity', required: false),
);

/// A quién va dirigida: `everyone` (por defecto), `vip` o `selected` (los
/// VIP de `recipientIds`).
PromotionAudience? _readAudience(InputReader body) =>
    body.oneOf('audience', PromotionAudience.values, required: false);

/// Los clientes VIP elegidos (sus ids), de 1 a 100.
List<UuidValue>? _readRecipientIds(InputReader body) {
  final ids = body.strings(
    'recipientIds',
    maxLength: 36,
    min: 1,
    max: 100,
    required: false,
  );
  if (ids == null) return null;
  final parsed = <UuidValue>[];
  for (final (i, id) in ids.indexed) {
    if (parseUuid(id) case final uuid?) {
      parsed.add(uuid);
    } else {
      body.reject('recipientIds[$i] debe ser un UUID');
    }
  }
  return parsed;
}

/// Un nombre para mostrar (p. ej. "Semana del arroz"), opcional.
String? _readTitle(InputReader body) =>
    body.text('title', maxLength: 100, nullable: true);

/// Como lo lee el panel (`Promotion.fromJson`), con el estado en minúsculas
/// (`scheduled`, `active`, `expired`, `disabled`).
Map<String, Object?> promotionJson(Promotion promotion, DateTime now) {
  final product = promotion.product!;
  final days = toDayPeriod(promotion.startDate, promotion.endDate);
  return {
    'id': promotion.id.toString(),
    'productId': promotion.productId.toString(),
    'product': {
      'id': product.id.toString(),
      'name': product.name,
      'sku': product.sku,
      'price': formatMoney(product.priceCents),
    },
    ..._typeJson(promotion),
    'startDate': days.startDate,
    'endDate': days.endDate,
    'active': promotion.active,
    'status': promotionStatus(promotion, now).name,
    'audience': promotion.audience.name,
    'title': promotion.title,
    // Con la audiencia selected: los clientes VIP elegidos, por correo.
    'recipients': [
      for (final vip in [
        for (final recipient
            in promotion.recipients ?? const <PromotionRecipient>[])
          recipient.vipCustomer!,
      ]..sort((a, b) => a.email.compareTo(b.email)))
        {'id': vip.id.toString(), 'email': vip.email},
    ],
  };
}

/// El tipo y sus campos, con el nombre para las personas (`label`). Los
/// que no son del tipo van en null.
Map<String, Object?> _typeJson(Promotion promotion) => {
  'type': promotion.type.name,
  'label': promotionLabel(promotion),
  'promoPrice': switch (promotion.promoPriceCents) {
    final cents? => formatMoney(cents),
    null => null,
  },
  'percent': promotion.percent,
  'buyQuantity': promotion.buyQuantity,
  'payQuantity': promotion.payQuantity,
  'giftProduct': switch (promotion.giftProduct) {
    final gift? => {'id': gift.id.toString(), 'name': gift.name},
    null => null,
  },
  'giftQuantity': promotion.giftQuantity,
};

/// Una promoción vigente como la ven los clientes: con el producto y su
/// precio normal, sin datos internos (sku, estado).
Map<String, Object?> activePromotionJson(Promotion promotion) {
  final product = promotion.product!;
  final days = toDayPeriod(promotion.startDate, promotion.endDate);
  return {
    'id': promotion.id.toString(),
    'title': promotion.title,
    'audience': promotion.audience.name,
    ..._typeJson(promotion),
    'startDate': days.startDate,
    'endDate': days.endDate,
    'product': {
      'id': product.id.toString(),
      'name': product.name,
      'price': formatMoney(product.priceCents),
      'imageUrl': product.imageUrl,
      // Para que la app le dé el color de su categoría si no tiene foto.
      'categoryId': product.categoryId.toString(),
    },
  };
}
