import 'package:serverpod/serverpod.dart';

import '../common/http_json.dart';
import '../common/money.dart';
import '../common/pagination.dart';
import '../common/shopper.dart';
import '../generated/protocol.dart';
import 'audience/promotion_audience_rule.dart';
import 'code_benefits.dart';
import 'promotion_announcer.dart';
import 'promotion_engine.dart';
import 'promotion_labels.dart';
import 'promotion_pricing.dart';
import 'promotion_rules.dart';

/// Datos de una promoción tal como llegan en el body (días de la tienda).
/// [type] decide qué campos lleva (ver [PromotionType]); los de otros
/// tipos van en null. [recipientIds], los clientes VIP elegidos: solo con
/// la audiencia `selected` (vacío en las demás). [promoCodeId], el código
/// que la da: solo con la audiencia `code`.
typedef PromotionInput = ({
  PromotionType type,
  int? promoPriceCents,
  int? percent,
  int? buyQuantity,
  int? payQuantity,
  UuidValue? giftProductId,
  int? giftQuantity,
  String startDate,
  String endDate,
  bool active,
  PromotionAudience audience,
  String? title,
  List<UuidValue> recipientIds,
  UuidValue? promoCodeId,
  // Crearla o guardarla aunque se cruce con otras (se acumulan).
  bool confirmOverlap,
});

/// Promociones: las del dashboard y, según las reglas de audiencia, las que
/// puede usar cada cliente ([PromotionPricing]).
class PromotionsService implements PromotionPricing {
  /// [audienceRules] decide quién usa cada audiencia: una audiencia sin regla
  /// no la usa nadie. [announcer] avisa de cada promoción que se crea y ya
  /// rige (p. ej. un push a los VIP). [codeBenefits] dice qué códigos
  /// activó cada cliente: las promociones de audiencia `code` solo valen en
  /// el cobro, para ellos.
  PromotionsService({
    required List<PromotionAudienceRule> audienceRules,
    this._announcer = const NoPromotionAnnouncer(),
    this._codeBenefits = const NoCodeBenefits(),
    DateTime Function()? now,
  }) : _audienceRules = List.unmodifiable(audienceRules),
       _now = now ?? DateTime.now;

  final List<PromotionAudienceRule> _audienceRules;
  final PromotionAnnouncer _announcer;
  final CodeBenefits _codeBenefits;
  final DateTime Function() _now;

  DateTime now() => _now().toUtc();

  /// Las audiencias cuyas promociones puede usar [shopper].
  Set<PromotionAudience> audiencesFor(Shopper shopper) => {
    for (final rule in _audienceRules)
      if (rule.isEligible(shopper)) rule.audience,
  };

  /// Las vigentes de las audiencias que [shopper] puede usar; de una regla
  /// que además elige entre sus promociones (clientes elegidos), solo las
  /// suyas.
  @override
  Expression eligibleWhere(
    PromotionTable promotion,
    DateTime now,
    Shopper shopper,
  ) {
    Expression audiences = Constant.bool(false);
    for (final rule in _audienceRules) {
      if (!rule.isEligible(shopper)) continue;
      audiences |= switch (rule) {
        final PromotionRecipientsRule rule =>
          promotion.audience.equals(rule.audience) &
              rule.recipientsWhere(promotion, shopper),
        _ => promotion.audience.equals(rule.audience),
      };
    }
    return activePromotionWhere(promotion, now) & audiences;
  }

  @override
  PromotionIncludeList eligibleFor(DateTime now, Shopper shopper) =>
      Promotion.includeList(
        where: (promotion) => eligibleWhere(promotion, now, shopper),
        orderByList: (promotion) => [promotion.id.asc()],
        include: Promotion.include(giftProduct: Product.include()),
      );

  @override
  Future<Set<UuidValue>> giftProductIds(
    Session session,
    Set<UuidValue> productIds,
    Shopper shopper, {
    Transaction? transaction,
    UuidValue? customerId,
  }) async {
    final now = this.now();
    final gifts = await Promotion.db.find(
      session,
      where: (promotion) =>
          eligibleWhere(promotion, now, shopper) &
          promotion.productId.inSet(productIds) &
          promotion.type.equals(PromotionType.gift),
      transaction: transaction,
    );
    final benefits = customerId == null
        ? const <CodeBenefit>[]
        : await _codeBenefits.activeFor(
            session,
            customerId,
            transaction: transaction,
          );
    final codeGifts = await _codePromotions(
      session,
      benefits,
      productIds,
      now,
      transaction,
    );
    return {
      for (final gift in [...gifts, ...codeGifts])
        if (gift.type == PromotionType.gift) gift.giftProductId!,
    };
  }

