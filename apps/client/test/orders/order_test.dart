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
