import 'package:serverpod/serverpod.dart';

import '../auth/firebase_token_verifier.dart';
import '../auth/role_guard.dart';
import '../common/api_route.dart';
import '../common/http_json.dart';
import '../common/input_reader.dart';
import '../common/money.dart';
import '../common/pagination.dart';
import '../generated/protocol.dart';
import 'promotion_rules.dart';
import 'promotions_service.dart';

/// Rutas de promociones: todas solo para admin y staff. El marketplace y la
/// app ven la promoción vigente dentro de cada producto.
List<RouteEntry> promotionsRoutes(
  PromotionsService promotions,
  FirebaseTokenVerifier verifier,
) {
  Route staffOnly(Method method, ApiHandler handler) =>
      RoleGuard(staffRoles, ApiRoute(method, handler), verifier: verifier);

  Map<String, Object?> json(Promotion promotion) =>
      promotionJson(promotion, promotions.now());

  return [
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
          allowed: {..._fields, 'productId'},
        );
        final productId = body.uuid('productId');
        final promoPriceCents = _readPromoPrice(body, required: true);
        final startDate = body.day('startDate');
        final endDate = body.day('endDate');
        final active = body.boolean('active', required: false) ?? true;
        body.check();

        final promotion = await promotions.create(session, productId!, (
          promoPriceCents: promoPriceCents!,
          startDate: startDate!,
          endDate: endDate!,
          active: active,
        ));
        return jsonResponse(201, json(promotion));
      }),
    ),
    (
      '/promotions/:id',
      staffOnly(Method.patch, (session, request) async {
        final id = idParam(request);
        // El producto no cambia: para otro producto, otra promoción.
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: _fields,
        );
        final promoPriceCents = _readPromoPrice(body, required: false);
        final startDate = body.day('startDate', required: false);
        final endDate = body.day('endDate', required: false);
        final active = body.boolean('active', required: false);
        body.check();

        final promotion = await promotions.update(
          session,
          id,
          promoPriceCents: promoPriceCents,
          startDate: startDate,
          endDate: endDate,
          active: active,
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

const _fields = {'promoPrice', 'startDate', 'endDate', 'active'};

/// El precio promocional, de 0.01 en adelante.
int? _readPromoPrice(InputReader body, {required bool required}) =>
    body.cents('promoPrice', minCents: 1, required: required);

/// Como el `Promotion` de packages/shared-types, con el estado en minúsculas
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
    'promoPrice': formatMoney(promotion.promoPriceCents),
    'startDate': days.startDate,
    'endDate': days.endDate,
    'active': promotion.active,
    'status': promotionStatus(promotion, now).name,
  };
}
