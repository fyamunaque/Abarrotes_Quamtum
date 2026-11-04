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
import '../promotions/promotion_labels.dart';
import '../promotions/promotions_routes.dart';
import 'promo_codes_service.dart';

/// Rutas de los códigos promocionales: activarlos y ver los propios, para
/// cualquier cuenta; la gestión del panel, con `promotions.manage`.
List<RouteEntry> promoCodesRoutes(
  PromoCodesService codes,
  Guards guards, {
  required ShopperResolver shoppers,
}) {
  Route staffOnly(Method method, ApiHandler handler) =>
      guards.require(Permission.promotionsManage, ApiRoute(method, handler));
  Route signedIn(Method method, ApiHandler handler) =>
      guards.signedIn(ApiRoute(method, handler));

  Map<String, Object?> json(PromoCodeSummary summary) =>
      promoCodeJson(summary, codes.now());

  return [
    (
      '/promo-codes/redeem',
      // Con el correo confirmado, como para pedir: el código queda a nombre
      // de la cuenta.
      signedIn(Method.post, (session, request) async {
        if (!request.firebaseIdentity.emailVerified) {
          return jsonError(
            403,
            'Confirma tu correo para activar códigos: te enviamos un enlace.',
          );
        }
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: const {'code'},
        );
        final code = body.text('code', maxLength: 40);
        body.check();

        final shopper = await shoppers.resolve(
          session,
          request.firebaseIdentity,
        );
        final redeemed = await codes.redeem(
          session,
          customer: request.currentUser,
          isVip: shopper.isVip,
          code: code!,
        );
        return jsonResponse(200, redeemedCodeJson(redeemed));
      }),
    ),
    (
      '/promo-codes/mine',
      signedIn(Method.get, (session, request) async {
        final mine = await codes.mine(session, request.currentUser);
        return jsonResponse(200, mine.map(redeemedCodeJson).toList());
      }),
    ),
    (
      '/promo-codes',
      staffOnly(Method.get, (session, request) async {
        final query = InputReader.query(
          request,
          allowed: {...PageQuery.fields, 'status', 'search'},
        );
        final page = PageQuery.read(query);
        final status = query.oneOf(
          'status',
          PromoCodeStatus.values,
          required: false,
        );
        final search = query.text('search', maxLength: 20, required: false);
        query.check();

        final (list, total) = await codes.list(
          session,
          page,
          status: status,
          search: search,
        );
        return jsonResponse(200, page.wrap(list.map(json).toList(), total));
      }),
    ),
    (
      '/promo-codes/:id',
      staffOnly(Method.get, (session, request) async {
        return jsonResponse(
          200,
          json(await codes.get(session, idParam(request))),
        );
      }),
    ),
    (
      '/promo-codes',
      staffOnly(Method.post, (session, request) async {
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: _fields,
        );
        final code = body.text('code', maxLength: 40);
        final startDate = body.day('startDate');
        final endDate = body.day('endDate');
        final limits = _readLimits(body);
        final eligibility = _readEligibility(body);
        final allowedEmails = _readAllowedEmails(body);
        // Sin promociones todavía: empieza apagado.
        final active = body.boolean('active', required: false) ?? false;
        final newCustomersOnly =
            body.boolean('newCustomersOnly', required: false) ?? false;
        body.check();

        final created = await codes.create(session, (
          code: code!,
          active: active,
          startDate: startDate!,
          endDate: endDate!,
          benefitDays: limits.benefitDays,
          maxRedemptions: limits.maxRedemptions,
          usesPerCustomer: limits.usesPerCustomer,
          minPurchaseCents: limits.minPurchaseCents,
          newCustomersOnly: newCustomersOnly,
          eligibility: eligibility ?? PromoCodeEligibility.everyone,
          allowedEmails: allowedEmails ?? const [],
        ));
        return jsonResponse(201, json(created));
      }),
    ),
    (
      '/promo-codes/:id',
      staffOnly(Method.patch, (session, request) async {
        final id = idParam(request);
        final body = InputReader.body(
          await readJsonBody(request),
          allowed: _fields,
        );
        final code = body.text('code', maxLength: 40, required: false);
        final active = body.boolean('active', required: false);
        final startDate = body.day('startDate', required: false);
        final endDate = body.day('endDate', required: false);
        final limits = _readLimits(body);
        final newCustomersOnly = body.boolean(
          'newCustomersOnly',
          required: false,
        );
        final eligibility = _readEligibility(body);
        final allowedEmails = _readAllowedEmails(body);
        body.check();

        // Un límite en null lo quita; sin el campo, queda como estaba.
        T keep<T>(String field, T value, T current) =>
            body.has(field) ? value : current;
        final updated = await codes.update(
          session,
          id,
          (current) => (
            code: code ?? current.code,
            active: active ?? current.active,
            startDate: startDate ?? current.startDate,
            endDate: endDate ?? current.endDate,
            benefitDays: keep(
              'benefitDays',
              limits.benefitDays,
              current.benefitDays,
            ),
            maxRedemptions: keep(
              'maxRedemptions',
              limits.maxRedemptions,
              current.maxRedemptions,
            ),
            usesPerCustomer: keep(
              'usesPerCustomer',
              limits.usesPerCustomer,
              current.usesPerCustomer,
            ),
            minPurchaseCents: keep(
              'minPurchase',
              limits.minPurchaseCents,
              current.minPurchaseCents,
            ),
            newCustomersOnly: newCustomersOnly ?? current.newCustomersOnly,
            eligibility: eligibility ?? current.eligibility,
            // Sin allowedEmails, los mismos mientras siga siendo de lista; si
            // pasa a otra condición, ninguno.
            allowedEmails:
                allowedEmails ??
                ((eligibility ?? current.eligibility) ==
                        PromoCodeEligibility.listed
                    ? current.allowedEmails
                    : const []),
          ),
        );
        return jsonResponse(200, json(updated));
      }),
    ),
    (
      '/promo-codes/:id',
      staffOnly(Method.delete, (session, request) async {
        await codes.delete(session, idParam(request));
        return Response.noContent();
      }),
    ),
  ];
}

