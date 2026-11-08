import 'package:flutter/material.dart';

import '../../catalog/category.dart';
import '../../theme/brand_colors.dart';
import '../shared/account.dart';
import '../shared/diagonal_band.dart';
import 'category_photo.dart';

/// El encabezado del catálogo filtrado por una categoría: su nombre y su
/// descripción, y a la derecha la franja diagonal con su foto (o su color y
/// la inicial), como "Embutidos" en las maquetas.
class CategoryHeader extends StatelessWidget {
  const CategoryHeader({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AccountActions.wideFrom;
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            category.name,
                            style: text.headlineSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (category.description case final description?)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              description,
                              style: text.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                // La foto (o el color y la inicial), cortada en diagonal.
                child: ClipPath(
                  clipper: const DiagonalClipper(),
                  child: CategoryPhoto(
                    category: category,
                    initialStyle: text.displaySmall,
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
