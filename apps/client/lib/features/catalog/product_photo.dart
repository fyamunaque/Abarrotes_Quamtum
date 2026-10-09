import 'package:flutter/material.dart';

/// La foto del producto, o una canasta sobre fondo neutro si no tiene o no
/// carga. Decorativa: el nombre ya dice qué es. Llena el espacio que le den.
class ProductPhoto extends StatelessWidget {
  const ProductPhoto(this.url, {super.key, this.iconSize = 40});

  final String? url;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainer,
      child: Center(
        child: Icon(
          Icons.shopping_basket_outlined,
          size: iconSize,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
    final url = this.url;
    return ExcludeSemantics(
      child: url == null
          ? placeholder
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}
