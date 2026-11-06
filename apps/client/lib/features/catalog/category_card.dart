import 'package:flutter/material.dart';

import '../../catalog/category.dart';
import '../../theme/brand_colors.dart';

/// Una categoría en una tarjeta: arriba un bloque de su color con la
/// inicial, abajo el nombre y una flecha. [colors] es el par fondo/letra; sin
/// él, el de la categoría ([PlaceholderColors.of]). La portada los pasa en
/// orden, así dos vecinas no se repiten.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.colors,
  });

  final Category category;
  final VoidCallback onTap;
  final (Color background, Color foreground)? colors;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) =
        colors ?? PlaceholderColors.of(category.id);
    final text = Theme.of(context).textTheme;
    final initial = category.name.isEmpty
        ? '?'
        : category.name.characters.first.toUpperCase();
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: background,
                child: Center(
                  child: ExcludeSemantics(
                    child: Text(
                      initial,
                      style: text.headlineLarge?.copyWith(color: foreground),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      style: text.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: NeilsColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
