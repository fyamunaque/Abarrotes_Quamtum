import 'package:serverpod/serverpod.dart' hide Order;

import '../common/api_route.dart';
import '../common/emails.dart';
import '../common/http_json.dart';
import '../common/pagination.dart';
import '../common/store_time.dart';
import '../generated/protocol.dart';

/// En qué está un código hoy. Se deduce de las fechas y del interruptor; no
/// se guarda.
enum PromoCodeStatus { active, scheduled, expired, paused }

/// [text] como se guarda: sin espacios en los extremos y en mayúsculas. El
/// cliente lo escribe como quiera y vale igual.
String normalizePromoCode(String text) => text.trim().toUpperCase();

/// De 3 a 20 letras, números o guiones (ya normalizado).
bool isValidPromoCode(String code) => _codePattern.hasMatch(code);

final _codePattern = RegExp(r'^[A-Z0-9-]{3,20}$');

/// Un código tal como llega en el body (días de la tienda), ya normalizado
/// por [PromoCodesService]. [allowedEmails], solo con `listed`.
typedef PromoCodeInput = ({
  String code,
  bool active,
  String startDate,
  String endDate,
  int? benefitDays,
  int? maxRedemptions,
  int? usesPerCustomer,
  int? minPurchaseCents,
  bool newCustomersOnly,
  PromoCodeEligibility eligibility,
  List<String> allowedEmails,
});

/// Un código con lo que muestra el panel: cuántos clientes lo activaron y
/// en cuántos pedidos (no cancelados) se usó.
typedef PromoCodeSummary = ({PromoCode code, int redemptions, int orders});

/// Los códigos promocionales del panel. Sus promociones (audiencia `code`)
/// se crean y editan con `/promotions`.
class PromoCodesService {
  PromoCodesService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  DateTime now() => _now().toUtc();

  static PromoCodeStatus statusOf(PromoCode code, DateTime now) {
    if (!code.active) return PromoCodeStatus.paused;
    if (now.isBefore(code.startDate)) return PromoCodeStatus.scheduled;
    if (!now.isBefore(code.endDate)) return PromoCodeStatus.expired;
    return PromoCodeStatus.active;
  }

  static Expression _statusWhere(
    PromoCodeTable code,
    PromoCodeStatus status,
    DateTime now,
  ) => switch (status) {
    PromoCodeStatus.paused => code.active.equals(false),
    PromoCodeStatus.scheduled =>
      code.active.equals(true) & (code.startDate > now),
    PromoCodeStatus.expired => code.active.equals(true) & (code.endDate <= now),
    PromoCodeStatus.active =>
      code.active.equals(true) & (code.startDate <= now) & (code.endDate > now),
  };

  /// Los creados más recientemente primero.
  Future<(List<PromoCodeSummary>, int)> list(
    Session session,
    PageQuery page, {
    PromoCodeStatus? status,
    String? search,
  }) async {
    final now = this.now();
    Expression where(PromoCodeTable code) {
      Expression filter = Constant.bool(true);
      if (status != null) filter &= _statusWhere(code, status, now);
      if (search != null && search.trim().isNotEmpty) {
        filter &= code.code.ilike('%${escapeLike(search.trim())}%');
      }
      return filter;
    }

    final codes = await PromoCode.db.find(
      session,
      where: where,
      orderByList: (code) => [code.createdAt.desc(), code.id.desc()],
      limit: page.limit,
      offset: page.offset,
      include: _include,
    );
    final total = await PromoCode.db.count(session, where: where);
    return ([for (final code in codes) await _summary(session, code)], total);
  }

  Future<PromoCodeSummary> get(Session session, UuidValue id) async =>
      _summary(session, await _find(session, id));

  Future<PromoCode> _find(Session session, UuidValue id) async {
    final code = await PromoCode.db.findById(session, id, include: _include);
    if (code == null) {
      throw const ApiException(404, 'Código no encontrado');
    }
    return code;
  }

