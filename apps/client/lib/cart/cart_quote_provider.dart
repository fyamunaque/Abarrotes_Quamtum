import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../orders/orders_providers.dart';
import '../orders/quote.dart';
import '../session/session.dart';
import '../session/session_provider.dart';
import 'cart.dart';
import 'cart_provider.dart';

/// Cómo se cobraría el carrito hoy, con las promociones de quien mira: la
/// pide al servidor [CartQuoteNotifier.debounce] después del último cambio
/// (así no se pide una por cada toque de "+"). Con el carrito vacío, null.
/// Si falla, el error: el carrito vuelve a su estimación, sin reintentar
/// solo (se vuelve a pedir con el próximo cambio).
final cartQuoteProvider = AsyncNotifierProvider<CartQuoteNotifier, Quote?>(
  CartQuoteNotifier.new,
  retry: (_, _) => null,
);

class CartQuoteNotifier extends AsyncNotifier<Quote?> {
  static const debounce = Duration(milliseconds: 400);

  @override
  Future<Quote?> build() async {
    final cart = ref.watch(cartProvider);
    // Con otra cuenta (o al ingresar), otras promociones.
    final signedIn = ref.watch(
      sessionProvider.select(
        (session) => switch (session) {
          SignedIn(:final user) => (user.email, user.isVip),
          _ => null,
        },
      ),
    );
    if (cart.isEmpty) return null;

    // Si el carrito cambia antes, esta vuelta se descarta y el timer se
    // cancela: nunca llega a pedirse.
    final wait = Completer<void>();
    final timer = Timer(debounce, wait.complete);
    ref.onDispose(timer.cancel);
    await wait.future;

    String? token;
    if (signedIn != null) {
      try {
        token = await ref.read(authRepositoryProvider).idToken();
      } on Object {
        // Sin token: las promociones de todos.
      }
    }
    return ref.read(orderRepositoryProvider).quote([
      for (final line in cart.lines)
        (productId: line.product.id, quantity: line.quantity),
    ], idToken: token);
  }
}

/// [quote] si se pidió para [cart] tal como está (los mismos productos y
/// cantidades, aunque el servidor haya dejado afuera alguno que ya no
/// está); si no (la del último cambio todavía no llega), null.
Quote? quoteFor(Cart cart, Quote? quote) {
  if (quote == null || quote.requested.length != cart.lines.length) {
    return null;
  }
  for (final (i, line) in cart.lines.indexed) {
    final requested = quote.requested[i];
    if (requested.productId != line.product.id ||
        requested.quantity != line.quantity) {
      return null;
    }
  }
  return quote;
}
