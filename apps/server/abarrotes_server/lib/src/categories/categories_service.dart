import 'package:serverpod/serverpod.dart';

import '../common/api_route.dart';
import '../common/http_json.dart';
import '../generated/protocol.dart';

/// Categorías del catálogo.
class CategoriesService {
  const CategoriesService();

  Future<List<Category>> list(Session session) =>
      Category.db.find(session, orderBy: (category) => category.name);

  Future<Category> get(Session session, UuidValue id) async {
    final category = await Category.db.findById(session, id);
    if (category == null) throw const ApiException(404, _notFound);
    return category;
  }

  Future<Category> create(Session session, String name) async {
    await _assertNameIsFree(session, name);
    try {
      return await Category.db.insertRow(session, Category(name: name));
    } on DatabaseUniqueViolationException {
      throw ApiException.conflict('Ya existe la categoría "$name"');
    }
  }

  /// Renombra la categoría; sin [name] la deja como está.
  Future<Category> update(Session session, UuidValue id, String? name) async {
    final category = await get(session, id);
    if (name == null) return category;
    await _assertNameIsFree(session, name, exceptId: id);
    try {
      return await Category.db.updateRow(
        session,
        category.copyWith(name: name),
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
