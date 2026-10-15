// El modelo Order choca con la clase Order (orderBy) de Serverpod.
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/orders/push_order_status_notifier.dart';
import 'package:serverpod/serverpod.dart' hide Order;
import 'package:test/test.dart';

import '../support/fake_push.dart';
import '../support/http_harness.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Aviso push del cambio de estado', (sessionBuilder, _) {
    late Session session;
    late FakePushSender push;
    late User customer;
    late Order order;
    var runs = 0;
    final running = <Future<void>>[];

    PushOrderStatusNotifier notifier({FakePushSender? sender}) =>
        PushOrderStatusNotifier(
          sender: sender ?? push,
          run: (work) {
            runs++;
            final job = work(session);
            running.add(job);
            return job;
          },
        );

    Future<void> device(User user, String token) => DeviceToken.db
        .insertRow(session, DeviceToken(token: token, userId: user.id!))
        .then((_) {});

    setUp(() async {
      session = sessionBuilder.build();
      push = FakePushSender();
      runs = 0;
      customer = await insertUser(session, 'uid-cliente');
      final other = await insertUser(session, 'uid-otro');
      await device(customer, 'token-telefono');
      await device(customer, 'token-web');
      await device(other, 'token-otro');
      order = await Order.db.insertRow(
        session,
        Order(
          status: OrderStatus.readyForPickup,
          fulfillmentType: FulfillmentType.pickup,
          pickupCode: 'K7M2XQ',
          totalCents: 450,
          customerId: customer.id!,
        ),
      );
    });

    test('a cada dispositivo del dueño del pedido, con el código', () async {
      final summary = await notifier().notifyNow(session, order);

      expect(summary, (sent: 2, invalid: 0, failed: 0));
      expect(
        [for (final (token, _) in push.sent) token],
        unorderedEquals(['token-telefono', 'token-web']),
      );
      expect(
        push.sent.first.$2.body,
        'Tu pedido está listo para recoger en tienda, tu código es K7M2XQ.',
      );
    });

    test('borra el token inválido y sigue si un envío falla', () async {
      push
        ..invalid.add('token-telefono')
        ..failing.add('token-web');

      final summary = await notifier().notifyNow(session, order);

      expect(summary, (sent: 0, invalid: 1, failed: 1));
      expect(
        [for (final d in await DeviceToken.db.find(session)) d.token],
        unorderedEquals(['token-web', 'token-otro']),
      );
    });

    test('sin FCM configurado no manda nada', () async {
      final disabled = FakePushSender(enabled: false);

      final summary = await notifier(sender: disabled).notifyNow(
        session,
        order,
      );

      expect(summary, (sent: 0, invalid: 0, failed: 0));
      expect(disabled.sent, isEmpty);
    });

    test('corre aparte, y no para un estado que no avisa', () async {
      final notify = notifier();

      notify.statusChanged(
        order.copyWith(status: OrderStatus.pendingConfirmation),
      );
      expect(runs, 0);

      notify.statusChanged(order);
      expect(runs, 1);
      await Future.wait(running);
      expect(push.sent, hasLength(2));
    });
  });
}
