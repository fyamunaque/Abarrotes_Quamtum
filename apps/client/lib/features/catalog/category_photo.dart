import 'package:flutter/material.dart';

import '../../catalog/category.dart';
import 'product_photo.dart';
import '../../theme/palette.dart';

/// La foto de una categoría, cubriendo su lugar. Sin foto, o si no carga, el
/// bloque del color de la categoría ([colors], o el de
/// [NeilsPalette.placeholderFor]): en la tienda, sin letra (el nombre va al
/// lado); en el panel, con su inicial ([showInitial]).
class CategoryPhoto extends StatelessWidget {
  const CategoryPhoto({
    super.key,
    required this.category,
    this.colors,
    this.showInitial = false,
    this.initialStyle,
  });

  final Category category;
  final (Color background, Color foreground)? colors;

  /// Si el bloque de color lleva la inicial (las miniaturas del panel).
  final bool showInitial;

  /// El estilo de la inicial; sin él, `headlineLarge`.
  final TextStyle? initialStyle;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) =
        colors ?? context.palette.placeholderFor(category.id);
    final placeholder = ColoredBox(
      color: background,
      child: !showInitial
          ? const SizedBox.expand()
          : Center(
              child: ExcludeSemantics(
                child: Text(
                  category.name.isEmpty
                      ? '?'
                      : category.name.characters.first.toUpperCase(),
                  style:
                      (initialStyle ??
                              Theme.of(context).textTheme.headlineLarge)
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