  Future<PromoCodeSummary> _summary(Session session, PromoCode code) async => (
    code: code,
    redemptions: await _redemptions(session, code.id!),
    orders: await OrderPromoCodeUse.db.count(
      session,
      where: (use) =>
          use.redemption.promoCodeId.equals(code.id) &
          use.order.status.notEquals(OrderStatus.cancelled),
    ),
  );

  Future<int> _redemptions(Session session, UuidValue id) =>
      PromoCodeRedemption.db.count(
        session,
        where: (redemption) => redemption.promoCodeId.equals(id),
      );

  /// Sin promociones todavía, el código empieza apagado: se enciende al
  /// agregarle al menos una.
  Future<PromoCodeSummary> create(Session session, PromoCodeInput raw) async {
    final input = _normalized(raw);
    await _validate(session, input);

    final created = await session.db.transaction((transaction) async {
      final created = await PromoCode.db.insertRow(
        session,
        _apply(
          PromoCode(code: input.code, startDate: now(), endDate: now()),
          input,
        ),
        transaction: transaction,
      );
      await _saveEmails(session, created.id!, input, transaction);
      return created;
    });
    return get(session, created.id!);
  }

  /// Aplica [changes] al código actual y valida tal como quedaría. Si
  /// alguien ya lo activó, el texto no cambia.
  Future<PromoCodeSummary> update(
    Session session,
    UuidValue id,
    PromoCodeInput Function(PromoCodeInput current) changes,
  ) async {
    final current = await _find(session, id);
    final days = daysOf(current);
    final input = _normalized(
      changes((
        code: current.code,
        active: current.active,
        startDate: days.startDate,
        endDate: days.endDate,
        benefitDays: current.benefitDays,
        maxRedemptions: current.maxRedemptions,
        usesPerCustomer: current.usesPerCustomer,
        minPurchaseCents: current.minPurchaseCents,
        newCustomersOnly: current.newCustomersOnly,
        eligibility: current.eligibility,
        allowedEmails: [
          for (final allowed
              in current.allowedEmails ?? const <PromoCodeAllowedEmail>[])
            allowed.email,
        ],
      )),
    );
    if (input.code != current.code && await _redemptions(session, id) > 0) {
      throw const ApiException.conflict(
        'El código ya se activó: no se puede cambiar el texto',
      );
    }
    await _validate(
      session,
      input,
      exceptId: id,
      promotions: current.promotions?.length ?? 0,
    );

    await session.db.transaction((transaction) async {
      await PromoCode.db.updateRow(
        session,
        _apply(current, input),
        transaction: transaction,
      );
      await PromoCodeAllowedEmail.db.deleteWhere(
        session,
        where: (allowed) => allowed.promoCodeId.equals(id),
        transaction: transaction,
      );
      await _saveEmails(session, id, input, transaction);
    });
    return get(session, id);
  }

  /// Borra el código con sus promociones. Si alguien ya lo activó, no: se
  /// apaga (los canjes y los pedidos lo nombran).
  Future<void> delete(Session session, UuidValue id) async {
    final code = await _find(session, id);
    if (await _redemptions(session, id) > 0) {
      throw const ApiException.conflict(
        'El código ya se activó: apágalo en vez de borrarlo',
      );
    }
    await session.db.transaction((transaction) async {
      await Promotion.db.deleteWhere(
        session,
        where: (promotion) => promotion.promoCodeId.equals(id),
        transaction: transaction,
      );
      await PromoCode.db.deleteRow(session, code, transaction: transaction);
    });
  }

  /// El texto en mayúsculas y los correos normalizados, sin repetir.
  static PromoCodeInput _normalized(PromoCodeInput input) => (
    code: normalizePromoCode(input.code),
    active: input.active,
    startDate: input.startDate,
    endDate: input.endDate,
    benefitDays: input.benefitDays,
    maxRedemptions: input.maxRedemptions,
    usesPerCustomer: input.usesPerCustomer,
    minPurchaseCents: input.minPurchaseCents,
    newCustomersOnly: input.newCustomersOnly,
    eligibility: input.eligibility,
    allowedEmails: [
      ...{for (final email in input.allowedEmails) normalizeEmail(email)},
    ]..sort(),
  );

