import '../common/api_client.dart';
import '../common/page_list.dart';
import 'catalog_repository.dart';
import 'category.dart';
import 'product.dart';

/// [CatalogRepository] contra `GET /categories` y `GET /products`. Los
/// productos se piden con el ID token de la cuenta abierta ([idToken], null
/// sin sesión): el servidor da a cada cliente su precio (p. ej. el VIP).
class HttpCatalogRepository implements CatalogRepository {
  HttpCatalogRepository(this._api, {Future<String?> Function()? idToken})
    : _idToken = idToken ?? _anonymous;

  final ApiClient _api;
  final Future<String?> Function() _idToken;

  static Future<String?> _anonymous() async => null;

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
      idToken: await _idToken(),
      fallback: 'No se pudieron cargar los productos.',
    );
    return decodeResponse(() => decodePage(json, Product.fromJson));
  }

  @override
  Future<Product> product(String id) async {
    final json = await _api.get(
      '/products/${Uri.encodeComponent(id)}',
      idToken: await _idToken(),
      fallback: 'Este producto ya no está disponible.',
    );
    return decodeResponse(() => Product.fromJson(json));
  }
}
