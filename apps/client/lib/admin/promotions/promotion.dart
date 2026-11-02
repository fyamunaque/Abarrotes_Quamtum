import '../../common/money.dart';

/// En qué está una promoción hoy. Lo calcula el servidor con las fechas y si
/// está encendida.
enum PromotionStatus {
  active('Activa', 'Activas'),
  scheduled('Programada', 'Programadas'),
  expired('Vencida', 'Vencidas'),
  disabled('Apagada', 'Apagadas');

  const PromotionStatus(this.label, this.pluralLabel);

  final String label;

  /// Para los filtros.
  final String pluralLabel;
}

/// A quién va dirigida una promoción, con los nombres del servidor.
enum PromotionAudience {
  everyone('Todos'),
  vip('Solo clientes VIP'),

  /// Solo los clientes VIP elegidos (`Promotion.recipients`).
  selected('Clientes elegidos');

  const PromotionAudience(this.label);

  final String label;
}

/// Qué da una promoción, con los nombres del servidor.
enum PromotionType {
  specialPrice('Precio especial'),
  percentOff('% de descuento'),
  buyXPayY('NxM'),
  extraUnit('Unidad extra'),
  gift('Regalo');

  const PromotionType(this.label);

  final String label;
}

/// Una promoción con la que se cruza otra al crearla o editarla (el
/// servidor las lista para que la persona decida).
typedef PromotionOverlapItem = ({
  String label,
  PromotionAudience audience,
  String startDate,
  String endDate,
});

/// La promoción se cruza con otras del producto: se acumulan. Para
/// guardarla igual, se manda con `confirmOverlap`.
class PromotionOverlap implements Exception {
  const PromotionOverlap(this.overlaps);

  final List<PromotionOverlapItem> overlaps;
}

/// Un cliente VIP elegido para una promoción: su id en `/vip-customers` y
/// su correo.
typedef PromotionRecipient = ({String id, String email});

/// Una promoción de un producto por unos días: un precio especial, un %,
/// un NxM, una unidad extra con descuento o un regalo ([type]), para
/// todos, para los clientes VIP o para algunos VIP elegidos.
class Promotion {
  const Promotion({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.priceCents,
    this.promoPriceCents,
    required this.startDate,
    required this.endDate,
    required this.active,
    required this.status,
    this.audience = PromotionAudience.everyone,
    this.title,
    this.recipients = const [],
    this.type = PromotionType.specialPrice,
    this.percent,
    this.buyQuantity,
    this.payQuantity,
    this.giftProductId,
    this.giftProductName,
    this.giftQuantity,
  });

  /// Como la manda `/promotions`. Sin `audience`, es para todos.
  factory Promotion.fromJson(Object? json) => switch (json) {
    {
          'id': final String id,
          'productId': final String productId,
          'product': {
            'name': final String productName,
            'sku': final String sku,
            'price': final String price,
          },
          'startDate': final String startDate,
          'endDate': final String endDate,
          'active': final bool active,
          'status': final String status,
        } &&
        final Map<Object?, Object?> map =>
      Promotion(
        id: id,
        productId: productId,
        productName: productName,
        sku: sku,
        priceCents: parseCents(price),
        promoPriceCents: switch (map['promoPrice']) {
          final String price => parseCents(price),
          _ => null,
        },
        // Sin type (un servidor anterior), precio especial.
        type: switch (map['type']) {
          null => PromotionType.specialPrice,
          final String name =>
            PromotionType.values.asNameMap()[name] ??
                (throw FormatException('Tipo desconocido', name)),
          final other => throw FormatException('Tipo inválido', other),
        },
        percent: map['percent'] as int?,
        buyQuantity: map['buyQuantity'] as int?,
        payQuantity: map['payQuantity'] as int?,
        giftProductId: switch (map['giftProduct']) {
          {'id': final String id} => id,
          _ => null,
        },
        giftProductName: switch (map['giftProduct']) {
          {'name': final String name} => name,
          _ => null,
        },
        giftQuantity: map['giftQuantity'] as int?,
        startDate: startDate,
        endDate: endDate,
        active: active,
        status:
            PromotionStatus.values.asNameMap()[status] ??
            (throw FormatException('Estado desconocido', status)),
        audience: switch (map['audience']) {
          null => PromotionAudience.everyone,
          final String name =>
            PromotionAudience.values.asNameMap()[name] ??
                (throw FormatException('Audiencia desconocida', name)),
          final other => throw FormatException('Audiencia inválida', other),
        },
        title: map['title'] as String?,
        recipients: switch (map['recipients']) {
          final List<Object?> list => [
            for (final item in list)
              switch (item) {
                {'id': final String id, 'email': final String email} => (
                  id: id,
                  email: email,
                ),
                _ => throw FormatException('No es un cliente elegido', item),
              },
          ],
          _ => const [],
        },
      ),
    _ => throw FormatException('No es una promoción', json),
  };

  final String id;
  final String productId;
  final String productName;
  final String sku;

