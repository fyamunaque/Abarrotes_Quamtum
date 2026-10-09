import 'package:flutter/widgets.dart';

/// Grilla de tarjetas: columnas de al menos 200 px (entre 2 y 4), todas del
/// mismo ancho. Va dentro del scroll de la pantalla.
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.children});

  final List<Widget> children;

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 200).floor().clamp(2, 4);
        final width = (constraints.maxWidth - _gap * (columns - 1)) / columns;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
