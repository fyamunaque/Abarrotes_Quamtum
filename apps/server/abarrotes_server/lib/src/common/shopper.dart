import 'package:serverpod/serverpod.dart';

import '../auth/firebase_identity.dart';

/// Quién mira el catálogo o compra, con lo que las promociones necesitan saber
/// de él. Lo arma un [ShopperResolver] a partir del token de la petición.
class Shopper {
  const Shopper({this.email, this.emailVerified = false, this.isVip = false});

  /// Un visitante sin cuenta (o con un token que no sirve).
  static const anonymous = Shopper();

  final String? email;
  final bool emailVerified;

  /// Si es un cliente VIP activo con el correo verificado.
  final bool isVip;
}

/// Arma el [Shopper] de una petición: sin [identity], [Shopper.anonymous].
abstract interface class ShopperResolver {
  Future<Shopper> resolve(Session session, FirebaseIdentity? identity);
}
