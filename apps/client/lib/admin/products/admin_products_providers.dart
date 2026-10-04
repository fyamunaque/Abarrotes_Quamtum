import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../catalog/product.dart';
import '../../common/page_list.dart';
import '../paged_notifier.dart';
import 'admin_products_repository.dart';

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
}
