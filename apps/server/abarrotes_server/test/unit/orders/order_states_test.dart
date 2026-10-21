import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/orders/states/order_states.dart';
import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:test/test.dart';

void main() {
  const pending = OrderStatus.pendingConfirmation;
  const confirmed = OrderStatus.confirmed;
  const onTheWay = OrderStatus.outForDelivery;
  const preparing = OrderStatus.preparing;
  const ready = OrderStatus.readyForPickup;
  const delivered = OrderStatus.delivered;
  const cancelled = OrderStatus.cancelled;

  final delivery = fulfillmentFlowOf(FulfillmentType.delivery);
  final pickup = fulfillmentFlowOf(FulfillmentType.pickup);

  /// A qué estados puede pasar cada uno, en cada flujo. Cancelar se puede
  /// hasta antes de entregar.
  final allowed = {
    delivery: {
      pending: {confirmed, cancelled},
      confirmed: {onTheWay, cancelled},
      onTheWay: {delivered, cancelled},
    },
    pickup: {
      pending: {confirmed, cancelled},
      confirmed: {preparing, cancelled},
      preparing: {ready, cancelled},
      ready: {delivered, cancelled},
    },
  };

  test('cada tipo de entrega tiene su flujo', () {
    expect(delivery.type, FulfillmentType.delivery);
    expect(pickup.type, FulfillmentType.pickup);
    expect(delivery.steps, [pending, confirmed, onTheWay, delivered]);
    expect(pickup.steps, [pending, confirmed, preparing, ready, delivered]);
  });

  for (final flow in [delivery, pickup]) {
    group('${flow.type.name}:', () {
      test('cada estado tiene su handler, con el flujo', () {
        for (final status in OrderStatus.values) {
          final state = orderStateOf(status, flow);
          expect(state.status, status);
          expect(state.flow, same(flow));
        }
      });

      for (final from in OrderStatus.values) {
        for (final to in OrderStatus.values) {
          final expected = allowed[flow]![from]?.contains(to) ?? false;
          test(
            '${from.name} → ${to.name}: ${expected ? 'permitido' : 'no'}',
            () =>
                expect(orderStateOf(from, flow).canTransitionTo(to), expected),
          );
        }
      }
    });
  }

  test('el handler de un pedido usa el flujo de su tipo de entrega', () {
    final order = Order(
      status: confirmed,
      fulfillmentType: FulfillmentType.pickup,
      totalCents: 450,
      customerId: UuidValue.fromString('0190a1b2-0000-7000-8000-000000000001'),
    );

    expect(orderStateOfOrder(order).nextStatuses, [preparing, cancelled]);
  });

  group('motivo del rechazo', () {
    test(
      'un estado final no puede cambiar (entregado no vuelve a confirmado)',
      () {
        expect(
          orderStateOf(delivered, delivery).rejectionReason(confirmed),
          'Un pedido entregado ya no puede cambiar de estado',
        );
        // En recojo, entregado se dice "recogido".
        expect(
          orderStateOf(delivered, pickup).rejectionReason(confirmed),
          'Un pedido recogido ya no puede cambiar de estado',
        );
      },
    );

    test('dice a qué estados sí puede pasar', () {
      expect(
        orderStateOf(confirmed, delivery).rejectionReason(delivered),
        'Un pedido confirmado no puede pasar a entregado: '
        'solo puede pasar a en camino o cancelado',
      );
      expect(
        orderStateOf(confirmed, pickup).rejectionReason(delivered),
        'Un pedido confirmado no puede pasar a recogido: '
        'solo puede pasar a preparando o cancelado',
      );
    });

    test('un estado de otro tipo de entrega', () {
      expect(
        orderStateOf(confirmed, pickup).rejectionReason(onTheWay),
        'Un pedido de recojo en tienda no puede pasar a en camino: '
        'no sale a reparto',
      );
      expect(
        orderStateOf(confirmed, delivery).rejectionReason(preparing),
        'Un pedido a domicilio no puede pasar a preparando: '
        'eso es solo para recojo en tienda',
      );
      expect(
        orderStateOf(pending, delivery).rejectionReason(ready),
        'Un pedido a domicilio no puede pasar a en espera de recojo: '
        'eso es solo para recojo en tienda',
      );
    });

    test('al mismo estado', () {
      expect(
        orderStateOf(cancelled, delivery).rejectionReason(cancelled),
        'El pedido ya está cancelado',
      );
    });
  });

  group('recoger en caja', () {
    final order = Order(
      status: ready,
      fulfillmentType: FulfillmentType.pickup,
      pickupCode: 'K7M2XQ',
      totalCents: 450,
      customerId: UuidValue.fromString('0190a1b2-0000-7000-8000-000000000001'),
    );
    final state = orderStateOf(ready, pickup);

    test('entregarlo pide el código del cliente', () {
      expect(
        state.exitProblem(order, delivered),
        'Falta el código de recojo: pídeselo al cliente',
      );
      expect(
        state.exitProblem(order, delivered, pickupCode: '  '),
        'Falta el código de recojo: pídeselo al cliente',
      );
      expect(
        state.exitProblem(order, delivered, pickupCode: 'K7M2XA'),
        'El código de recojo no coincide',
      );
      // Como lo escriba quien atiende: minúsculas y espacios valen.
      expect(
        state.exitProblem(order, delivered, pickupCode: ' k7m 2xq '),
        isNull,
      );
    });

    test('cancelarlo no pide el código', () {
      expect(state.exitProblem(order, cancelled), isNull);
    });

    test('los demás estados no piden nada al salir', () {
      for (final status in OrderStatus.values.where((s) => s != ready)) {
        expect(
          orderStateOf(status, pickup).exitProblem(order, cancelled),
          isNull,
        );
      }
    });

    test('al quedar listo guarda cuándo; los demás no tocan nada', () {
      final now = DateTime.utc(2026, 10, 14, 15);
      final waiting = order.copyWith(status: preparing);

      expect(state.onEnter(waiting, now).readyForPickupAt, now);
      for (final status in OrderStatus.values.where((s) => s != ready)) {
        expect(
          orderStateOf(status, pickup).onEnter(waiting, now).readyForPickupAt,
          isNull,
        );
      }
    });
  });
}