  /// Reglas de negocio:
  /// - El texto, de 3 a 20 letras, números o guiones, y único.
  /// - El último día no puede ser anterior al primero.
  /// - Con `listed`, al menos un correo, todos válidos; con otra
  ///   condición, ninguno.
  /// - Encendido, con al menos una promoción.
  Future<void> _validate(
    Session session,
    PromoCodeInput input, {
    UuidValue? exceptId,
    int promotions = 0,
  }) async {
    if (!isValidPromoCode(input.code)) {
      throw const ApiException.badRequest(
        'code debe tener de 3 a 20 letras, números o guiones',
      );
    }
    if (input.endDate.compareTo(input.startDate) < 0) {
      throw const ApiException.badRequest(
        'endDate no puede ser anterior a startDate',
      );
    }
    if (input.eligibility == PromoCodeEligibility.listed) {
      if (input.allowedEmails.isEmpty) {
        throw const ApiException.badRequest('Escribe al menos un correo');
      }
      final invalid = [
        for (final email in input.allowedEmails)
          if (!isValidEmail(email)) email,
      ];
      if (invalid.isNotEmpty) {
        throw ApiException.badRequest(
          'Algún correo no es válido: ${invalid.join(', ')}',
        );
      }
    } else if (input.allowedEmails.isNotEmpty) {
      throw const ApiException.badRequest(
        'allowedEmails solo va con eligibility listed',
      );
    }
    if (input.active && promotions == 0) {
      throw const ApiException.badRequest(
        'Agrega al menos una promoción antes de encender el código',
      );
    }
    final same = await PromoCode.db.findFirstRow(
      session,
      where: (code) => exceptId == null
          ? code.code.equals(input.code)
          : code.code.equals(input.code) & code.id.notEquals(exceptId),
    );
    if (same != null) {
      throw ApiException.conflict('Ya existe el código ${input.code}');
    }
  }

  PromoCode _apply(PromoCode code, PromoCodeInput input) => code.copyWith(
    code: input.code,
    active: input.active,
    startDate: storeDayStart(input.startDate),
    endDate: storeDayStart(addDays(input.endDate, 1)),
    benefitDays: input.benefitDays,
    maxRedemptions: input.maxRedemptions,
    usesPerCustomer: input.usesPerCustomer,
    minPurchaseCents: input.minPurchaseCents,
    newCustomersOnly: input.newCustomersOnly,
    eligibility: input.eligibility,
  );

  Future<void> _saveEmails(
    Session session,
    UuidValue id,
    PromoCodeInput input,
    Transaction transaction,
  ) async {
    if (input.allowedEmails.isEmpty) return;
    await PromoCodeAllowedEmail.db.insert(session, [
      for (final email in input.allowedEmails)
        PromoCodeAllowedEmail(promoCodeId: id, email: email),
    ], transaction: transaction);
  }

  /// Los instantes guardados como días de la tienda, ambos incluidos.
  static ({String startDate, String endDate}) daysOf(PromoCode code) => (
    startDate: storeDay(code.startDate),
    endDate: addDays(storeDay(code.endDate), -1),
  );

  static final _include = PromoCode.include(
    allowedEmails: PromoCodeAllowedEmail.includeList(
      orderBy: (allowed) => allowed.email,
    ),
    promotions: Promotion.includeList(
      orderBy: (promotion) => promotion.id,
      include: Promotion.include(
        product: Product.include(),
        giftProduct: Product.include(),
        promoCode: PromoCode.include(),
        recipients: PromotionRecipient.includeList(
          include: PromotionRecipient.include(
            vipCustomer: VipCustomer.include(),
          ),
        ),
      ),
    ),
  );
}
