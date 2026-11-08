import 'package:flutter/material.dart';

import '../../catalog/category.dart';
import '../../theme/brand_colors.dart';
import '../shared/account.dart';
import '../shared/diagonal_band.dart';
import 'category_photo.dart';

/// El encabezado del catálogo filtrado por una categoría: su nombre y su
/// descripción, y a la derecha la franja diagonal con su foto (o su color y
/// la inicial), como "Embutidos" en las maquetas.
///
/// Mide al menos 120 de alto en el teléfono y 160 en escritorio, y crece si
/// el texto (agrandado) no entra; la foto acompaña ese alto.
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // La foto, el 40 % de la derecha.
            final photoWidth = constraints.maxWidth * 0.4;
            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: wide ? 160 : 120),
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  PositionedDirectional(
                    top: 0,
                    bottom: 0,
                    end: 0,
                    width: photoWidth,
                    // La foto (o el color y la inicial), cortada en diagonal.
                    child: ClipPath(
                      clipper: const DiagonalClipper(),
                      child: CategoryPhoto(
                        category: category,
                        initialStyle: text.displaySmall,
                      ),
                    ),
                  ),
                  // El texto decide el alto, si pasa del mínimo.
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: 20,
                      end: photoWidth + 20,
                      top: 16,
                      bottom: 16,
                    ),
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
