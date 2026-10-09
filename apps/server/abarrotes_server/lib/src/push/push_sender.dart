/// Un aviso push: lo que se ve (título y texto) y datos para la app.
class PushMessage {
  const PushMessage({
    required this.title,
    required this.body,
    this.data = const {},
  });

  final String title;
  final String body;

  /// Para la app al tocar el aviso (p. ej. qué producto abrir). FCM solo
  /// acepta textos.
  final Map<String, String> data;
}

/// Qué pasó con un envío.
enum PushResult {
  sent,

  /// El token ya no sirve (se desinstaló la app o se renovó el token): hay
  /// que borrarlo.
  invalidToken,

  /// No se pudo mandar ahora (sin red, cuota, un error de FCM).
  failed,
}

/// El resultado de un envío y, si no salió, por qué (para el log; nunca
/// incluye el token ni credenciales).
typedef PushOutcome = ({PushResult result, String? reason});

/// Manda avisos push a un dispositivo por vez, por su token de registro.
abstract interface class PushSender {
  /// Si está configurado. Sin credenciales no manda nada.
  bool get enabled;

  /// Manda [message] al dispositivo de [token]. Nunca lanza: el resultado
  /// dice qué pasó.
  Future<PushOutcome> send(String token, PushMessage message);
}

/// Sin credenciales de FCM: no manda nada (ver `server.dart`).
class DisabledPushSender implements PushSender {
  const DisabledPushSender();

  @override
  bool get enabled => false;

  @override
  Future<PushOutcome> send(String token, PushMessage message) async =>
      (result: PushResult.failed, reason: 'el envío push no está configurado');
}

/// Los últimos caracteres de [token], para identificarlo en el log sin
/// escribirlo entero.
String tokenHint(String token) =>
    token.length <= 6 ? '…' : '…${token.substring(token.length - 6)}';
