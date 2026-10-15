import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/orders/order_status_notifier.dart';
import 'package:abarrotes_server/src/promotions/promotion_announcer.dart';
import 'package:abarrotes_server/src/push/push_sender.dart';

/// Un [PushSender] en memoria: guarda lo que se mandó. Los tokens de
/// [invalid] responden como dados de baja y los de [failing], como un error
/// de FCM.
class FakePushSender implements PushSender {
  FakePushSender({this.enabled = true});

  @override
  final bool enabled;

  final invalid = <String>{};
  final failing = <String>{};

  /// Lo que se mandó, en orden (también los intentos que fallaron).
  final sent = <(String, PushMessage)>[];

  @override
  Future<PushOutcome> send(String token, PushMessage message) async {
    sent.add((token, message));
    if (invalid.contains(token)) {
      return (result: PushResult.invalidToken, reason: 'UNREGISTERED');
    }
    if (failing.contains(token)) {
      return (result: PushResult.failed, reason: 'FCM respondió 500');
    }
    return (result: PushResult.sent, reason: null);
  }
}

/// Guarda las promociones que se le pidió anunciar.
class RecordingAnnouncer implements PromotionAnnouncer {
  final announced = <Promotion>[];

  @override
  void announce(Promotion promotion) => announced.add(promotion);
}

/// Guarda los pedidos de los que se le pidió avisar.
class RecordingOrderNotifier implements OrderStatusNotifier {
  final changed = <Order>[];

  @override
  void statusChanged(Order order) => changed.add(order);
}

/// Siempre falla al avisar.
class ThrowingOrderNotifier implements OrderStatusNotifier {
  @override
  void statusChanged(Order order) => throw StateError('FCM caído');
}

/// Siempre falla al anunciar.
class ThrowingAnnouncer implements PromotionAnnouncer {
  @override
  void announce(Promotion promotion) => throw StateError('FCM caído');
}
