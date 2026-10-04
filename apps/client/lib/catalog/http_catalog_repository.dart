import '../common/api_client.dart';
import '../common/page_list.dart';
import 'catalog_repository.dart';
import 'category.dart';
import 'product.dart';

/// [CatalogRepository] contra `GET /categories` y `GET /products`.
class HttpCatalogRepository implements CatalogRepository {
  HttpCatalogRepository(this._api);

  final ApiClient _api;

  /// Productos por página (el servidor acepta hasta 100).
  static const pageSize = 20;

  @override
  Future<List<Category>> categories() async {
    final json = await _api.get(
      '/categories',
      fallback: 'No se pudieron cargar las categorías.',
    );
    return decodeResponse(
      () => [for (final category in json! as List) Category.fromJson(category)],
    );
  }

  @override
  Future<PageList<Product>> products({
    String? categoryId,
    String? search,
    int page = 1,
  }) async {
    final text = search?.trim() ?? '';
    final json = await _api.get(
      '/products',
      query: {
        'page': '$page',
        'limit': '$pageSize',
        'categoryId': ?categoryId,
        // Como el servidor: hasta 100 caracteres.
        if (text.isNotEmpty)
          'search': text.length > 100 ? text.substring(0, 100) : text,
      },
      fallback: 'No se pudieron cargar los productos.',
    );
    return decodeResponse(() => decodePage(json, Product.fromJson));
  }

  @override
  Future<Product> product(String id) async {
    final json = await _api.get(
      '/products/${Uri.encodeComponent(id)}',
      fallback: 'Este producto ya no está disponible.',
    );
    return decodeResponse(() => Product.fromJson(json));
  }
}
