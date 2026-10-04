import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/orders/states/order_states.dart';
import 'package:test/test.dart';

void main() {
  const pending = OrderStatus.pendingConfirmation;
  const confirmed = OrderStatus.confirmed;
  const onTheWay = OrderStatus.outForDelivery;
  const delivered = OrderStatus.delivered;
  const cancelled = OrderStatus.cancelled;

  /// El flujo completo: a qué estados puede pasar cada uno.
  const allowed = {
    pending: {confirmed, cancelled},
    confirmed: {onTheWay, cancelled},
    onTheWay: {delivered, cancelled},
    delivered: <OrderStatus>{},
    cancelled: <OrderStatus>{},
  };

  test('cada estado tiene su handler', () {
    for (final status in OrderStatus.values) {
      expect(orderStateOf(status).status, status);
    }
  });

  for (final from in OrderStatus.values) {
    for (final to in OrderStatus.values) {
      final expected = allowed[from]!.contains(to);
      test('${from.name} → ${to.name}: ${expected ? 'permitido' : 'no'}', () {
        expect(orderStateOf(from).canTransitionTo(to), expected);
      });
    }
  }

  group('motivo del rechazo', () {
    test(
      'un estado final no puede cambiar (entregado no vuelve a confirmado)',
      () {
        expect(
          orderStateOf(delivered).rejectionReason(confirmed),
          'Un pedido entregado ya no puede cambiar de estado',
        );
      },
    );

    test('dice a qué estados sí puede pasar', () {
      expect(
        orderStateOf(confirmed).rejectionReason(delivered),
        'Un pedido confirmado no puede pasar a entregado: '
        'solo puede pasar a en camino o cancelado',
      );
    });

    test('al mismo estado', () {
      expect(
        orderStateOf(cancelled).rejectionReason(cancelled),
        'El pedido ya está cancelado',
      );
    });
  });
}
