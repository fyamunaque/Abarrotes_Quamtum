import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/page_list.dart';

/// Una tabla del panel que va página por página (ver `AdminTable`). Cada
/// sección dice cómo pedir una página en [fetch]; los filtros van en el
/// argumento de su provider (family).
abstract class PagedNotifier<T> extends AsyncNotifier<PageList<T>> {
  int _page = 1;

  /// La página [page] (desde 1). Los errores salen como `ApiFailure`.
  Future<PageList<T>> fetch(int page);

  @override
  Future<PageList<T>> build() {
    _page = 1;
    return fetch(1);
  }

  /// Muestra la página [page]. Mientras llega, la tabla sigue con la anterior.
  Future<void> goTo(int page) async {
    final next = await fetch(page);
    _page = page;
    state = AsyncData(next);
  }

  /// Vuelve a pedir la página actual (p. ej. después de editar). Si quedó
  /// vacía (se borró lo último que tenía), muestra la anterior.
  Future<void> refresh() async {
    await goTo(_page);
    if (_page > 1 && (state.value?.items.isEmpty ?? false)) {
      await goTo(_page - 1);
    }
  }

  /// Deja [item] en lugar del que cumple [matches], sin volver a pedir nada.
  void replace(T item, bool Function(T) matches) {
    if (state.value case final page?) {
      state = AsyncData(page.replace(item, matches));
    }
  }
}
