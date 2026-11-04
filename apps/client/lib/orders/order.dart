import '../common/money.dart';
import 'fulfillment.dart';
import 'order_status.dart';

/// Un pedido de la cuenta, como lo manda el servidor (`orderJson` en
/// apps/server). Montos en céntimos.
class Order {
  const Order({
    required this.id,
    required this.status,
    required this.totalCents,
    this._subtotalCents,
    this.discountCents = 0,
    required this.createdAt,
    required this.lines,
    this.number,
    this.fulfillmentType = FulfillmentType.delivery,
    this.deliveryAddress,
    this.pickupCode,
    this.deliveryCode,
    this.hasDeliveryCode = false,
    this.deliveredWithoutCodeReason,
    this.readyForPickupAt,
    this.allowedNextStatuses = const [],
    this.priceChanges = const [],
    this.notices = const [],
  });

  /// Lanza [FormatException] si [json] no tiene la forma de un pedido.
  factory Order.fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'status': final String status,
      'total': final String total,
      'createdAt': final String createdAt,
      'items': final List<Object?> items,
    }) {
      final statuses = OrderStatus.values.asNameMap();
      return Order(
        id: id,
        number: json['number'] as int?,
        status:
            statuses[status] ??
            (throw FormatException('Estado desconocido', status)),
        // Sin el campo (un servidor anterior), a domicilio.
        fulfillmentType: switch (json['fulfillmentType']) {
          final String type =>
            FulfillmentType.values.asNameMap()[type] ??
                (throw FormatException('Tipo de entrega desconocido', type)),
          _ => FulfillmentType.delivery,
        },
        totalCents: parseCents(total),
        // Sin los campos (un servidor anterior), sin descuentos.
        subtotalCents: switch (json['subtotal']) {
          final String subtotal => parseCents(subtotal),
          _ => null,
        },
        discountCents: switch (json['discount']) {
          final String discount => parseCents(discount),
          _ => 0,
        },
        deliveryAddress: json['deliveryAddress'] as String?,
        pickupCode: json['pickupCode'] as String?,
        deliveryCode: json['deliveryCode'] as String?,
        hasDeliveryCode:
            json['hasDeliveryCode'] == true || json['deliveryCode'] != null,
        deliveredWithoutCodeReason:
            json['deliveredWithoutCodeReason'] as String?,
        readyForPickupAt: switch (json['readyForPickupAt']) {
          final String at => DateTime.parse(at),
          _ => null,
        },
        createdAt: DateTime.parse(createdAt),
        lines: [for (final item in items) OrderLine.fromJson(item)],
        // Los que esta versión de la app no conoce, no se ofrecen.
        allowedNextStatuses: switch (json['allowedNextStatuses']) {
          final List<Object?> names => [
            for (final name in names) ?statuses[name],
          ],
          _ => const [],
        },
        // Solo al crearlo: lo que se cobró distinto de lo que mostraba el
        // carrito.
        priceChanges: switch (json['priceChanges']) {
          final List<Object?> changes => [
            for (final change in changes) PriceChange.fromJson(change),
          ],
          _ => const [],
        },
        // También solo al crearlo: p. ej. un regalo que se agotó al pedir.
        notices: switch (json['notices']) {
          final List<Object?> notices => [
            for (final notice in notices)
              if (notice is String) notice,
          ],
          _ => const [],
        },
      );
    }
    throw FormatException('No es un pedido', json);
  }

  final String id;

  /// El número que se le dice al cliente ("Pedido N.º 1024"), correlativo.
  /// Null solo con un servidor anterior.
  final int? number;

  /// "Pedido N.º 1024", o "Pedido" sin número.
  String get title => switch (number) {
    final number? => 'Pedido N.º $number',
    null => 'Pedido',
  };

  final OrderStatus status;
  final FulfillmentType fulfillmentType;

  /// Lo que se cobró: [subtotalCents] (los precios normales, sin los
  /// regalos) menos [discountCents] (lo que ahorraron las promociones).
  final int totalCents;
  final int? _subtotalCents;
  int get subtotalCents => _subtotalCents ?? totalCents;
  final int discountCents;

  /// Solo a domicilio.
  final String? deliveryAddress;

  /// Solo en recojo: el código que el cliente muestra en caja. Lo reciben el
  /// dueño del pedido y el personal que ve los pedidos.
  final String? pickupCode;

  /// Solo a domicilio: el código que el cliente le da al repartidor. Lo
  /// recibe solo el dueño del pedido; el panel nunca lo ve.
  final String? deliveryCode;

  /// Si entregarlo pide el código de entrega (los pedidos de antes no lo
  /// tienen). Lo sabe también el panel, para pedírselo al cliente.
  final bool hasDeliveryCode;

  /// Si se entregó sin el código de entrega: por qué.
  final String? deliveredWithoutCodeReason;

  /// Cuándo quedó listo para recoger.
  final DateTime? readyForPickupAt;

  final DateTime createdAt;
  final List<OrderLine> lines;

  /// A qué estados puede pasar, según el flujo de su tipo de entrega. Lo
  /// calcula el servidor: el panel arma sus botones con esto.
  final List<OrderStatus> allowedNextStatuses;

  /// El estado como lo lee la persona ("Recogido" en recojo).
  String get statusLabel => fulfillmentType.labelOf(status);

  /// Los productos que se cobraron a otro precio que el del carrito (p. ej.
  /// terminó una promoción). Solo viene al crear el pedido.
  final List<PriceChange> priceChanges;

  /// Los avisos del cobro (p. ej. "Solo quedaba 1 de Sal 1 kg para
  /// regalo"). Solo vienen al crear el pedido.
  final List<String> notices;
}

