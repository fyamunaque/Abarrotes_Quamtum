import 'package:serverpod/serverpod.dart';

import '../auth/firebase_identity.dart';
import '../common/shopper.dart';
import 'vip_service.dart';

/// Es VIP quien tiene el correo del token en la lista de VIPs activos **y**
/// verificado en Firebase (`email_verified`): sin verificar, cualquiera podría
/// crear una cuenta con el correo de un VIP.
class VipShopperResolver implements ShopperResolver {
  const VipShopperResolver(this._vips);

  final VipService _vips;

  @override
  Future<Shopper> resolve(Session session, FirebaseIdentity? identity) async {
    if (identity == null) return Shopper.anonymous;
    final email = identity.email;
    final isVip =
        email != null &&
        identity.emailVerified &&
        await _vips.isActiveVip(session, email);
    return Shopper(
      email: email,
      emailVerified: identity.emailVerified,
      isVip: isVip,
    );
  }
}
