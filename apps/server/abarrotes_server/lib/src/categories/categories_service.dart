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

  /// Las categorías por nombre, cada una con cuántos productos tiene (los
  /// inactivos también: son los que impiden borrarla). Una sola consulta
  /// para los conteos.
  Future<List<(Category, int)>> listWithProductCounts(Session session) async {
    final categories = await list(session);
    final rows = await session.db.unsafeQuery(
      'SELECT "categoryId"::text AS id, COUNT(*)::int AS n '
      'FROM products GROUP BY "categoryId"',
    );
    final counts = {
      for (final row in rows)
        row.toColumnMap()['id'] as String: row.toColumnMap()['n'] as int,
    };
    return [
      for (final category in categories)
        (category, counts[category.id.toString()] ?? 0),
    ];
  }

  Future<Category> get(Session session, UuidValue id) async {
    final category = await Category.db.findById(session, id);
    if (category == null) throw const ApiException(404, _notFound);
    return category;
  }

  /// Crea la categoría; [imageUrl], si viene, es una URL externa (las fotos
  /// se suben después, con [setImage]).
  Future<Category> create(
    Session session,
    String name, {
    String? description,
    String? imageUrl,
  }) async {
    await _assertNameIsFree(session, name);
    try {
      return await Category.db.insertRow(
        session,
        Category(name: name, description: description, imageUrl: imageUrl),
      );
    } on DatabaseUniqueViolationException {
      throw ApiException.conflict('Ya existe la categoría "$name"');
    }
  }

  /// Renombra la categoría y cambia su descripción: sin [name] el nombre
  /// queda como está; sin [description], la descripción también, salvo con
  /// [clearDescription], que la borra.
  ///
  /// Con [setImageUrl], la foto pasa a ser [imageUrl]: una URL externa, null
  /// (sin foto) o la foto subida que ya tiene; otra foto subida es 400 (se
  /// sube con [setImage]). Si deja una foto subida, se borra.
  Future<Category> update(
    Session session,
    UuidValue id,
    String? name, {
    String? description,
    bool clearDescription = false,
    String? imageUrl,
    bool setImageUrl = false,
  }) async {
    final category = await get(session, id);
    if (name == null &&
        description == null &&
        !clearDescription &&
        !setImageUrl) {
      return category;
    }
    if (setImageUrl &&
        CategoryImages.isStored(imageUrl) &&
        imageUrl != category.imageUrl) {
      throw const ApiException.badRequest(
        'Para cambiar la foto, súbela con PUT /categories/:id/image',
      );
    }
    if (name != null) await _assertNameIsFree(session, name, exceptId: id);
    final Category updated;
    try {
      updated = await Category.db.updateRow(
        session,
        category.copyWith(
          name: name ?? category.name,
          description: clearDescription
              ? null
              : description ?? category.description,
          imageUrl: setImageUrl ? imageUrl : category.imageUrl,
        ),
      );
    } on DatabaseUniqueViolationException {
      throw ApiException.conflict('Ya existe la categoría "$name"');
    }
    if (updated.imageUrl != category.imageUrl) {
      await _images.delete(session, category.imageUrl);
    }
    return updated;
  }

  /// Borra la categoría (y su foto, si era una subida) solo si no tiene
  /// productos, ni siquiera inactivos: cada producto necesita una categoría.
  /// Para eliminarla, primero hay que mover sus productos.
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
    // Ya nadie la usa.
    await _images.delete(session, category.imageUrl);
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

  /// Le quita la foto a la categoría [id] (vuelve a verse su color con la
  /// inicial) y la borra si era una subida. Sin foto, no cambia nada.
  Future<Category> removeImage(Session session, UuidValue id) async {
    final category = await get(session, id);
    if (category.imageUrl == null) return category;
    final updated = await Category.db.updateRow(
      session,
      category.copyWith(imageUrl: null),
    );
    await _images.delete(session, category.imageUrl);
    return updated;
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
