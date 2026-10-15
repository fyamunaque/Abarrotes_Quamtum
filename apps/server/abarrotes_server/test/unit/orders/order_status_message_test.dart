import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/orders/push_order_status_notifier.dart';
import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:test/test.dart';

void main() {
  final id = UuidValue.fromString('0190a1b2-0000-7000-8000-000000000001');

  Order order(OrderStatus status, {bool pickup = false}) => Order(
    id: id,
    status: status,
    fulfillmentType: pickup ? FulfillmentType.pickup : FulfillmentType.delivery,
    pickupCode: pickup ? 'K7M2XQ' : null,
    deliveryAddress: pickup ? null : 'Av. Arequipa 123',
    totalCents: 450,
    customerId: id,
  );

  (String, String)? text(OrderStatus status, {bool pickup = false}) =>
      switch (orderStatusMessage(order(status, pickup: pickup))) {
        final message? => (message.title, message.body),
        null => null,
      };

  test('a domicilio, un aviso por paso', () {
    expect(text(OrderStatus.pendingConfirmation), isNull);
    expect(text(OrderStatus.confirmed), (
      'Confirmamos tu pedido',
      'Lo estamos alistando para enviártelo.',
    ));
    expect(text(OrderStatus.outForDelivery), (
      'Tu pedido está en camino',
      'Pronto llega a la dirección que nos diste.',
    ));
    expect(text(OrderStatus.delivered), (
      'Entregamos tu pedido',
      '¡Gracias por tu compra!',
    ));
    expect(text(OrderStatus.cancelled), (
      'Cancelamos tu pedido',
      'Si tienes dudas, escríbenos.',
    ));
  });

  test('con recojo: preparando, listo con el código y recogido', () {
    expect(text(OrderStatus.confirmed, pickup: true), (
      'Confirmamos tu pedido',
      'Te avisamos cuando empecemos a prepararlo.',
    ));
    expect(text(OrderStatus.preparing, pickup: true), (
      'Estamos preparando tu pedido',
      'Te avisamos cuando esté listo para recoger.',
    ));
    expect(text(OrderStatus.readyForPickup, pickup: true), (
      'Tu pedido está listo',
      'Tu pedido está listo para recoger en tienda, tu código es K7M2XQ.',
    ));
    expect(text(OrderStatus.delivered, pickup: true), (
      'Recogiste tu pedido',
      '¡Gracias por tu compra!',
    ));
  });

  test('la dirección no va en el aviso (se ve en la pantalla bloqueada)', () {
    for (final status in OrderStatus.values) {
      final message = orderStatusMessage(order(status));
      expect(message?.body ?? '', isNot(contains('Arequipa')));
    }
  });

  test('los datos dicen qué pedido abrir', () {
    expect(orderStatusMessage(order(OrderStatus.confirmed))!.data, {
      'type': 'order_status',
      'orderId': id.toString(),
      'status': 'confirmed',
    });
  });
}
