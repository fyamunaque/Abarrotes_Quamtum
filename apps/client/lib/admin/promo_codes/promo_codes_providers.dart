import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../common/page_list.dart';
import '../paged_notifier.dart';
import '../promotions/promotion.dart';
import '../promotions/promotions_providers.dart';
import 'promo_code.dart';
import 'promo_codes_repository.dart';

final promoCodesRepositoryProvider = Provider<PromoCodesRepository>(
  (ref) => HttpPromoCodesRepository(ref.watch(authedApiProvider)),
);

/// Los filtros de la tabla de códigos: el estado (null: todos) y lo buscado.
typedef PromoCodesFilter = ({PromoCodeStatus? status, String search});

/// Los códigos, con [PromoCodesFilter].
final promoCodesProvider = AsyncNotifierProvider.autoDispose
    .family<PromoCodesNotifier, PageList<PromoCode>, PromoCodesFilter>(
      PromoCodesNotifier.new,
    );

class PromoCodesNotifier extends PagedNotifier<PromoCode> {
  PromoCodesNotifier(this.filter);

  final PromoCodesFilter filter;

  @override
  Future<PageList<PromoCode>> fetch(int page) => ref
      .read(promoCodesRepositoryProvider)
      .list(page: page, status: filter.status, search: filter.search);

  /// Crea el código y vuelve a cargar la tabla desde la primera página.
  Future<PromoCode> create(PromoCodeInput input) async {
    final code = await ref.read(promoCodesRepositoryProvider).create(input);
    ref.invalidateSelf();
    return code;
  }

  /// Guarda los cambios y vuelve a pedir la página: con otro estado (p. ej.
  /// pausado), puede salir del filtro.
  Future<PromoCode> save(String id, PromoCodeInput input) async {
    final code = await ref.read(promoCodesRepositoryProvider).update(id, input);
    replace(code, (current) => current.id == id);
    ref.invalidate(promoCodeProvider(id));
    await _refreshQuietly();
    return code;
  }

  Future<void> delete(String id) async {
    await ref.read(promoCodesRepositoryProvider).delete(id);
    await _refreshQuietly();
  }

  /// Si falla, la tabla queda como estaba: el cambio ya se guardó.
  Future<void> _refreshQuietly() => refresh().catchError((Object _) {});
}

/// Un código con sus promociones al día, y sus promociones: agregarlas,
/// editarlas y borrarlas (con `/promotions`).
final promoCodeProvider = AsyncNotifierProvider.autoDispose
    .family<PromoCodeNotifier, PromoCode, String>(PromoCodeNotifier.new);

class PromoCodeNotifier extends AsyncNotifier<PromoCode> {
  PromoCodeNotifier(this.id);

  final String id;

  @override
  Future<PromoCode> build() => ref.read(promoCodesRepositoryProvider).get(id);

  /// Una promoción nueva de este código. Si se cruza con otras del
  /// producto, `PromotionOverlap`: con [confirmOverlap] se crea igual.
  Future<Promotion> addPromotion(
    PromotionInput input, {
    bool confirmOverlap = false,
  }) async {
    final promotion = await ref
        .read(promotionsRepositoryProvider)
        .create(input, confirmOverlap: confirmOverlap);
    await _reload();
    return promotion;
  }

  Future<Promotion> savePromotion(
    String promotionId,
    PromotionInput input, {
    bool confirmOverlap = false,
  }) async {
    final promotion = await ref
        .read(promotionsRepositoryProvider)
        .update(promotionId, input, confirmOverlap: confirmOverlap);
    await _reload();
    return promotion;
  }

  Future<void> deletePromotion(String promotionId) async {
    await ref.read(promotionsRepositoryProvider).delete(promotionId);
    await _reload();
  }

  /// El código con sus promociones de ahora; la lista de Promociones
  /// también cambió.
  Future<void> _reload() async {
    ref.invalidate(promotionsProvider);
    state = AsyncData(await ref.read(promoCodesRepositoryProvider).get(id));
  }
}
