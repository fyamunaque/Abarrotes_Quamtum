import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/page_list.dart';
import '../config/api_config.dart';
import '../session/session_provider.dart';
import 'catalog_repository.dart';
import 'category.dart';
import 'http_catalog_repository.dart';
import 'product.dart';

/// El catálogo desde el servidor, con el token de la cuenta abierta (si hay).
/// Los tests lo reemplazan por uno en memoria.
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => HttpCatalogRepository(
    ref.watch(apiClientProvider),
    idToken: ref.watch(optionalIdTokenProvider),
  ),
);

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);

/// Un producto, para su detalle. Si la cuenta pasa a ser VIP (o deja de
/// serlo), se vuelve a pedir: el precio cambia.
final productProvider = FutureProvider.family<Product, String>((ref, id) {
  ref.watch(isVipProvider);
  return ref.watch(catalogRepositoryProvider).product(id);
});

/// "Promociones de hoy" en el inicio: la primera página de los productos con
/// una promoción vigente que la cuenta puede usar, con su precio. Si la cuenta
/// pasa a ser VIP (o deja de serlo), se vuelven a pedir.
final onSaleProductsProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) async {
  ref.watch(isVipProvider);
  final page = await ref
      .watch(catalogRepositoryProvider)
      .products(onSale: true);
  return page.items;
});

/// Los productos de "Más de" (la categoría) en el detalle de un producto.
typedef RelatedQuery = ({String categoryId, String productId});

/// Cuántos productos muestra "Más de" (la categoría).
const relatedLimit = 10;

/// Hasta [relatedLimit] productos de la categoría de [RelatedQuery], sin el
/// que se está viendo. Con el precio de la cuenta, como el catálogo.
final relatedProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, RelatedQuery>((ref, query) async {
      ref.watch(isVipProvider);
      final page = await ref
          .watch(catalogRepositoryProvider)
          .products(categoryId: query.categoryId);
      return [
        for (final product in page.items)
          if (product.id != query.productId) product,
      ].take(relatedLimit).toList();
    });

/// Qué muestra el catálogo: una categoría (null: todas) y lo buscado (null:
/// nada).
typedef CatalogQuery = ({String? categoryId, String? search});

/// Los productos cargados de [CatalogQuery], página a página.
final productListProvider =
    AsyncNotifierProvider.family<
      ProductListNotifier,
      PageList<Product>,
      CatalogQuery
    >(ProductListNotifier.new);

class ProductListNotifier extends AsyncNotifier<PageList<Product>> {
  ProductListNotifier(this.query);

  final CatalogQuery query;
  int _page = 1;

  @override
  Future<PageList<Product>> build() {
    _page = 1;
    // Cada cliente ve su precio: si pasa a ser VIP (o deja de serlo), la
    // lista se vuelve a pedir.
    ref.watch(isVipProvider);
    return ref
        .watch(catalogRepositoryProvider)
        .products(categoryId: query.categoryId, search: query.search);
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
          .products(
            categoryId: query.categoryId,
            search: query.search,
            page: _page + 1,
          );
      _page++;
      state = AsyncData(current.append(next));
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
