import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/categories/admin_categories_providers.dart';
import '../../../admin/categories/admin_categories_repository.dart';
import '../../../catalog/category.dart';
import '../../../common/page_list.dart';
import '../../catalog/category_photo.dart';
import '../shared/admin_page.dart';
import '../shared/admin_table.dart';
import 'category_form.dart';

/// Las categorías del catálogo (con `categories.manage`): su foto, su
/// descripción y cuántos productos tiene cada una. Crear, editar (nombre,
/// descripción y foto) y borrar las que no tienen productos.
class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void notify(String message) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    Future<void> open({AdminCategory? row}) async {
      final result = await showAdminForm<CategoryFormResult>(
        context,
        title: row == null ? 'Nueva categoría' : 'Editar categoría',
        builder: (_) => CategoryForm(row: row),
      );
      switch (result) {
        case CategorySaved(:final category):
          notify(
            row == null
                ? 'Creaste "${category.name}".'
                : 'Guardaste "${category.name}".',
          );
        case CategoryDeleted(:final name):
          notify('Borraste "$name".');
        case null:
          break;
      }
    }

    final categories = ref.watch(adminCategoriesProvider);
    return AdminPage(
      title: 'Categorías',
      actions: [
        FilledButton.icon(
          onPressed: open,
          icon: const Icon(Icons.add),
          label: const Text('Nueva categoría'),
        ),
      ],
      children: [
        AdminTable<AdminCategory>(
          // Todas en una página: son pocas.
          value: categories.whenData(
            (list) => PageList(
              list,
              total: list.length,
              pageSize: list.isEmpty ? 1 : list.length,
            ),
          ),
          columns: [
            AdminColumn('Categoría', (row) => _NameCell(row.category), flex: 3),
            AdminColumn(
              'Descripción',
              (row) => Text(row.category.description ?? '—'),
              flex: 4,
            ),
            AdminColumn(
              'Productos',
              (row) => Text(productsLabel(row.productCount)),
              numeric: true,
            ),
          ],
          rowKey: (row) => row.category.id,
          rowLabel: (row) => [
            row.category.name,
            ?row.category.description,
            productsLabel(row.productCount),
          ].join(', '),
          onRowTap: (row) => open(row: row),
          onPage: (_) {},
          onRetry: () => ref.invalidate(adminCategoriesProvider),
          emptyText: 'Todavía no hay categorías.',
        ),
      ],
    );
  }
}

/// "Sin productos", "1 producto", "3 productos".
String productsLabel(int count) => switch (count) {
  0 => 'Sin productos',
  1 => '1 producto',
  _ => '$count productos',
};

class _NameCell extends StatelessWidget {
  const _NameCell(this.category);

  final Category category;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.square(
            dimension: 48,
            child: CategoryPhoto(
              category: category,
              initialStyle: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(category.name)),
      ],
    );
  }
}