  /// El precio normal del producto.
  final int priceCents;

  final PromotionType type;

  /// Solo en [PromotionType.specialPrice].
  final int? promoPriceCents;

  /// En [PromotionType.percentOff] y [PromotionType.extraUnit]: cuánto
  /// menos, en %.
  final int? percent;

  /// En un NxM, la N que se lleva; en la unidad extra, cada cuántas; en un
  /// regalo, cada cuántas unidades hay regalo.
  final int? buyQuantity;

  /// En un NxM, la M que se paga.
  final int? payQuantity;

  /// En un regalo: qué producto y cuántos.
  final String? giftProductId;
  final String? giftProductName;
  final int? giftQuantity;

  /// Días de la tienda (`AAAA-MM-DD`), ambos incluidos.
  final String startDate;
  final String endDate;

  /// El interruptor: apagada no rige aunque esté en fecha.
  final bool active;
  final PromotionStatus status;
  final PromotionAudience audience;

  /// El nombre de la oferta (p. ej. "Semana del arroz"), si tiene.
  final String? title;

  /// Con [PromotionAudience.selected]: los clientes VIP elegidos.
  final List<PromotionRecipient> recipients;

  /// Solo para clientes VIP: todos o los elegidos.
  bool get vipOnly => audience != PromotionAudience.everyone;

  /// El descuento sobre el precio normal, redondeado: el de un precio
  /// especial o un %; null en los demás tipos.
  int? get discountPercent => switch (type) {
    PromotionType.specialPrice when priceCents > 0 =>
      ((priceCents - promoPriceCents!) * 100 / priceCents).round(),
    PromotionType.percentOff => percent,
    _ => null,
  };

  /// Cómo se nombra, como en el servidor: "Precio especial S/ 19.90",
  /// "20 % menos", "2x1", "2.ª al 50 %" o "Regalo: Sal 1 kg".
  String get label => promotionLabel(
    type,
    promoPriceCents: promoPriceCents,
    percent: percent,
    buyQuantity: buyQuantity,
    payQuantity: payQuantity,
    giftProductName: giftProductName,
  );
}

/// [type] con sus datos, como lo nombra el servidor.
String promotionLabel(
  PromotionType type, {
  int? promoPriceCents,
  int? percent,
  int? buyQuantity,
  int? payQuantity,
  String? giftProductName,
}) => switch (type) {
  PromotionType.specialPrice =>
    'Precio especial ${formatSoles(promoPriceCents ?? 0)}',
  PromotionType.percentOff => '$percent % menos',
  PromotionType.buyXPayY => '${buyQuantity}x$payQuantity',
  PromotionType.extraUnit => '$buyQuantity.ª al $percent %',
  PromotionType.gift =>
    giftProductName == null ? 'Regalo' : 'Regalo: $giftProductName',
};

/// Lo que se manda al crear o editar una promoción. El producto y el tipo
/// solo se eligen al crear: al editar no se mandan.
class PromotionInput {
  const PromotionInput({
    this.type = PromotionType.specialPrice,
    this.promoPriceCents,
    this.percent,
    this.buyQuantity,
    this.payQuantity,
    this.giftProductId,
    this.giftQuantity,
    required this.startDate,
    required this.endDate,
    required this.active,
    this.audience = PromotionAudience.everyone,
    this.title,
    this.productId,
    this.recipients = const [],
  });

  final String? productId;
  final PromotionType type;
  final int? promoPriceCents;
  final int? percent;
  final int? buyQuantity;
  final int? payQuantity;
  final String? giftProductId;
  final int? giftQuantity;

  /// `AAAA-MM-DD`, ambos incluidos.
  final String startDate;
  final String endDate;
  final bool active;
  final PromotionAudience audience;

  /// Sin título se manda null, que al editar lo borra.
  final String? title;

  /// Con [PromotionAudience.selected]: los clientes VIP elegidos (al menos
  /// uno). Con otra audiencia no se mandan: el servidor los quita.
  final List<PromotionRecipient> recipients;

  Map<String, Object?> toJson() => {
    'productId': ?productId,
    if (productId != null) 'type': type.name,
    ...switch (type) {
      PromotionType.specialPrice => {'promoPrice': promoPriceCents! / 100},
      PromotionType.percentOff => {'percent': percent},
      PromotionType.buyXPayY => {
        'buyQuantity': buyQuantity,
        'payQuantity': payQuantity,
      },
      PromotionType.extraUnit => {
        'buyQuantity': buyQuantity,
        'percent': percent,
      },
      PromotionType.gift => {
        'buyQuantity': buyQuantity,
        'giftProductId': giftProductId,
        'giftQuantity': giftQuantity,
      },
    },
    'startDate': startDate,
    'endDate': endDate,
    'active': active,
    'audience': audience.name,
    'title': title,
    if (audience == PromotionAudience.selected)
      'recipientIds': [for (final recipient in recipients) recipient.id],
  };
}
