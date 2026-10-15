import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../common/store_time.dart';
import '../generated/protocol.dart';
import '../promotions/promotion_announcer.dart';
import '../push/device_push.dart';
import '../push/push_sender.dart';
import 'vip_service.dart';

/// Avisa por push de una promoción VIP que empieza a regir, a cada
/// dispositivo de los clientes VIP activos con el correo verificado. Uno por
/// uno (nunca por topic: uno lo podría suscribir cualquiera). Las demás
/// promociones no las anuncia.
class VipPromotionAnnouncer implements PromotionAnnouncer {
  VipPromotionAnnouncer({
    required this._sender,
    required this._run,
    this._vips = const VipService(),
  });

  final PushSender _sender;
  final SessionRunner _run;
  final VipService _vips;

  /// En segundo plano, con su propia sesión: la promoción ya se creó y la
  /// respuesta no espera. Si algo falla, queda en el log de esa sesión.
  @override
  void announce(Promotion promotion) {
    if (promotion.audience != PromotionAudience.vip) return;
    unawaited(
      _run(
        (session) => announceNow(session, promotion),
      ).catchError((Object _) {
        // withSession ya lo dejó en el log.
      }),
    );
  }

  /// Manda el aviso de [promotion] y deja el resumen en el log. Los tokens
  /// que FCM da por inválidos se borran; si un envío falla, sigue con los
  /// demás.
  Future<PushSummary> announceNow(
    Session session,
    Promotion promotion,
  ) async {
    if (!_sender.enabled) {
      session.log(
        'Aviso push de la promoción ${promotion.id}: el envío push no está '
        'configurado (fcmServiceAccountFile)',
      );
      return (sent: 0, invalid: 0, failed: 0);
    }
    final emails = await _vips.activeEmails(session);
    final devices = emails.isEmpty
        ? const <DeviceToken>[]
        : await DeviceToken.db.find(
            session,
            where: (device) =>
                device.user.emailVerified.equals(true) &
                device.user.email.inSet(emails),
          );

    final (:sent, :invalid, :failed) = await pushToDevices(
      session,
      _sender,
      devices,
      vipPromotionMessage(promotion),
    );
    session.log(
      'Aviso push de la promoción VIP ${promotion.id}: $sent enviados, '
      '$invalid tokens inválidos borrados, $failed fallidos',
      level: failed > 0 ? LogLevel.warning : LogLevel.info,
    );
    return (sent: sent, invalid: invalid, failed: failed);
  }
}

/// El aviso de una promoción VIP (con su producto): "Nueva oferta
/// exclusiva" y, p. ej., "Semana VIP: Arroz extra 5 kg a S/ 17.90 (antes
/// S/ 24.90), hasta el 15 oct." Los datos dicen a la app qué abrir.
PushMessage vipPromotionMessage(Promotion promotion) {
  final product = promotion.product!;
  // endDate es el límite exclusivo: el último día es el anterior.
  final lastDay = addDays(storeDay(promotion.endDate), -1);
  final title = promotion.title;
  return PushMessage(
    title: 'Nueva oferta exclusiva',
    body:
        '${title == null ? '' : '$title: '}${product.name} a '
        '${_soles(promotion.promoPriceCents)} '
        '(antes ${_soles(product.priceCents)}), hasta el ${_day(lastDay)}.',
    data: {
      'type': 'vip_promotion',
      'promotionId': promotion.id.toString(),
      'productId': promotion.productId.toString(),
    },
  );
}

/// "S/ 17.90".
String _soles(int cents) =>
    'S/ ${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sept',
  'oct',
  'nov',
  'dic',
];

/// "2026-10-15" → "15 oct".
String _day(String day) {
  final [_, month, date] = day.split('-').map(int.parse).toList();
  return '$date ${_months[month - 1]}';
}
