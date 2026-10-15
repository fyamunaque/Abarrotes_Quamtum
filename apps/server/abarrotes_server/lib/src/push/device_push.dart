import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'push_sender.dart';

/// Corre un trabajo con una sesión propia (`Serverpod.withSession`): sirve
/// para seguir después de responder la petición.
typedef SessionRunner = Future<void> Function(Future<void> Function(Session));

/// Cuántos avisos salieron, cuántos tokens inválidos se borraron y cuántos
/// envíos fallaron.
typedef PushSummary = ({int sent, int invalid, int failed});

/// Manda [message] a cada uno de [devices], uno por uno (nunca por topic: uno
/// lo podría suscribir cualquiera). Los tokens que FCM da por inválidos se
/// borran; si un envío falla, queda en el log y sigue con los demás.
Future<PushSummary> pushToDevices(
  Session session,
  PushSender sender,
  Iterable<DeviceToken> devices,
  PushMessage message,
) async {
  var sent = 0, invalid = 0, failed = 0;
  for (final device in devices) {
    final outcome = await sender.send(device.token, message);
    switch (outcome.result) {
      case PushResult.sent:
        sent++;
      case PushResult.invalidToken:
        invalid++;
        await DeviceToken.db.deleteRow(session, device);
      case PushResult.failed:
        failed++;
        session.log(
          'No salió el aviso a ${tokenHint(device.token)}: ${outcome.reason}',
          level: LogLevel.warning,
        );
    }
  }
  return (sent: sent, invalid: invalid, failed: failed);
}
