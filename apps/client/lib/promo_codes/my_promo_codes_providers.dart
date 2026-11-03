import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../cart/cart_quote_provider.dart';
import '../config/api_config.dart';
import '../session/session.dart';
import '../session/session_provider.dart';
import 'my_promo_code.dart';
import 'my_promo_codes_repository.dart';

/// Los códigos de la cuenta desde el servidor. Los tests lo reemplazan por
/// uno en memoria.
final myPromoCodesRepositoryProvider = Provider<MyPromoCodesRepository>(
  (ref) => HttpMyPromoCodesRepository(ref.watch(apiClientProvider)),
);

/// Los códigos que activó la cuenta abierta (sin cuenta, ninguno). Se
/// vuelven a pedir al cambiar de cuenta.
final myPromoCodesProvider =
    AsyncNotifierProvider<MyPromoCodesNotifier, List<MyPromoCode>>(
      MyPromoCodesNotifier.new,
    );

class MyPromoCodesNotifier extends AsyncNotifier<List<MyPromoCode>> {
  @override
  Future<List<MyPromoCode>> build() async {
    final email = ref.watch(
      sessionProvider.select(
        (session) => switch (session) {
          SignedIn(:final user) => user.email,
          _ => null,
        },
      ),
    );
    if (email == null) return const [];
    final token = await ref.read(authRepositoryProvider).idToken();
    return ref.read(myPromoCodesRepositoryProvider).mine(token);
  }

  /// Activa [code] y lo suma a la lista. El carrito vuelve a cotizar: sus
  /// promociones ya cuentan. Si falla, `ApiFailure` con el motivo y la
  /// lista queda igual.
  Future<MyPromoCode> redeem(String code) async {
    final token = await ref.read(authRepositoryProvider).idToken();
    final redeemed = await ref
        .read(myPromoCodesRepositoryProvider)
        .redeem(token, code);
    ref.invalidate(cartQuoteProvider);
    state = AsyncData([
      for (final current in state.value ?? const <MyPromoCode>[])
        if (current.code != redeemed.code) current,
      redeemed,
    ]);
    return redeemed;
  }
}
