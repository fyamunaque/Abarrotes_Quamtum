import 'package:serverpod/serverpod.dart';

import '../common/http_json.dart';
import '../common/money.dart';
import '../common/pagination.dart';
import '../common/shopper.dart';
import '../generated/protocol.dart';
import 'audience/promotion_audience_rule.dart';
import 'promotion_pricing.dart';
import 'promotion_rules.dart';

/// Datos de una promoción tal como llegan en el body (días de la tienda).
typedef PromotionInput = ({
  int promoPriceCents,
  String startDate,
  String endDate,
  bool active,
  PromotionAudience audience,
  String? title,
});

/// Promociones: las del dashboard y, según las reglas de audiencia, las que
/// puede usar cada cliente ([PromotionPricing]).
class PromotionsService implements PromotionPricing {
  /// [audienceRules] decide quién usa cada audiencia: una audiencia sin regla
  /// no la usa nadie.
  PromotionsService({
    required List<PromotionAudienceRule> audienceRules,
    DateTime Function()? now,
  }) : _audienceRules = List.unmodifiable(audienceRules),
       _now = now ?? DateTime.now;

  final List<PromotionAudienceRule> _audienceRules;
  final DateTime Function() _now;

  DateTime now() => _now().toUtc();

  /// Las audiencias cuyas promociones puede usar [shopper].
  Set<PromotionAudience> audiencesFor(Shopper shopper) => {
    for (final rule in _audienceRules)
      if (rule.isEligible(shopper)) rule.audience,
  };

  @override
  Expression eligibleWhere(
    PromotionTable promotion,
    DateTime now,
    Shopper shopper,
  ) =>
      activePromotionWhere(promotion, now) &
      promotion.audience.inSet(audiencesFor(shopper));

  @override
  PromotionIncludeList bestFor(DateTime now, Shopper shopper) =>
      Promotion.includeList(
        where: (promotion) => eligibleWhere(promotion, now, shopper),
        orderByList: (promotion) => [
          promotion.promoPriceCents.asc(),
          promotion.id.asc(),
        ],
        limit: 1,
      );

  /// Las vigentes que [shopper] puede usar, de productos activos: por nombre
  /// del producto y, en el mismo producto, la más barata primero.
  Future<(List<Promotion>, int)> activeFor(
    Session session,
    Shopper shopper,
    PageQuery page,
  ) async {
    final now = this.now();
    Expression where(PromotionTable promotion) =>
        eligibleWhere(promotion, now, shopper) &
        promotion.product.active.equals(true);

    final promotions = await Promotion.db.find(
      session,
      where: where,
      orderByList: (promotion) => [
        promotion.product.name.asc(),
        promotion.promoPriceCents.asc(),
        promotion.id.asc(),
      ],
      limit: page.limit,
      offset: page.offset,
      include: _include,
    );
    final total = await Promotion.db.count(session, where: where);
    return (promotions, total);
  }

  /// Las de inicio más reciente primero.
  Future<(List<Promotion>, int)> list(
    Session session,
    PageQuery page, {
    UuidValue? productId,
    PromotionStatus? status,
  }) async {
    final now = this.now();
    Expression where(PromotionTable promotion) {
      Expression filter = Constant.bool(true);
      if (productId != null) filter &= promotion.productId.equals(productId);
      if (status != null) {
        filter &= promotionStatusWhere(promotion, status, now);
      }
      return filter;
    }

    final promotions = await Promotion.db.find(
      session,
      where: where,
      orderByList: (promotion) => [
        promotion.startDate.desc(),
        promotion.id.desc(),
      ],
      limit: page.limit,
      offset: page.offset,
      include: _include,
    );
    final total = await Promotion.db.count(session, where: where);
    return (promotions, total);
  }

  Future<Promotion> get(Session session, UuidValue id) async {
    final promotion = await Promotion.db.findById(
      session,
      id,
      include: _include,
    );
    if (promotion == null) {
      throw const ApiException(404, 'Promoción no encontrada');
    }
    return promotion;
  }

