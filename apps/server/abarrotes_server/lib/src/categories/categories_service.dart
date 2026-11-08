import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../common/api_route.dart';
import '../common/http_json.dart';
import '../generated/protocol.dart';
import 'category_images.dart';

/// Categorías del catálogo, con su descripción y su foto.
class CategoriesService {
  CategoriesService({CategoryImages? images})
    : _images = images ?? CategoryImages();

  final CategoryImages _images;

  Future<List<Category>> list(Session session) =>
      Category.db.find(session, orderBy: (category) => category.name);

  Future<Category> get(Session session, UuidValue id) async {
    final category = await Category.db.findById(session, id);
    if (category == null) throw const ApiException(404, _notFound);
    return category;
  }

  Future<Category> create(
    Session session,
    String name, {
    String? description,
  }) async {
    await _assertNameIsFree(session, name);
    try {
      return await Category.db.insertRow(
        session,
        Category(name: name, description: description),
      );
    } on DatabaseUniqueViolationException {
      throw ApiException.conflict('Ya existe la categoría "$name"');
    }
  }

  /// Renombra la categoría y cambia su descripción: sin [name] el nombre
  /// queda como está; sin [description], la descripción también, salvo con
  /// [clearDescription], que la borra.
  Future<Category> update(
    Session session,
    UuidValue id,
    String? name, {
    String? description,
    bool clearDescription = false,
  }) async {
    final category = await get(session, id);
    if (name == null && description == null && !clearDescription) {
      return category;
    }
    if (name != null) await _assertNameIsFree(session, name, exceptId: id);
    try {
      return await Category.db.updateRow(
        session,
        category.copyWith(
          name: name ?? category.name,
          description: clearDescription
              ? null
              : description ?? category.description,
        ),
      );
    } on DatabaseUniqueViolationException {
      throw ApiException.conflict('Ya existe la categoría "$name"');
    }
  }

  /// Borra la categoría solo si no tiene productos, ni siquiera inactivos:
  /// cada producto necesita una categoría. Para eliminarla, primero hay que
  /// mover sus productos.
  Future<void> delete(Session session, UuidValue id) async {
    final category = await get(session, id);
    final products = await Product.db.count(
      session,
      where: (product) => product.categoryId.equals(id),
    );
    if (products > 0) {
      throw ApiException.conflict(
        'La categoría tiene $products producto${products == 1 ? '' : 's'}: '
        'muévelos a otra antes de eliminarla',
      );
    }
    try {
      await Category.db.deleteRow(session, category);
    } on DatabaseForeignKeyViolationException {
      // Se le asignó un producto justo mientras se borraba.
      throw const ApiException.conflict(
        'La categoría tiene productos: muévelos a otra antes de eliminarla',
      );
    }
  }

  /// Le pone a la categoría [id] la foto [jpeg], ya procesada con
  /// [CategoryImages.process]; la que tenía se borra si era una subida.
  Future<Category> setImage(
    Session session,
    UuidValue id,
    Uint8List jpeg,
  ) async {
    final category = await get(session, id);
    final url = await _images.store(session, id, jpeg);
    try {
      final updated = await Category.db.updateRow(
        session,
        category.copyWith(imageUrl: url),
      );
      await _images.delete(session, category.imageUrl);
      return updated;
    } catch (_) {
      await _images.delete(session, url);
      rethrow;
    }
  }

  /// La foto subida [file] de la categoría [categoryId] (JPEG), o null si no
  /// existe.
  Future<Uint8List?> image(
    Session session,
    String categoryId,
    String file,
  ) => _images.read(session, categoryId, file);

  /// La foto lista para guardar: JPEG de hasta 1200 px.
  Uint8List processImage(Uint8List bytes) => CategoryImages.process(bytes);

  /// El índice único de la base distingue mayúsculas: "Bebidas" y "bebidas"
  /// pasarían. Para la tienda son la misma categoría, así que se compara sin
  /// distinguirlas.
  Future<void> _assertNameIsFree(
    Session session,
    String name, {
    UuidValue? exceptId,
  }) async {
    final existing = await Category.db.findFirstRow(
      session,
      where: (category) {
        final sameName = category.name.ilike(escapeLike(name));
        return exceptId == null
            ? sameName
            : sameName & category.id.notEquals(exceptId);
      },
    );
    if (existing != null) {
      throw ApiException.conflict('Ya existe la categoría "${existing.name}"');
    }
  }

  static const _notFound = 'Categoría no encontrada';
}