const _fields = {
  'code',
  'active',
  'startDate',
  'endDate',
  'benefitDays',
  'maxRedemptions',
  'usesPerCustomer',
  'minPurchase',
  'newCustomersOnly',
  'eligibility',
  'allowedEmails',
};

/// Los límites, todos opcionales (null: sin límite).
({
  int? benefitDays,
  int? maxRedemptions,
  int? usesPerCustomer,
  int? minPurchaseCents,
})
_readLimits(InputReader body) => (
  benefitDays: body.integer(
    'benefitDays',
    min: 1,
    max: 365,
    required: false,
    nullable: true,
  ),
  maxRedemptions: body.integer(
    'maxRedemptions',
    min: 1,
    max: 1000000,
    required: false,
    nullable: true,
  ),
  usesPerCustomer: body.integer(
    'usesPerCustomer',
    min: 1,
    max: 1000,
    required: false,
    nullable: true,
  ),
  minPurchaseCents: body.cents(
    'minPurchase',
    minCents: 1,
    required: false,
    nullable: true,
  ),
);

PromoCodeEligibility? _readEligibility(InputReader body) =>
    body.oneOf('eligibility', PromoCodeEligibility.values, required: false);

/// Los correos de la lista, hasta 500 (se normalizan en el servicio).
List<String>? _readAllowedEmails(InputReader body) => body.strings(
  'allowedEmails',
  maxLength: 254,
  max: 500,
  required: false,
);

/// Un código activado como lo ve el cliente: hasta cuándo le sirve (un
/// instante), los pedidos en que todavía puede usarlo (null: sin límite),
/// la compra mínima y lo que da cada promoción.
Map<String, Object?> redeemedCodeJson(RedeemedCode redeemed) {
  final code = redeemed.redemption.promoCode!;
  return {
    'code': code.code,
    'expiresAt': redeemed.redemption.expiresAt.toUtc().toIso8601String(),
    'usesLeft': redeemed.usesLeft,
    'minPurchase': switch (code.minPurchaseCents) {
      final cents? => formatMoney(cents),
      null => null,
    },
    'promotions': [
      for (final promotion in code.promotions ?? const <Promotion>[])
        {
          'label': promotionLabel(promotion),
          'product': {
            'id': promotion.product!.id.toString(),
            'name': promotion.product!.name,
          },
        },
    ],
  };
}

/// Como lo lee el panel: el estado en minúsculas (`active`, `scheduled`,
/// `expired`, `paused`), días de la tienda, montos como texto y sus
/// promociones como las de `/promotions`.
Map<String, Object?> promoCodeJson(PromoCodeSummary summary, DateTime now) {
  final code = summary.code;
  final days = PromoCodesService.daysOf(code);
  return {
    'id': code.id.toString(),
    'code': code.code,
    'active': code.active,
    'status': PromoCodesService.statusOf(code, now).name,
    'startDate': days.startDate,
    'endDate': days.endDate,
    'benefitDays': code.benefitDays,
    'maxRedemptions': code.maxRedemptions,
    'usesPerCustomer': code.usesPerCustomer,
    'minPurchase': switch (code.minPurchaseCents) {
      final cents? => formatMoney(cents),
      null => null,
    },
    'newCustomersOnly': code.newCustomersOnly,
    'eligibility': code.eligibility.name,
    'allowedEmails': [
      for (final allowed
          in code.allowedEmails ?? const <PromoCodeAllowedEmail>[])
        allowed.email,
    ],
    'promotions': [
      for (final promotion in code.promotions ?? const <Promotion>[])
        promotionJson(promotion, now),
    ],
    'redemptions': summary.redemptions,
    'orders': summary.orders,
  };
}
