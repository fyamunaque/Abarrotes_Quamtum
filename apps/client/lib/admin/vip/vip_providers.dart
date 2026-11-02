import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../common/page_list.dart';
import '../emails.dart';
import '../paged_notifier.dart';
import 'vip_customer.dart';
import 'vip_repository.dart';

final vipRepositoryProvider = Provider<VipRepository>(
  (ref) => HttpVipRepository(ref.watch(authedApiProvider)),
);

/// Busca hasta 20 clientes VIP activos cuyo correo contiene lo escrito.
typedef VipSearch = Future<List<VipCustomer>> Function(String search);

/// Para elegir a quién va una promoción de clientes elegidos.
final vipSearchProvider = Provider<VipSearch>((ref) {
  final vips = ref.watch(vipRepositoryProvider);
  return (search) async => (await vips.list(search: search)).items;
});

/// Los clientes VIP, filtrados por lo buscado ('' para todos).
final vipCustomersProvider = AsyncNotifierProvider.autoDispose
    .family<VipCustomersNotifier, PageList<VipCustomer>, String>(
      VipCustomersNotifier.new,
    );

class VipCustomersNotifier extends PagedNotifier<VipCustomer> {
  VipCustomersNotifier(this.search);

  final String search;

  @override
  Future<PageList<VipCustomer>> fetch(int page) =>
      ref.read(vipRepositoryProvider).list(page: page, search: search);

  /// Agrega [emails] y vuelve a cargar la tabla desde la primera página.
  Future<EmailAddSummary> add(List<String> emails) async {
    final summary = await ref.read(vipRepositoryProvider).add(emails);
    if (summary.added.isNotEmpty) ref.invalidateSelf();
    return summary;
  }

  /// Lo da de baja y vuelve a pedir la página: deja de estar en la lista.
  Future<void> remove(String id) async {
    await ref.read(vipRepositoryProvider).remove(id);
    // Si falla, la tabla queda como estaba: la baja ya se guardó.
    await refresh().catchError((Object _) {});
  }
}
