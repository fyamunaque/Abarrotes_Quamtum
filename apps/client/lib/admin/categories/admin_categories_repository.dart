import '../../catalog/category.dart';
import '../../common/api_client.dart';

/// Una categoría en el panel, con cuántos productos tiene (también los dados
/// de baja).
typedef AdminCategory = ({Category category, int productCount});

/// Las categorías desde el panel (con `categories.manage`). Los errores
/// salen como `ApiFailure` (p. ej. 409 si el nombre ya existe o si tiene
/// productos al borrarla).
abstract interface class AdminCategoriesRepository {
  /// Todas, por nombre, con su cantidad de productos.
  Future<List<AdminCategory>> list();

  Future<Category> create(String name, {String? description});

  /// Cambia el nombre y la descripción. Una descripción vacía la borra.
  Future<Category> update(
    String id, {
    required String name,
    required String description,
  });

  /// Le pone la foto [bytes]; el servidor la achica y reemplaza a la que
  /// tenía.
  Future<Category> uploadImage(
    String id,
    List<int> bytes, {
    required String contentType,
  });

  /// Le quita la foto: la tienda vuelve a mostrar su color con la inicial.
  Future<Category> removeImage(String id);

  /// Solo si no tiene productos (si no, 409 con el aviso del servidor).
  Future<void> delete(String id);
}

class HttpAdminCategoriesRepository implements AdminCategoriesRepository {
  HttpAdminCategoriesRepository(this._api);

  final AuthedApi _api;

  /// `GET /categories/summary`: cada categoría con `productCount` (también
  /// los productos dados de baja), en una sola petición.
  @override
  Future<List<AdminCategory>> list() async {
    final json = await _api.get(
      '/categories/summary',
      fallback: 'No se pudieron cargar las categorías.',
    );
    return decodeResponse(
      () => [
        for (final item in json as List)
          (
            category: Category.fromJson(item),
            productCount: (item as Map<String, Object?>)['productCount'] as int,
          ),
      ],
    );
  }

  @override
  Future<Category> create(String name, {String? description}) async {
    final json = await _api.post('/categories', {
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
    }, fallback: 'No se pudo crear la categoría.');
    return decodeResponse(() => Category.fromJson(json));
  }

  @override
  Future<Category> update(
    String id, {
    required String name,
    required String description,
  }) async {
    final json = await _api.patch('/categories/${Uri.encodeComponent(id)}', {
      'name': name,
      'description': description,
    }, fallback: 'No se pudo guardar la categoría.');
    return decodeResponse(() => Category.fromJson(json));
  }

  @override
  Future<Category> uploadImage(
    String id,
    List<int> bytes, {
    required String contentType,
  }) async {
    final json = await _api.putBytes(
      '/categories/${Uri.encodeComponent(id)}/image',
      bytes,
      contentType: contentType,
      fallback: 'No se pudo subir la foto.',
    );
    return decodeResponse(() => Category.fromJson(json));
  }

  @override
  Future<Category> removeImage(String id) async {
    final json = await _api.delete(
      '/categories/${Uri.encodeComponent(id)}/image',
      fallback: 'No se pudo quitar la foto.',
    );
    return decodeResponse(() => Category.fromJson(json));
  }

  @override
  Future<void> delete(String id) => _api.delete(
    '/categories/${Uri.encodeComponent(id)}',
    fallback: 'No se pudo borrar la categoría.',
  );
}
