import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../theme/brand_colors.dart';

/// La foto del producto. Sin foto (o mientras carga, o si no carga), un
/// marcador con la inicial de [name] sobre el color de su categoría
/// ([colorKey], p. ej. su id). Decorativa: el nombre ya dice qué es. Llena el
/// espacio que le den.
///
/// Una foto subida al servidor llega como ruta relativa
/// (`/images/products/…`) y se completa con [apiBaseUrl]; una URL externa
/// queda igual.
class ProductPhoto extends StatelessWidget {
  const ProductPhoto(
    this.url, {
    super.key,
    required this.name,
    this.colorKey,
    this.initialSize = 40,
  });

  final String? url;
  final String name;

  /// Lo que decide el color del marcador; si no hay, el nombre.
  final String? colorKey;

  /// El tamaño de la inicial del marcador.
  final double initialSize;

  /// La URL para pedir la foto: [url] completa con [apiBaseUrl] si es
  /// relativa.
  static Uri? resolve(String? url) =>
      url == null || url.isEmpty ? null : apiBaseUrl.resolve(url);

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(
      name: name,
      colorKey: colorKey ?? name,
      size: initialSize,
    );
    final source = resolve(url);
    final fade = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return ExcludeSemantics(
      child: source == null
          ? placeholder
          : Image.network(
              source.toString(),
              fit: BoxFit.cover,
              // Mientras carga, el marcador; la foto entra con un fundido.
              frameBuilder: (_, child, frame, wasSynchronouslyLoaded) =>
                  wasSynchronouslyLoaded
                  ? child
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        placeholder,
                        AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: fade,
                          child: child,
                        ),
                      ],
                    ),
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}

/// La inicial del producto sobre un fondo del color de su categoría.
class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.name,
    required this.colorKey,
    required this.size,
  });

  final String name;
  final String colorKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = PlaceholderColors.of(colorKey);
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
    return ColoredBox(
      color: background,
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontSize: size,
            height: 1,
            fontWeight: FontWeight.w800,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
