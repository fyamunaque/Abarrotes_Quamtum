import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../common/page_list.dart';
import '../paged_notifier.dart';
import 'inventory_repository.dart';
import 'movement.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => HttpInventoryRepository(ref.watch(authedApiProvider)),
);

final movementsProvider =
    AsyncNotifierProvider.autoDispose<MovementsNotifier, PageList<Movement>>(
      MovementsNotifier.new,
    );

class MovementsNotifier extends PagedNotifier<Movement> {
  @override
  Future<PageList<Movement>> fetch(int page) =>
      ref.read(inventoryRepositoryProvider).movements(page: page);

  /// Registra el movimiento y vuelve a la primera página, donde aparece.
  Future<Movement> record(MovementInput input) async {
    final movement = await ref.read(inventoryRepositoryProvider).record(input);
    await goTo(1);
    return movement;
  }
}
