import '../common/api_client.dart';
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
  Future<ProductPage> products({String? categoryId, int page = 1}) async {
    final json = await _api.get(
      '/products',
      query: {'page': '$page', 'limit': '$pageSize', 'categoryId': ?categoryId},
      fallback: 'No se pudieron cargar los productos.',
    );
    return decodeResponse(
      () => switch (json) {
        {
          'data': final List<Object?> data,
          'meta': {'total': final int total},
        } =>
          ProductPage([
            for (final p in data) Product.fromJson(p),
          ], total: total),
        _ => throw FormatException('No es una página de productos', json),
      },
    );
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
