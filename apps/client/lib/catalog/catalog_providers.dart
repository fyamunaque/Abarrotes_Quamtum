import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/page_list.dart';
import '../config/api_config.dart';
import 'catalog_repository.dart';
import 'category.dart';
import 'http_catalog_repository.dart';
import 'product.dart';

/// El catálogo desde el servidor. Los tests lo reemplazan por uno en memoria.
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => HttpCatalogRepository(ref.watch(apiClientProvider)),
);

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);

/// Un producto, para su detalle.
final productProvider = FutureProvider.family<Product, String>(
  (ref, id) => ref.watch(catalogRepositoryProvider).product(id),
);

/// Los productos cargados de una categoría (null: todas), página a página.
final productListProvider =
    AsyncNotifierProvider.family<
      ProductListNotifier,
      PageList<Product>,
      String?
    >(ProductListNotifier.new);

class ProductListNotifier extends AsyncNotifier<PageList<Product>> {
  ProductListNotifier(this.categoryId);

  final String? categoryId;
  int _page = 1;

  @override
  Future<PageList<Product>> build() {
    _page = 1;
    return ref
        .watch(catalogRepositoryProvider)
        .products(categoryId: categoryId);
  }

  /// Agrega la página siguiente al final. Si falla, la lista queda como
  /// estaba y el error sale de aquí, para que la pantalla lo muestre.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.withLoadingMore());
    try {
      final next = await ref
          .read(catalogRepositoryProvider)
          .products(categoryId: categoryId, page: _page + 1);
      _page++;
      state = AsyncData(current.append(next));
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
