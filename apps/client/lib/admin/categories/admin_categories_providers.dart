import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../catalog/catalog_providers.dart';
import '../../catalog/category.dart';
import 'admin_categories_repository.dart';

final adminCategoriesRepositoryProvider = Provider<AdminCategoriesRepository>(
  (ref) => HttpAdminCategoriesRepository(ref.watch(authedApiProvider)),
);

/// Las categorías del panel, con su cantidad de productos. Cada cambio las
/// vuelve a pedir, y también las de la tienda ([categoriesProvider]).
final adminCategoriesProvider =
    AsyncNotifierProvider.autoDispose<
      AdminCategoriesNotifier,
      List<AdminCategory>
    >(AdminCategoriesNotifier.new);

class AdminCategoriesNotifier extends AsyncNotifier<List<AdminCategory>> {
  AdminCategoriesRepository get _repository =>
      ref.read(adminCategoriesRepositoryProvider);

  @override
  Future<List<AdminCategory>> build() =>
      ref.watch(adminCategoriesRepositoryProvider).list();

  Future<Category> create(String name, {String? description}) =>
      _changed(_repository.create(name, description: description));

  Future<Category> save(
    String id, {
    required String name,
    required String description,
  }) => _changed(_repository.update(id, name: name, description: description));

  Future<Category> uploadImage(
    String id,
    List<int> bytes, {
    required String contentType,
  }) => _changed(_repository.uploadImage(id, bytes, contentType: contentType));

  Future<Category> removeImage(String id) =>
      _changed(_repository.removeImage(id));

  Future<void> delete(String id) => _changed(_repository.delete(id));

  Future<T> _changed<T>(Future<T> change) async {
    final result = await change;
    ref
      ..invalidateSelf()
      ..invalidate(categoriesProvider);
    return result;
  }
}
