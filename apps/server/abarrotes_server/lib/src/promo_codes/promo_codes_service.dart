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

/// Un código activado, con el código y sus promociones, y los pedidos en
/// que todavía puede usarse (null: sin límite).
typedef RedeemedCode = ({PromoCodeRedemption redemption, int? usesLeft});

/// Un código con lo que muestra el panel: cuántos clientes lo activaron y
/// en cuántos pedidos (no cancelados) se usó.
typedef PromoCodeSummary = ({PromoCode code, int redemptions, int orders});

/// Los códigos promocionales del panel. Sus promociones (audiencia `code`)
/// se crean y editan con `/promotions`.
class PromoCodesService {
  PromoCodesService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  DateTime now() => _now().toUtc();

  /// Hasta cuándo le sirve [code] a quien lo activó en [activatedAt]: con
  /// `benefitDays`, esos días desde la activación, sin pasar del fin del
  /// código; sin ellos, hasta el fin. Se calcula con el código de ahora:
  /// si el administrador cambia la vigencia o los días, cambia también para
  /// quienes ya lo activaron.
  static DateTime expiryOf(DateTime activatedAt, PromoCode code) {
    final benefitEnd = switch (code.benefitDays) {
      final days? => activatedAt.add(Duration(days: days)),
      null => code.endDate,
    };
    return benefitEnd.isBefore(code.endDate) ? benefitEnd : code.endDate;
  }

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
      activePromotions: [
        for (final promotion in current.promotions ?? const <Promotion>[])
          if (promotion.active) promotion,
      ].length,
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

