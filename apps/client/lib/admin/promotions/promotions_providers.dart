import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../common/page_list.dart';
import '../paged_notifier.dart';
import 'promotion.dart';
import 'promotions_repository.dart';

final promotionsRepositoryProvider = Provider<PromotionsRepository>(
  (ref) => HttpPromotionsRepository(ref.watch(authedApiProvider)),
);

/// Las promociones, filtradas por estado (null: todas).
final promotionsProvider = AsyncNotifierProvider.autoDispose
    .family<PromotionsNotifier, PageList<Promotion>, PromotionStatus?>(
      PromotionsNotifier.new,
    );

class PromotionsNotifier extends PagedNotifier<Promotion> {
  PromotionsNotifier(this.status);

  final PromotionStatus? status;

  @override
  Future<PageList<Promotion>> fetch(int page) =>
      ref.read(promotionsRepositoryProvider).list(page: page, status: status);

  /// Crea la promoción y vuelve a cargar la tabla desde la primera página.
  Future<Promotion> create(PromotionInput input) async {
    final promotion = await ref
        .read(promotionsRepositoryProvider)
        .create(input);
    ref.invalidateSelf();
    return promotion;
  }

  /// Guarda los cambios y vuelve a pedir la página: con otro estado (p. ej.
  /// apagada), puede salir del filtro.
  Future<Promotion> save(String id, PromotionInput input) async {
    final promotion = await ref
        .read(promotionsRepositoryProvider)
        .update(id, input);
    replace(promotion, (current) => current.id == id);
    await _refreshQuietly();
    return promotion;
  }

  Future<void> delete(String id) async {
    await ref.read(promotionsRepositoryProvider).delete(id);
    await _refreshQuietly();
  }

  /// Si falla, la tabla queda como estaba: el cambio ya se guardó.
  Future<void> _refreshQuietly() => refresh().catchError((Object _) {});
}
