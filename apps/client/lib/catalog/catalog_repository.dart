import '../common/page_list.dart';
import 'category.dart';
import 'product.dart';

/// El catálogo público: categorías y productos activos. Los errores salen
/// como `ApiFailure`.
abstract interface class CatalogRepository {
  /// Las categorías, por nombre.
  Future<List<Category>> categories();

  /// Una página de productos activos, por nombre. Con [categoryId], solo los
  /// de esa categoría.
  Future<PageList<Product>> products({String? categoryId, int page = 1});

  /// Un producto activo. Si no existe o está dado de baja, `ApiFailure` con
  /// status 404 (o 400 si el id no es válido).
  Future<Product> product(String id);
}
