import 'package:flutter/material.dart';

import '../../catalog/category.dart';
import '../../theme/brand_colors.dart';
import '../shared/account.dart';
import '../shared/diagonal_band.dart';

/// El encabezado del catálogo filtrado por una categoría: su nombre y, a la
/// derecha, la franja diagonal con su color, como "Embutidos" en las
/// maquetas.
class CategoryHeader extends StatelessWidget {
  const CategoryHeader({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AccountActions.wideFrom;
    final (background, foreground) = PlaceholderColors.of(category.id);
    final text = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: NeilsColors.surface,
        child: SizedBox(
          height: wide ? 160 : 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Semantics(
                      header: true,
                      child: Text(
                        category.name,
                        style: text.headlineSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: DiagonalBand(
                  color: background,
                  child: ExcludeSemantics(
                    child: Text(
                      category.name.isEmpty
                          ? ''
                          : category.name.characters.first.toUpperCase(),
                      style: text.displaySmall?.copyWith(color: foreground),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
