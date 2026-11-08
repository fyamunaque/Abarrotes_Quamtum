import 'package:flutter/material.dart';

import '../../catalog/category.dart';
import '../../theme/brand_colors.dart';
import 'product_photo.dart';

/// La foto de una categoría, cubriendo su lugar. Sin foto, o si no carga, el
/// color de la categoría con su inicial ([colors], o el de
/// [PlaceholderColors.of]).
class CategoryPhoto extends StatelessWidget {
  const CategoryPhoto({
    super.key,
    required this.category,
    this.colors,
    this.initialStyle,
  });

  final Category category;
  final (Color background, Color foreground)? colors;

  /// El estilo de la inicial; sin él, `headlineLarge`.
  final TextStyle? initialStyle;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) =
        colors ?? PlaceholderColors.of(category.id);
    final placeholder = ColoredBox(
      color: background,
      child: Center(
        child: ExcludeSemantics(
          child: Text(
            category.name.isEmpty
                ? '?'
                : category.name.characters.first.toUpperCase(),
            style: (initialStyle ?? Theme.of(context).textTheme.headlineLarge)
                ?.copyWith(color: foreground),
          ),
        ),
      ),
    );
    final url = ProductPhoto.resolve(category.imageUrl);
    if (url == null) return placeholder;
    return Image.network(
      url.toString(),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // Decorativa: el nombre ya está al lado.
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => placeholder,
      frameBuilder: (_, child, frame, loaded) =>
          loaded || frame != null ? child : placeholder,
    );
  }
}
