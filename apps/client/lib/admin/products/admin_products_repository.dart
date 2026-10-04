import '../../catalog/product.dart';
import '../../common/api_client.dart';
import '../../common/page_list.dart';
import 'product_input.dart';

/// Los productos desde el panel, también los dados de baja (solo admin y
/// staff). Los errores salen como `ApiFailure` (p. ej. 409 si el SKU ya
/// existe).
abstract interface class AdminProductsRepository {
  /// Una página, por nombre. [search] busca en el nombre y el SKU.
  Future<PageList<Product>> list({
    int page = 1,
    String? search,
    String? categoryId,
  });

  Future<Product> create(ProductInput input);

  Future<Product> update(String id, ProductInput input);

  /// Baja lógica: el producto deja de verse en la tienda.
  Future<Product> deactivate(String id);
}

class HttpAdminProductsRepository implements AdminProductsRepository {
  HttpAdminProductsRepository(this._api);

  final AuthedApi _api;

  static const pageSize = 20;

  @override
  Future<PageList<Product>> list({
    int page = 1,
    String? search,
    String? categoryId,
  }) async {
    final json = await _api.get(
      '/products',
      query: {
        'page': '$page',
        'limit': '$pageSize',
        'includeInactive': 'true',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'categoryId': ?categoryId,
      },
      fallback: 'No se pudieron cargar los productos.',
    );
    return decodeResponse(() => decodePage(json, Product.fromJson));
  }

  @override
  Future<Product> create(ProductInput input) async {
    final json = await _api.post(
      '/products',
      input.toJson(create: true),
      fallback: 'No se pudo crear el producto.',
    );
    return decodeResponse(() => Product.fromJson(json));
  }

  @override
  Future<Product> update(String id, ProductInput input) async {
    final json = await _api.patch(
      '/products/${Uri.encodeComponent(id)}',
      input.toJson(create: false),
      fallback: 'No se pudo guardar el producto.',
    );
    return decodeResponse(() => Product.fromJson(json));
  }

  @override
  Future<Product> deactivate(String id) async {
    final json = await _api.delete(
      '/products/${Uri.encodeComponent(id)}',
      fallback: 'No se pudo dar de baja el producto.',
    );
    return decodeResponse(() => Product.fromJson(json));
  }
}
