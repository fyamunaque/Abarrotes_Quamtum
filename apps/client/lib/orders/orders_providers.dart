import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../common/page_list.dart';
import '../config/api_config.dart';
import '../session/session.dart';
import '../session/session_provider.dart';
import 'http_order_repository.dart';
import 'order.dart';
import 'order_repository.dart';

/// Los pedidos desde el servidor. Los tests lo reemplazan por uno en memoria.
final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => HttpOrderRepository(ref.watch(apiClientProvider)),
);

/// Los pedidos de la cuenta abierta, página a página. Se vuelve a cargar si
/// cambia la cuenta.
final myOrdersProvider =
    AsyncNotifierProvider<MyOrdersNotifier, PageList<Order>>(
      MyOrdersNotifier.new,
    );

class MyOrdersNotifier extends AsyncNotifier<PageList<Order>> {
  int _page = 1;

  @override
  Future<PageList<Order>> build() {
    _page = 1;
    // Sin cuenta todavía (la sesión carga) espera: cuando la sesión cambie,
    // este provider se reconstruye. /mis-pedidos sin cuenta ni llega aquí:
    // el guard manda al ingreso.
    if (ref.watch(sessionProvider) is! SignedIn) {
      return Completer<PageList<Order>>().future;
    }
    return _fetch(1);
  }

  /// Vuelve a pedir la primera página sin pasar por "cargando": la lista
  /// sigue en pantalla y cada pedido se actualiza en su lugar (el
  /// seguimiento anima el avance del estado).
  Future<void> refresh() async {
    final fresh = await _fetch(1);
    _page = 1;
    state = AsyncData(fresh);
  }

  /// Agrega la página siguiente al final. Si falla, la lista queda como
  /// estaba y el error sale de aquí.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.withLoadingMore());
    try {
      final next = await _fetch(_page + 1);
      _page++;
      state = AsyncData(current.append(next));
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<PageList<Order>> _fetch(int page) async {
    final token = await ref.read(authRepositoryProvider).idToken();
    return ref.read(orderRepositoryProvider).mine(token, page: page);
  }
}
