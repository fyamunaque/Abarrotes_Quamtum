import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import 'stats.dart';
import 'stats_repository.dart';

final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => HttpStatsRepository(ref.watch(authedApiProvider)),
);

// Cada reporte se carga por su lado: si uno falla, el resto del inicio se ve
// igual. autoDispose: al volver al inicio se piden de nuevo, con los números
// de ese momento.

final overviewProvider = FutureProvider.autoDispose<StatsOverview>(
  (ref) => ref.watch(statsRepositoryProvider).overview(),
);

final salesProvider = FutureProvider.autoDispose<SalesReport>(
  (ref) => ref.watch(statsRepositoryProvider).sales30Days(),
);

final topProductsProvider = FutureProvider.autoDispose<List<TopProduct>>(
  (ref) => ref.watch(statsRepositoryProvider).topProducts(),
);

final lowStockProvider = FutureProvider.autoDispose<List<LowStockItem>>(
  (ref) => ref.watch(statsRepositoryProvider).lowStock(),
);

final expiringProvider = FutureProvider.autoDispose<List<ExpiringItem>>(
  (ref) => ref.watch(statsRepositoryProvider).expiring(),
);
