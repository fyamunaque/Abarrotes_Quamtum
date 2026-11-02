import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../catalog/catalog_providers.dart';

/// El filtro por categoría de una tabla del panel: "Todas" o una.
class CategoryFilter extends ConsumerWidget {
  const CategoryFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    return DropdownButtonFormField<String?>(
      style: Theme.of(context).textTheme.bodyLarge,
      // Recién al cargar las categorías se puede mostrar la elegida.
      key: ValueKey(categories.length),
      initialValue: categories.any((c) => c.id == value) ? value : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Categoría'),
      items: [
        const DropdownMenuItem(child: Text('Todas')),
        for (final category in categories)
          DropdownMenuItem(value: category.id, child: Text(category.name)),
      ],
      onChanged: onChanged,
    );
  }
}
