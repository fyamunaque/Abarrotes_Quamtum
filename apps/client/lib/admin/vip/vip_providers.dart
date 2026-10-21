import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../common/page_list.dart';
import '../paged_notifier.dart';
import 'vip_customer.dart';
import 'vip_repository.dart';

final vipRepositoryProvider = Provider<VipRepository>(
  (ref) => HttpVipRepository(ref.watch(authedApiProvider)),
);

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
  Future<VipAddSummary> add(List<String> emails) async {
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
