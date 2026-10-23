import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../catalog/product.dart';
import '../../common/page_list.dart';
import '../paged_notifier.dart';
import 'admin_products_repository.dart';
import 'product_input.dart';

final adminProductsRepositoryProvider = Provider<AdminProductsRepository>(
  (ref) => HttpAdminProductsRepository(ref.watch(authedApiProvider)),
);

/// Los filtros de la tabla de productos.
typedef ProductFilter = ({String search, String? categoryId});

final adminProductsProvider = AsyncNotifierProvider.autoDispose
    .family<AdminProductsNotifier, PageList<Product>, ProductFilter>(
      AdminProductsNotifier.new,
    );

class AdminProductsNotifier extends PagedNotifier<Product> {
  AdminProductsNotifier(this.filter);

  final ProductFilter filter;

  @override
  Future<PageList<Product>> fetch(int page) => ref
      .read(adminProductsRepositoryProvider)
      .list(page: page, search: filter.search, categoryId: filter.categoryId);

  /// Crea el producto y vuelve a cargar la tabla desde la primera página (va
  /// por nombre: el nuevo puede caer en cualquiera).
  Future<Product> create(ProductInput input) async {
    final product = await ref
        .read(adminProductsRepositoryProvider)
        .create(input);
    ref.invalidateSelf();
    return product;
  }

  /// Guarda los cambios y deja el producto actualizado en la página.
  Future<Product> save(String id, ProductInput input) async {
    final product = await ref
        .read(adminProductsRepositoryProvider)
        .update(id, input);
    replace(product, (current) => current.id == id);
    return product;
  }

  /// Le sube la foto y deja el producto con ella en la página.
  Future<Product> uploadImage(
    String id,
    List<int> bytes, {
    required String contentType,
  }) async {
    final product = await ref
        .read(adminProductsRepositoryProvider)
        .uploadImage(id, bytes, contentType: contentType);
    replace(product, (current) => current.id == id);
    return product;
  }

  /// Lo da de baja (deja de verse en la tienda) y lo deja así en la página.
  Future<Product> deactivate(String id) async {
    final product = await ref
        .read(adminProductsRepositoryProvider)
        .deactivate(id);
    replace(product, (current) => current.id == id);
    return product;
  }
}
