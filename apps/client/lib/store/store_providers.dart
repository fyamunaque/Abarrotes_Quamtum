import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../config/api_config.dart';
import 'store_repository.dart';
import 'store_settings.dart';

/// Los datos de la tienda desde el servidor. Los tests lo reemplazan por uno
/// en memoria.
final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => HttpStoreRepository(
    ref.watch(apiClientProvider),
    ref.watch(authedApiProvider),
  ),
);

/// Dónde y cuándo se recogen los pedidos: al elegir recojo en el carrito y
/// en los pedidos de recojo. Se pide una vez y queda; si falla, se puede
/// volver a pedir (`ref.invalidate`).
final storeSettingsProvider = FutureProvider<StoreSettings>(
  (ref) => ref.watch(storeRepositoryProvider).settings(),
);
