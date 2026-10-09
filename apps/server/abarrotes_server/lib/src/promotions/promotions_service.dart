import 'package:serverpod/serverpod.dart';

import '../common/http_json.dart';
import '../common/money.dart';
import '../common/pagination.dart';
import '../generated/protocol.dart';
import 'promotion_rules.dart';

/// Datos de una promoción tal como llegan en el body (días de la tienda).
typedef PromotionInput = ({
  int promoPriceCents,
  String startDate,
  String endDate,
  bool active,
});

/// Promociones del dashboard.
class PromotionsService {
  PromotionsService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  DateTime now() => _now().toUtc();

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
      ),
    );
    return get(session, created.id!);
  }

  /// Aplica los cambios de [changes] (los campos en null no cambian). Se valida
  /// la promoción tal como quedaría.
  Future<Promotion> update(
    Session session,
    UuidValue id, {
    int? promoPriceCents,
    String? startDate,
    String? endDate,
    bool? active,
  }) async {
    final current = await get(session, id);
    final days = toDayPeriod(current.startDate, current.endDate);
    final input = (
      promoPriceCents: promoPriceCents ?? current.promoPriceCents,
      startDate: startDate ?? days.startDate,
      endDate: endDate ?? days.endDate,
      active: active ?? current.active,
    );
    await _validate(session, current.product!, input, exceptId: id);

    final period = toStoredPeriod(input.startDate, input.endDate);
    await Promotion.db.updateRow(
      session,
      current.copyWith(
        promoPriceCents: input.promoPriceCents,
        startDate: period.startDate,
        endDate: period.endDate,
        active: input.active,
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
  /// - Dos promociones encendidas del mismo producto no pueden cruzarse en el
  ///   tiempo; si no, no habría un único precio vigente para cobrar.
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
      throw ApiException.conflict(
        '${product.name} ya tiene una promoción del ${days.startDate} al '
        '${days.endDate} que se cruza con esas fechas',
      );
    }
  }

  static final _include = Promotion.include(product: Product.include());
}