  /// Activa [code] (escrito como sea) para [customer]. Para no revelar qué
  /// códigos existen, uno que no existe, apagado o fuera de fechas da el
  /// mismo 404. La fila del código se bloquea antes de contar sus canjes:
  /// dos activaciones a la vez no pasan `maxRedemptions`. El beneficio dura
  /// `benefitDays` días desde ahora, nunca más allá del fin del código.
  Future<RedeemedCode> redeem(
    Session session, {
    required User customer,
    required bool isVip,
    required String code,
  }) async {
    final text = normalizePromoCode(code);
    final now = this.now();
    final id = await session.db.transaction((transaction) async {
      final found = await PromoCode.db.findFirstRow(
        session,
        where: (promoCode) => promoCode.code.equals(text),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (found == null || statusOf(found, now) != PromoCodeStatus.active) {
        throw const ApiException(
          404,
          'El código no existe o ya no está vigente',
        );
      }
      final already = await PromoCodeRedemption.db.count(
        session,
        where: (redemption) =>
            redemption.promoCodeId.equals(found.id) &
            redemption.userId.equals(customer.id),
        transaction: transaction,
      );
      if (already > 0) {
        throw const ApiException.conflict('Ya activaste este código');
      }
      if (found.maxRedemptions case final max?) {
        final taken = await PromoCodeRedemption.db.count(
          session,
          where: (redemption) => redemption.promoCodeId.equals(found.id),
          transaction: transaction,
        );
        if (taken >= max) {
          throw const ApiException.conflict(
            'Se acabaron los canjes de este código',
          );
        }
      }
      await _checkConditions(session, found, customer, isVip, transaction);

      final redemption = await PromoCodeRedemption.db.insertRow(
        session,
        PromoCodeRedemption(
          promoCodeId: found.id!,
          userId: customer.id!,
          activatedAt: now,
          // Cómo quedó al activarlo; lo que vale es expiryOf.
          expiresAt: expiryOf(now, found),
        ),
        transaction: transaction,
      );
      return redemption.id!;
    });
    return _redeemed(session, id);
  }

  /// Las condiciones del código: cuál no cumple [customer], con su mensaje.
  Future<void> _checkConditions(
    Session session,
    PromoCode code,
    User customer,
    bool isVip,
    Transaction transaction,
  ) async {
    if (code.newCustomersOnly) {
      final orders = await Order.db.count(
        session,
        where: (order) =>
            order.customerId.equals(customer.id) &
            order.status.notEquals(OrderStatus.cancelled),
        transaction: transaction,
      );
      if (orders > 0) {
        throw const ApiException.forbidden(
          'Este código es solo para clientes nuevos',
        );
      }
    }
    switch (code.eligibility) {
      case PromoCodeEligibility.everyone:
        break;
      case PromoCodeEligibility.vip when !isVip:
        throw const ApiException.forbidden(
          'Este código es solo para clientes VIP',
        );
      case PromoCodeEligibility.vip:
        break;
      case PromoCodeEligibility.listed:
        final listed = await PromoCodeAllowedEmail.db.count(
          session,
          where: (allowed) =>
              allowed.promoCodeId.equals(code.id) &
              allowed.email.equals(normalizeEmail(customer.email)),
          transaction: transaction,
        );
        if (listed == 0) {
          throw const ApiException.forbidden(
            'Este código no está disponible para tu cuenta',
          );
        }
    }
  }

  /// Los códigos que [customer] activó y todavía le sirven: el código
  /// encendido, sin vencer y con usos. Los que vencen antes, primero.
  Future<List<RedeemedCode>> mine(Session session, User customer) async {
    final now = this.now();
    final redemptions = await PromoCodeRedemption.db.find(
      session,
      where: (redemption) =>
          redemption.userId.equals(customer.id) &
          redemption.promoCode.active.equals(true),
      orderBy: (redemption) => redemption.id,
    );
    return [
      for (final redemption in redemptions)
        if (await _redeemed(session, redemption.id!) case final redeemed
            when redeemed.usesLeft != 0 &&
                redeemed.redemption.expiresAt.isAfter(now))
          redeemed,
    ]..sort(
      (a, b) => a.redemption.expiresAt.compareTo(b.redemption.expiresAt),
    );
  }

  Future<RedeemedCode> _redeemed(Session session, UuidValue id) async {
    final now = this.now();
    final redemption = (await PromoCodeRedemption.db.findById(
      session,
      id,
      include: PromoCodeRedemption.include(
        promoCode: PromoCode.include(
          // Solo las que valen hoy: encendidas, en fecha y de productos que
          // se venden.
          promotions: Promotion.includeList(
            where: (promotion) =>
                promotion.active.equals(true) &
                (promotion.startDate <= now) &
                (promotion.endDate > now) &
                promotion.product.active.equals(true),
            orderBy: (promotion) => promotion.id,
            include: Promotion.include(
              product: Product.include(),
              giftProduct: Product.include(),
            ),
          ),
        ),
      ),
    ))!;
    final code = redemption.promoCode!;
    final limit = code.usesPerCustomer;
    return (
      // Con el vencimiento de ahora (ver expiryOf).
      redemption: redemption.copyWith(
        expiresAt: expiryOf(redemption.activatedAt, code),
      ),
      usesLeft: limit == null
          ? null
          : (limit - await usesOf(session, id)).clamp(0, limit),
    );
  }

  /// En cuántos pedidos (no cancelados) se usó el canje [redemptionId].
  static Future<int> usesOf(
    Session session,
    UuidValue redemptionId, {
    Transaction? transaction,
  }) => OrderPromoCodeUse.db.count(
    session,
    where: (use) =>
        use.redemptionId.equals(redemptionId) &
        use.order.status.notEquals(OrderStatus.cancelled),
    transaction: transaction,
  );

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
  /// - Encendido, con al menos una promoción encendida.
  Future<void> _validate(
    Session session,
    PromoCodeInput input, {
    UuidValue? exceptId,
    int promotions = 0,
    int activePromotions = 0,
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
    if (input.active && activePromotions == 0) {
      throw const ApiException.badRequest(
        'Enciende al menos una de sus promociones antes de encender el código',
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
