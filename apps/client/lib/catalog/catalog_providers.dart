import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    AsyncNotifierProvider.family<ProductListNotifier, ProductList, String?>(
      ProductListNotifier.new,
    );

/// Lo que se cargó hasta ahora y cuántos hay en total.
class ProductList {
  const ProductList(
    this.products, {
    required this.total,
    this.loadingMore = false,
  });

  final List<Product> products;
  final int total;

  /// Si se está pidiendo la página siguiente.
  final bool loadingMore;

  bool get hasMore => products.length < total;
}

class ProductListNotifier extends AsyncNotifier<ProductList> {
  ProductListNotifier(this.categoryId);

  final String? categoryId;
  int _page = 1;

  @override
  Future<ProductList> build() async {
    _page = 1;
    final page = await ref
        .watch(catalogRepositoryProvider)
        .products(categoryId: categoryId);
    return ProductList(page.products, total: page.total);
  }

  /// Agrega la página siguiente al final. Si falla, la lista queda como
  /// estaba y el error sale de aquí, para que la pantalla lo muestre.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      ProductList(current.products, total: current.total, loadingMore: true),
    );
    try {
      final next = await ref
          .read(catalogRepositoryProvider)
          .products(categoryId: categoryId, page: _page + 1);
      _page++;
      state = AsyncData(
        ProductList([...current.products, ...next.products], total: next.total),
      );
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
