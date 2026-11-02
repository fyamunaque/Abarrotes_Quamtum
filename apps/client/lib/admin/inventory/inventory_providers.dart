import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../common/page_list.dart';
import '../paged_notifier.dart';
import 'inventory_repository.dart';
import 'movement.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => HttpInventoryRepository(ref.watch(authedApiProvider)),
);

/// Los filtros del historial (vacío o null: todos). [from] y [to] son días
/// de la tienda, ambos incluidos.
typedef MovementsFilter = ({
  String search,
  MovementOrigin? origin,
  String? categoryId,
  DateTime? from,
  DateTime? to,
});

/// Sin filtros.
const MovementsFilter allMovements = (
  search: '',
  origin: null,
  categoryId: null,
  from: null,
  to: null,
);

/// El historial de inventario, con sus filtros.
final movementsProvider = AsyncNotifierProvider.autoDispose
    .family<MovementsNotifier, PageList<Movement>, MovementsFilter>(
      MovementsNotifier.new,
    );

class MovementsNotifier extends PagedNotifier<Movement> {
  MovementsNotifier(this.filter);

  final MovementsFilter filter;

  @override
  Future<PageList<Movement>> fetch(int page) => ref
      .read(inventoryRepositoryProvider)
      .movements(
        page: page,
        search: filter.search,
        origin: filter.origin,
        categoryId: filter.categoryId,
        from: filter.from,
        to: filter.to,
      );

  /// Registra el movimiento y vuelve a la primera página, donde aparece.
  Future<Movement> record(MovementInput input) async {
    final movement = await ref.read(inventoryRepositoryProvider).record(input);
    await goTo(1);
    return movement;
  }
}
