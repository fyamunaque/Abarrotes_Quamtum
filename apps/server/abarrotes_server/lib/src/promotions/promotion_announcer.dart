import '../generated/protocol.dart';

/// Avisa de una promoción que empieza a regir (p. ej. un push a su
/// audiencia). promotions solo dice cuándo; a quién y cómo lo decide la
/// implementación, que se arma en `server.dart`.
abstract interface class PromotionAnnouncer {
  /// [promotion] (con su producto) se acaba de crear y ya rige. No espera ni
  /// lanza: lo que haga corre aparte y sus errores van al log.
  void announce(Promotion promotion);
}

/// No avisa a nadie.
class NoPromotionAnnouncer implements PromotionAnnouncer {
  const NoPromotionAnnouncer();

  @override
  void announce(Promotion promotion) {}
}
