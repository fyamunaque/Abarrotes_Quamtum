import 'package:flutter_test/flutter_test.dart';
import 'package:neils/orders/fulfillment.dart';
import 'package:neils/orders/order.dart';
import 'package:neils/orders/order_status.dart';

/// El pedido como lo manda el servidor (`orderJson` en apps/server).
void main() {
  const base = {
    'id': 'o-1',
    'status': 'pendingConfirmation',
    'total': '24.9',
    'deliveryAddress': 'Av. Arequipa 123',
    'createdAt': '2026-10-14T15:00:00.000Z',
    'items': [],
  };

  test('de un servidor anterior: a domicilio y sin estados siguientes', () {
    final order = Order.fromJson(base);

    expect(order.fulfillmentType, FulfillmentType.delivery);
    expect(order.deliveryAddress, 'Av. Arequipa 123');
    expect(order.pickupCode, isNull);
    expect(order.allowedNextStatuses, isEmpty);
  });

  test(
    'el número: "Pedido N.º 1024"; sin él (un servidor anterior), "Pedido"',
    () {
      final order = Order.fromJson({...base, 'number': 1024});
      expect(order.number, 1024);
      expect(order.title, 'Pedido N.º 1024');

      expect(Order.fromJson(base).number, isNull);
      expect(Order.fromJson(base).title, 'Pedido');
    },
  );

  test('de recojo: sin dirección, con su código y cuándo quedó listo', () {
    final order = Order.fromJson({
      ...base,
      'status': 'readyForPickup',
      'fulfillmentType': 'pickup',
      'deliveryAddress': null,
      'pickupCode': 'K7M2XQ',
      'readyForPickupAt': '2026-10-14T16:30:00.000Z',
      // Uno que esta versión de la app no conoce: no se ofrece.
      'allowedNextStatuses': ['delivered', 'teletransportado', 'cancelled'],
    });

    expect(order.status, OrderStatus.readyForPickup);
    expect(order.fulfillmentType, FulfillmentType.pickup);
    expect(order.deliveryAddress, isNull);
    expect(order.pickupCode, 'K7M2XQ');
    expect(order.readyForPickupAt, DateTime.utc(2026, 10, 14, 16, 30));
    expect(order.allowedNextStatuses, [
      OrderStatus.delivered,
      OrderStatus.cancelled,
    ]);
    expect(order.statusLabel, 'En espera de recojo');
  });

  test('lee el detalle del cobro', () {
    final order = Order.fromJson({
      ...base,
      'subtotal': '49.8',
      'discount': '24.9',
      'items': [
        {
          'productId': 'arroz',
          'quantity': 2,
          'listUnitPrice': '24.9',
          'unitPrice': '24.9',
          'lineTotal': '24.9',
          'isGift': false,
          'promotions': [
            {'label': '2x1', 'saved': '24.9'},
          ],
          'product': {'name': 'Arroz extra 5 kg'},
        },
        {
          'productId': 'sal',
          'quantity': 1,
          'listUnitPrice': '1.5',
          'unitPrice': '0',
          'lineTotal': '0',
          'isGift': true,
          'promotions': [
            {'label': 'Regalo: Sal 1 kg', 'saved': '1.5'},
          ],
          'product': {'name': 'Sal 1 kg'},
        },
      ],
    });

    expect(
      (order.subtotalCents, order.discountCents, order.totalCents),
      (4980, 2490, 2490),
    );
    final [arroz, sal] = order.lines;
    expect(
      (arroz.listUnitPriceCents, arroz.unitPriceCents, arroz.lineTotalCents),
      (2490, 2490, 2490),
    );
    expect(arroz.isGift, isFalse);
    expect(arroz.promotions, [(label: '2x1', savedCents: 2490)]);
    expect((sal.listUnitPriceCents, sal.lineTotalCents), (150, 0));
    expect(sal.isGift, isTrue);
  });

  test('de un servidor anterior: sin descuento', () {
    final order = Order.fromJson({
      ...base,
      'total': '49.8',
      'items': [
        {
          'productId': 'arroz',
          'quantity': 2,
          'unitPrice': '24.9',
          'product': {'name': 'Arroz extra 5 kg'},
        },
      ],
    });

    expect((order.subtotalCents, order.discountCents), (4980, 0));
    final line = order.lines.single;
    expect((line.listUnitPriceCents, line.lineTotalCents), (2490, 4980));
    expect(line.isGift, isFalse);
    expect(line.promotions, isEmpty);
  });

  test('a domicilio: el código de entrega, si lo tiene, y el motivo', () {
    // El dueño recibe el código.
    final mine = Order.fromJson({...base, 'deliveryCode': 'P4R9TW'});
    // El panel no, pero sabe que lo pide.
    final panel = Order.fromJson({
      ...base,
      'status': 'delivered',
      'deliveryCode': null,
      'hasDeliveryCode': true,
      'deliveredWithoutCodeReason': 'No tenía el celular',
    });

    expect((mine.deliveryCode, mine.hasDeliveryCode), ('P4R9TW', true));
    expect((panel.deliveryCode, panel.hasDeliveryCode), (null, true));
    expect(panel.deliveredWithoutCodeReason, 'No tenía el celular');
    // Uno de antes, o de un servidor anterior: sin código.
    expect(Order.fromJson(base).hasDeliveryCode, isFalse);
  });

  test('un estado o un tipo de entrega desconocidos no son un pedido', () {
    expect(
      () => Order.fromJson({...base, 'status': 'teletransportado'}),
      throwsFormatException,
    );
    expect(
      () => Order.fromJson({...base, 'fulfillmentType': 'dron'}),
      throwsFormatException,
    );
  });

  test('los pasos y los nombres de cada tipo de entrega', () {
    expect(FulfillmentType.delivery.steps, [
      OrderStatus.pendingConfirmation,
      OrderStatus.confirmed,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ]);
    expect(FulfillmentType.pickup.steps, [
      OrderStatus.pendingConfirmation,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.readyForPickup,
      OrderStatus.delivered,
    ]);
    // En recojo, entregado es "Recogido".
    expect(FulfillmentType.pickup.labelOf(OrderStatus.delivered), 'Recogido');
    expect(
      FulfillmentType.pickup.actionLabelOf(OrderStatus.delivered),
      'Marcar recogido',
    );
    expect(
      FulfillmentType.delivery.labelOf(OrderStatus.delivered),
      'Entregado',
    );
    expect(OrderStatus.preparing.label, 'Preparando');
    expect(OrderStatus.readyForPickup.label, 'En espera de recojo');
  });
}