  /// Las promociones vigentes de los códigos de [benefits] para
  /// [productIds].
  Future<List<Promotion>> _codePromotions(
    Session session,
    List<CodeBenefit> benefits,
    Set<UuidValue> productIds,
    DateTime now,
    Transaction? transaction,
  ) async {
    if (benefits.isEmpty || productIds.isEmpty) return const [];
    return Promotion.db.find(
      session,
      where: (promotion) =>
          activePromotionWhere(promotion, now) &
          promotion.audience.equals(PromotionAudience.code) &
          promotion.promoCodeId.inSet(<UuidValue>{
            for (final benefit in benefits) benefit.promoCodeId,
          }) &
          promotion.productId.inSet(productIds),
      orderBy: (promotion) => promotion.id,
      include: Promotion.include(giftProduct: Product.include()),
      transaction: transaction,
    );
  }

  @override
  Future<PricedCart> price(
    Session session,
    List<PricingLine> lines,
    Shopper shopper, {
    Transaction? transaction,
    UuidValue? customerId,
    bool lockCodes = false,
  }) async {
    final now = this.now();
    final productIds = {for (final line in lines) line.productId};
    final promotions = productIds.isEmpty
        ? const <Promotion>[]
        : await Promotion.db.find(
            session,
            where: (promotion) =>
                eligibleWhere(promotion, now, shopper) &
                promotion.productId.inSet(productIds),
            orderBy: (promotion) => promotion.id,
            include: Promotion.include(giftProduct: Product.include()),
            transaction: transaction,
          );
    final benefits = customerId == null || productIds.isEmpty
        ? const <CodeBenefit>[]
        : await _codeBenefits.activeFor(
            session,
            customerId,
            transaction: transaction,
            lock: lockCodes,
          );
    final codePromotions = await _codePromotions(
      session,
      benefits,
      productIds,
      now,
      transaction,
    );
    final giftIds = <UuidValue>{
      for (final p in [...promotions, ...codePromotions]) ?p.giftProductId,
    };
    final gifts = giftIds.isEmpty
        ? const <Product>[]
        : await Product.db.find(
            session,
            where: (product) => product.id.inSet(giftIds),
            transaction: transaction,
          );
    return priceCartWithCodes(
      lines,
      {
        for (final id in productIds)
          id: [
            for (final p in promotions)
              if (p.productId == id) p,
          ],
      },
      {
        for (final gift in gifts)
          gift.id!: (
            id: gift.id!,
            name: gift.name,
            priceCents: gift.priceCents,
            active: gift.active,
            stock: gift.currentStock,
          ),
      },
      [
        for (final benefit in benefits)
          (
            redemptionId: benefit.redemptionId,
            code: benefit.code,
            minPurchaseCents: benefit.minPurchaseCents,
            promotions: [
              for (final p in codePromotions)
                if (p.promoCodeId == benefit.promoCodeId) p,
            ],
          ),
      ],
    );
  }

  /// Las vigentes que [shopper] puede usar, de productos activos: por nombre
  /// del producto y, en el mismo producto, la más barata primero. Con
  /// [specialPriceOnly], solo los precios especiales.
  Future<(List<Promotion>, int)> activeFor(
    Session session,
    Shopper shopper,
    PageQuery page, {
    bool specialPriceOnly = false,
  }) async {
    final now = this.now();
    Expression where(PromotionTable promotion) {
      final active =
          eligibleWhere(promotion, now, shopper) &
          promotion.product.active.equals(true);
      return specialPriceOnly
          ? active & promotion.type.equals(PromotionType.specialPrice)
          : active;
    }

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
    final created = await session.db.transaction((transaction) async {
      final created = await Promotion.db.insertRow(
        session,
        Promotion(
          productId: productId,
          type: input.type,
          promoPriceCents: input.promoPriceCents,
          percent: input.percent,
          buyQuantity: input.buyQuantity,
          payQuantity: input.payQuantity,
          giftProductId: input.giftProductId,
          giftQuantity: input.giftQuantity,
          startDate: period.startDate,
          endDate: period.endDate,
          active: input.active,
          audience: input.audience,
          promoCodeId: input.promoCodeId,
          title: input.title,
        ),
        transaction: transaction,
      );
      await _saveRecipients(session, created.id!, input, transaction);
      return created;
    });
    final promotion = await get(session, created.id!);
    if (promotionStatus(promotion, now()) == PromotionStatus.active) {
      _announce(session, promotion);
    }
    return promotion;
  }

