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

/// Una promoción: un precio especial de un producto por unos días.
class Promotion {
  const Promotion({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.priceCents,
    required this.promoPriceCents,
    required this.startDate,
    required this.endDate,
    required this.active,
    required this.status,
  });

  /// Como la manda `/promotions`.
  factory Promotion.fromJson(Object? json) => switch (json) {
    {
      'id': final String id,
      'productId': final String productId,
      'product': {
        'name': final String productName,
        'sku': final String sku,
        'price': final String price,
      },
      'promoPrice': final String promoPrice,
      'startDate': final String startDate,
      'endDate': final String endDate,
      'active': final bool active,
      'status': final String status,
    } =>
      Promotion(
        id: id,
        productId: productId,
        productName: productName,
        sku: sku,
        priceCents: parseCents(price),
        promoPriceCents: parseCents(promoPrice),
        startDate: startDate,
        endDate: endDate,
        active: active,
        status:
            PromotionStatus.values.asNameMap()[status] ??
            (throw FormatException('Estado desconocido', status)),
      ),
    _ => throw FormatException('No es una promoción', json),
  };

  final String id;
  final String productId;
  final String productName;
  final String sku;

  /// El precio normal del producto.
  final int priceCents;
  final int promoPriceCents;

  /// Días de la tienda (`AAAA-MM-DD`), ambos incluidos.
  final String startDate;
  final String endDate;

  /// El interruptor: apagada no rige aunque esté en fecha.
  final bool active;
  final PromotionStatus status;

  /// El descuento sobre el precio normal, redondeado.
  int get discountPercent => priceCents == 0
      ? 0
      : ((priceCents - promoPriceCents) * 100 / priceCents).round();
}

/// Lo que se manda al crear o editar una promoción. El producto solo se
/// elige al crear.
class PromotionInput {
  const PromotionInput({
    required this.promoPriceCents,
    required this.startDate,
    required this.endDate,
    required this.active,
    this.productId,
  });

  final String? productId;
  final int promoPriceCents;

  /// `AAAA-MM-DD`, ambos incluidos.
  final String startDate;
  final String endDate;
  final bool active;

  Map<String, Object?> toJson() => {
    'productId': ?productId,
    'promoPrice': promoPriceCents / 100,
    'startDate': startDate,
    'endDate': endDate,
    'active': active,
  };
}