/// Un producto que se cobró distinto de lo que mostraba el carrito: el
/// total de la línea (si el carrito tenía la cotización) o el precio por
/// unidad.
class PriceChange {
  const PriceChange({
    required this.productId,
    required this.name,
    this.shownUnitPriceCents,
    this.unitPriceCents,
    this.shownLineTotalCents,
    this.lineTotalCents,
  });

  factory PriceChange.fromJson(Object? json) => switch (json) {
    {
      'productId': final String productId,
      'name': final String name,
      'shownLineTotal': final String shown,
      'lineTotal': final String lineTotal,
    } =>
      PriceChange(
        productId: productId,
        name: name,
        shownLineTotalCents: parseCents(shown),
        lineTotalCents: parseCents(lineTotal),
      ),
    {
      'productId': final String productId,
      'name': final String name,
      'shownUnitPrice': final String shown,
      'unitPrice': final String unitPrice,
    } =>
      PriceChange(
        productId: productId,
        name: name,
        shownUnitPriceCents: parseCents(shown),
        unitPriceCents: parseCents(unitPrice),
      ),
    _ => throw FormatException('No es un cambio de precio', json),
  };

  final String productId;
  final String name;
  final int? shownUnitPriceCents;
  final int? unitPriceCents;
  final int? shownLineTotalCents;
  final int? lineTotalCents;
}

/// Una promoción que se aplicó a una línea ("2x1") y cuánto ahorró.
typedef AppliedPromotion = ({String label, int savedCents});

/// Una línea del pedido, con lo que se cobró: el precio normal, el
/// unitario (con el precio especial y los %), el total de la línea (con
/// el NxM o la unidad extra) y las promociones que se le aplicaron. Un
/// regalo va en su propia línea, en 0.
class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPriceCents,
    this._listUnitPriceCents,
    this._lineTotalCents,
    this.isGift = false,
    this.promotions = const [],
  });

  factory OrderLine.fromJson(Object? json) => switch (json) {
    {
          'productId': final String productId,
          'quantity': final int quantity,
          'unitPrice': final String unitPrice,
          'product': {'name': final String name},
        } &&
        final Map<Object?, Object?> map =>
      OrderLine(
        productId: productId,
        name: name,
        quantity: quantity,
        unitPriceCents: parseCents(unitPrice),
        // Sin los campos (un servidor anterior), el unitario por la
        // cantidad.
        listUnitPriceCents: switch (map['listUnitPrice']) {
          final String price => parseCents(price),
          _ => null,
        },
        lineTotalCents: switch (map['lineTotal']) {
          final String total => parseCents(total),
          _ => null,
        },
        isGift: map['isGift'] == true,
        promotions: switch (map['promotions']) {
          final List<Object?> list => [
            for (final item in list)
              switch (item) {
                {'label': final String label, 'saved': final String saved} => (
                  label: label,
                  savedCents: parseCents(saved),
                ),
                _ => throw FormatException('No es una promoción', item),
              },
          ],
          _ => const [],
        },
      ),
    _ => throw FormatException('No es una línea de pedido', json),
  };

  final String productId;
  final String name;
  final int quantity;
  final int unitPriceCents;

  final int? _listUnitPriceCents;
  int get listUnitPriceCents => _listUnitPriceCents ?? unitPriceCents;

  final int? _lineTotalCents;
  int get lineTotalCents => _lineTotalCents ?? unitPriceCents * quantity;

  final bool isGift;
  final List<AppliedPromotion> promotions;
}
