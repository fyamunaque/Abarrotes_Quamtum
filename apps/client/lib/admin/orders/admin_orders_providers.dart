import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../common/page_list.dart';
import '../../orders/order_status.dart';
import '../paged_notifier.dart';
import 'admin_order.dart';
import 'admin_orders_repository.dart';

final adminOrdersRepositoryProvider = Provider<AdminOrdersRepository>(
  (ref) => HttpAdminOrdersRepository(ref.watch(authedApiProvider)),
);

/// Los pedidos del panel, filtrados por estado (null: todos).
final adminOrdersProvider = AsyncNotifierProvider.autoDispose
    .family<AdminOrdersNotifier, PageList<AdminOrder>, OrderStatus?>(
      AdminOrdersNotifier.new,
    );

class AdminOrdersNotifier extends PagedNotifier<AdminOrder> {
  AdminOrdersNotifier(this.status);

  final OrderStatus? status;

  @override
  Future<PageList<AdminOrder>> fetch(int page) =>
      ref.read(adminOrdersRepositoryProvider).list(page: page, status: status);

  /// Cambia el estado y deja el pedido actualizado en la página. Devuelve el
  /// pedido como quedó.
  Future<AdminOrder> changeStatus(
    AdminOrder order,
    OrderStatus next, {
    String? pickupCode,
  }) async {
    final updated = await ref
        .read(adminOrdersRepositoryProvider)
        .changeStatus(order.id, next, pickupCode: pickupCode);
    replace(updated, (current) => current.id == updated.id);
    return updated;
  }
}
