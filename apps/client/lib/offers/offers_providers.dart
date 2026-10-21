import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../session/session_provider.dart';
import 'offer.dart';
import 'offers_repository.dart';

/// Las ofertas desde el servidor. Los tests lo reemplazan por uno en memoria.
final offersRepositoryProvider = Provider<OffersRepository>(
  (ref) => HttpOffersRepository(
    ref.watch(apiClientProvider),
    idToken: ref.watch(optionalIdTokenProvider),
  ),
);

/// Las ofertas exclusivas de la cuenta. Si no es VIP, ninguna, y sin pedir
/// nada al servidor. Si pasa a serlo (o deja de serlo), se vuelven a pedir.
final exclusiveOffersProvider = FutureProvider.autoDispose<List<Offer>>((ref) {
  if (!ref.watch(isVipProvider)) return const [];
  return ref.watch(offersRepositoryProvider).exclusive();
});