  Future<Promotion> create(
    Session session,
    UuidValue productId,
    PromotionInput input,
  ) async {
    final product = await Product.db.findById(session, productId);
    if (product == null) {
      throw const ApiException.badRequest('El producto indicado no existe');
    }
    await _validate(session, product, input);

    final period = toStoredPeriod(input.startDate, input.endDate);
    final created = await Promotion.db.insertRow(
      session,
      Promotion(
        productId: productId,
        promoPriceCents: input.promoPriceCents,
        startDate: period.startDate,
        endDate: period.endDate,
        active: input.active,
        audience: input.audience,
        title: input.title,
      ),
    );
    return get(session, created.id!);
  }

  /// Aplica [changes] a la promoción actual. Se valida tal como quedaría.
  Future<Promotion> update(
    Session session,
    UuidValue id,
    PromotionInput Function(PromotionInput current) changes,
  ) async {
    final current = await get(session, id);
    final days = toDayPeriod(current.startDate, current.endDate);
    final input = changes((
      promoPriceCents: current.promoPriceCents,
      startDate: days.startDate,
      endDate: days.endDate,
      active: current.active,
      audience: current.audience,
      title: current.title,
    ));
    await _validate(session, current.product!, input, exceptId: id);

    final period = toStoredPeriod(input.startDate, input.endDate);
    await Promotion.db.updateRow(
      session,
      current.copyWith(
        promoPriceCents: input.promoPriceCents,
        startDate: period.startDate,
        endDate: period.endDate,
        active: input.active,
        audience: input.audience,
        title: input.title,
      ),
    );
    return get(session, id);
  }

  /// Borra la promoción. Los pedidos guardan su precio, así que no se ven
  /// afectados.
  Future<void> delete(Session session, UuidValue id) async {
    await Promotion.db.deleteRow(session, await get(session, id));
  }

  /// Reglas de negocio:
  /// - El último día no puede ser anterior al primero.
  /// - El precio promocional tiene que ser menor al precio normal.
  /// - Dos promociones encendidas del mismo producto y la misma audiencia no
  ///   pueden cruzarse en el tiempo. De audiencias distintas sí (una para
  ///   todos y otra VIP): cada cliente paga la más barata de las que puede
  ///   usar.
  Future<void> _validate(
    Session session,
    Product product,
    PromotionInput input, {
    UuidValue? exceptId,
  }) async {
    if (input.endDate.compareTo(input.startDate) < 0) {
      throw const ApiException.badRequest(
        'endDate no puede ser anterior a startDate',
      );
    }
    if (input.promoPriceCents >= product.priceCents) {
      throw ApiException.badRequest(
        'El precio promocional debe ser menor al precio normal '
        '(${formatMoney(product.priceCents)})',
      );
    }
    if (!input.active) return;

    final period = toStoredPeriod(input.startDate, input.endDate);
    final overlapping = await Promotion.db.findFirstRow(
      session,
      where: (promotion) {
        final crosses =
            promotion.productId.equals(product.id) &
            promotion.audience.equals(input.audience) &
            promotion.active.equals(true) &
            (promotion.startDate < period.endDate) &
            (promotion.endDate > period.startDate);
        return exceptId == null
            ? crosses
            : crosses & promotion.id.notEquals(exceptId);
      },
    );
    if (overlapping != null) {
      final days = toDayPeriod(overlapping.startDate, overlapping.endDate);
      final kind = input.audience == PromotionAudience.everyone
          ? 'una promoción'
          : 'una promoción ${input.audience.name.toUpperCase()}';
      throw ApiException.conflict(
        '${product.name} ya tiene $kind del ${days.startDate} al '
        '${days.endDate} que se cruza con esas fechas',
      );
    }
  }

  static final _include = Promotion.include(product: Product.include());
}
