import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../common/page_list.dart';
import '../../orders/fulfillment.dart';
import '../../orders/order_status.dart';
import '../paged_notifier.dart';
import 'admin_order.dart';
import 'admin_orders_repository.dart';

final adminOrdersRepositoryProvider = Provider<AdminOrdersRepository>(
  (ref) => HttpAdminOrdersRepository(ref.watch(authedApiProvider)),
);

/// Los filtros de la tabla de pedidos (null: todos).
typedef AdminOrdersFilter = ({
  OrderStatus? status,
  FulfillmentType? fulfillmentType,
});

/// Sin filtros.
const AdminOrdersFilter allOrders = (status: null, fulfillmentType: null);

/// Los pedidos del panel, con sus filtros.
final adminOrdersProvider = AsyncNotifierProvider.autoDispose
    .family<AdminOrdersNotifier, PageList<AdminOrder>, AdminOrdersFilter>(
      AdminOrdersNotifier.new,
    );

class AdminOrdersNotifier extends PagedNotifier<AdminOrder> {
  AdminOrdersNotifier(this.filter);

  final AdminOrdersFilter filter;

  @override
  Future<PageList<AdminOrder>> fetch(int page) => ref
      .read(adminOrdersRepositoryProvider)
      .list(
        page: page,
        status: filter.status,
        fulfillmentType: filter.fulfillmentType,
      );

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

/// Para caja: los pedidos de recojo que se preparan o esperan a su cliente.
/// Primero los que esperan (el que espera hace más, arriba) y después los que
/// se preparan (el más viejo, arriba).
final pickupQueueProvider =
    AsyncNotifierProvider.autoDispose<PickupQueueNotifier, List<AdminOrder>>(
      PickupQueueNotifier.new,
    );

class PickupQueueNotifier extends AsyncNotifier<List<AdminOrder>> {
  /// Cuántos de cada estado se piden: en una caja no se juntan más.
  static const limit = 100;

  @override
  Future<List<AdminOrder>> build() => _fetch();

  Future<List<AdminOrder>> _fetch() async {
    final orders = ref.read(adminOrdersRepositoryProvider);
    Future<List<AdminOrder>> inStatus(OrderStatus status) async =>
        (await orders.list(
          status: status,
          fulfillmentType: FulfillmentType.pickup,
          limit: limit,
        )).items;
    final (waiting, preparing) = await (
      inStatus(OrderStatus.readyForPickup),
      inStatus(OrderStatus.preparing),
    ).wait;
    DateTime readyAt(AdminOrder order) =>
        order.order.readyForPickupAt ?? order.order.createdAt;
    return [
      ...List.of(waiting)..sort((a, b) => readyAt(a).compareTo(readyAt(b))),
      ...List.of(preparing)
        ..sort((a, b) => a.order.createdAt.compareTo(b.order.createdAt)),
    ];
  }

  /// Vuelve a pedir la lista. Mientras llega se sigue viendo la anterior; si
  /// falla, queda como estaba y el error sale al que llamó.
  Future<void> refresh() async => state = AsyncData(await _fetch());

  /// Lo pasa a [next] (con el [pickupCode] para entregarlo) y vuelve a pedir
  /// la lista: uno recogido sale de ella.
  Future<void> changeStatus(
    AdminOrder order,
    OrderStatus next, {
    String? pickupCode,
  }) async {
    await ref
        .read(adminOrdersRepositoryProvider)
        .changeStatus(order.id, next, pickupCode: pickupCode);
    await refresh().catchError((Object _) {});
  }
}