  /// El aviso nunca corta la creación: si falla, queda en el log.
  void _announce(Session session, Promotion promotion) {
    try {
      _announcer.announce(promotion);
    } on Object catch (error, stackTrace) {
      session.log(
        'No se pudo avisar de la promoción ${promotion.id}',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
    }
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
      type: current.type,
      promoPriceCents: current.promoPriceCents,
      percent: current.percent,
      buyQuantity: current.buyQuantity,
      payQuantity: current.payQuantity,
      giftProductId: current.giftProductId,
      giftQuantity: current.giftQuantity,
      startDate: days.startDate,
      endDate: days.endDate,
      active: current.active,
      audience: current.audience,
      title: current.title,
      recipientIds: _recipientIdsOf(current),
      promoCodeId: current.promoCodeId,
      confirmOverlap: false,
    ));
    await _validate(
      session,
      current.product!,
      input,
      exceptId: id,
      currentRecipients: _recipientIdsOf(current).toSet(),
      currentGiftId: current.giftProductId,
    );

    final period = toStoredPeriod(input.startDate, input.endDate);
    await session.db.transaction((transaction) async {
      await Promotion.db.updateRow(
        session,
        current.copyWith(
          promoPriceCents: input.promoPriceCents,
          percent: input.percent,
          buyQuantity: input.buyQuantity,
          payQuantity: input.payQuantity,
          giftProductId: input.giftProductId,
          giftQuantity: input.giftQuantity,
          startDate: period.startDate,
          endDate: period.endDate,
          active: input.active,
          audience: input.audience,
          promoCodeId: input.promoCodeId,
          title: input.title,
        ),
        transaction: transaction,
      );
      await PromotionRecipient.db.deleteWhere(
        session,
        where: (recipient) => recipient.promotionId.equals(id),
        transaction: transaction,
      );
      await _saveRecipients(session, id, input, transaction);
    });
    return get(session, id);
  }

  static List<UuidValue> _recipientIdsOf(Promotion promotion) => [
    for (final recipient
        in promotion.recipients ?? const <PromotionRecipient>[])
      recipient.vipCustomerId,
  ];

  /// Los clientes elegidos de [input] (ninguno si no es de clientes
  /// elegidos), en la transacción que guarda la promoción.
  Future<void> _saveRecipients(
    Session session,
    UuidValue promotionId,
    PromotionInput input,
    Transaction transaction,
  ) async {
    if (input.recipientIds.isEmpty) return;
    await PromotionRecipient.db.insert(session, [
      for (final vipId in input.recipientIds.toSet())
        PromotionRecipient(promotionId: promotionId, vipCustomerId: vipId),
    ], transaction: transaction);
  }

  /// Borra la promoción. Los pedidos guardan su precio, así que no se ven
  /// afectados.
  Future<void> delete(Session session, UuidValue id) async {
    await Promotion.db.deleteRow(session, await get(session, id));
  }

  /// Reglas de negocio:
  /// - El último día no puede ser anterior al primero.
  /// - Cada tipo lleva sus campos y solo esos (ver [_typeProblems]); el
  ///   regalo es otro producto, que existe y está activo (al elegirlo).
  /// - El precio promocional tiene que ser menor al precio normal.
  /// - Una de clientes elegidos lleva al menos uno, y cada uno nuevo tiene
  ///   que ser un VIP activo (los que ya estaban se quedan aunque los den de
  ///   baja: dejan de usarla solos). Las demás no llevan elegidos.
  /// - Una de código lleva el código que la da, que existe; las demás, no.
  /// - Si se cruza con otras encendidas del mismo producto (fechas que se
  ///   pisan, de cualquier audiencia y tipo), 409 con la lista en
  ///   `overlaps`, salvo [PromotionInput.confirmOverlap]: se acumulan y el
  ///   administrador decide.
  Future<void> _validate(
    Session session,
    Product product,
    PromotionInput input, {
    UuidValue? exceptId,
    Set<UuidValue> currentRecipients = const {},
    UuidValue? currentGiftId,
  }) async {
    if (input.endDate.compareTo(input.startDate) < 0) {
      throw const ApiException.badRequest(
        'endDate no puede ser anterior a startDate',
      );
    }
    final problems = _typeProblems(input, product.id!);
    if (problems.isNotEmpty) throw ApiException.badRequest(problems);
    // Solo uno nuevo: si el de antes se dio de baja, igual se puede apagar o
    // cambiar la promoción.
    if (input.giftProductId case final giftId? when giftId != currentGiftId) {
      final gift = await Product.db.findById(session, giftId);
      if (gift == null || !gift.active) {
        throw const ApiException.badRequest(
          'El producto de regalo no existe o está dado de baja',
        );
      }
    }
    if (input.promoPriceCents case final promoPrice?
        when promoPrice >= product.priceCents) {
      throw ApiException.badRequest(
        'El precio promocional debe ser menor al precio normal '
        '(${formatMoney(product.priceCents)})',
      );
    }
    if (input.audience == PromotionAudience.selected) {
      if (input.recipientIds.isEmpty) {
        throw const ApiException.badRequest('Elige al menos un cliente VIP');
      }
      final added = input.recipientIds.toSet().difference(currentRecipients);
      final vips = added.isEmpty
          ? 0
          : await VipCustomer.db.count(
              session,
              where: (vip) => vip.id.inSet(added) & vip.active.equals(true),
            );
      if (vips != added.length) {
        throw const ApiException.badRequest(
          'Algún cliente elegido no es un cliente VIP activo',
        );
      }
    } else if (input.recipientIds.isNotEmpty) {
      throw const ApiException.badRequest(
        'recipientIds solo va en una promoción para clientes elegidos',
      );
    }
    if (input.audience == PromotionAudience.code) {
      final codeId = input.promoCodeId;
      if (codeId == null) {
        throw const ApiException.badRequest(
          'promoCodeId es obligatorio en una promoción de código',
        );
      }
      if (await PromoCode.db.findById(session, codeId) == null) {
        throw const ApiException.badRequest('El código indicado no existe');
      }
    } else if (input.promoCodeId != null) {
      throw const ApiException.badRequest(
        'promoCodeId solo va en una promoción de código',
      );
    }
    if (!input.active || input.confirmOverlap) return;

    final period = toStoredPeriod(input.startDate, input.endDate);
    final overlapping = await Promotion.db.find(
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
      orderBy: (promotion) => promotion.startDate,
      include: Promotion.include(giftProduct: Product.include()),
    );
    if (overlapping.isNotEmpty) {
      throw ApiException.conflict(
        'Se acumula con otras promociones del producto',
        details: {
          'overlaps': [
            for (final other in overlapping)
              {
                'id': other.id.toString(),
                'type': other.type.name,
                'audience': other.audience.name,
                'label': promotionLabel(other),
                'startDate': toDayPeriod(
                  other.startDate,
                  other.endDate,
                ).startDate,
                'endDate': toDayPeriod(other.startDate, other.endDate).endDate,
              },
          ],
        },
      );
    }
  }

  /// Los campos de [PromotionInput.type]: los que le faltan, los que no
  /// van y los que se salen de rango, con el mensaje para cada uno.
  static List<String> _typeProblems(
    PromotionInput input,
    UuidValue productId,
  ) {
    final type = input.type;
    final fields = <String, Object?>{
      'promoPrice': input.promoPriceCents,
      'percent': input.percent,
      'buyQuantity': input.buyQuantity,
      'payQuantity': input.payQuantity,
      'giftProductId': input.giftProductId,
      'giftQuantity': input.giftQuantity,
    };
    final own = _fieldsOf[type]!;
    final problems = [
      for (final MapEntry(:key, :value) in fields.entries)
        if (value != null && !own.contains(key))
          '$key no va en una promoción ${type.name}'
        else if (value == null && own.contains(key))
          type == PromotionType.specialPrice
              ? '$key es obligatorio en un precio especial'
              : '$key es obligatorio en una promoción ${type.name}',
    ];
    if (problems.isNotEmpty) return problems;

    void range(String field, int value, int min, int max) {
      if (value < min || value > max) {
        problems.add('$field debe estar entre $min y $max');
      }
    }

    switch (type) {
      case PromotionType.specialPrice:
        break;
      case PromotionType.percentOff:
        range('percent', input.percent!, 1, 90);
      case PromotionType.buyXPayY:
        range('buyQuantity', input.buyQuantity!, 2, 10);
        if (input.payQuantity! < 1) {
          problems.add('payQuantity debe ser mayor o igual a 1');
        } else if (input.payQuantity! >= input.buyQuantity!) {
          problems.add('payQuantity debe ser menor que buyQuantity');
        }
      case PromotionType.extraUnit:
        range('buyQuantity', input.buyQuantity!, 2, 10);
        range('percent', input.percent!, 1, 100);
      case PromotionType.gift:
        range('buyQuantity', input.buyQuantity!, 1, 10);
        range('giftQuantity', input.giftQuantity!, 1, 10);
        if (input.giftProductId == productId) {
          problems.add('El regalo tiene que ser otro producto');
        }
    }
    return problems;
  }

  static const _fieldsOf = {
    PromotionType.specialPrice: {'promoPrice'},
    PromotionType.percentOff: {'percent'},
    PromotionType.buyXPayY: {'buyQuantity', 'payQuantity'},
    PromotionType.extraUnit: {'buyQuantity', 'percent'},
    PromotionType.gift: {'buyQuantity', 'giftProductId', 'giftQuantity'},
  };

  static final _include = Promotion.include(
    product: Product.include(),
    giftProduct: Product.include(),
    promoCode: PromoCode.include(),
    recipients: PromotionRecipient.includeList(
      include: PromotionRecipient.include(vipCustomer: VipCustomer.include()),
    ),
  );
}
