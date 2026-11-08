import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neils/theme/brand_colors.dart';

/// Lo que muestran el navegador y la app instalada desde la web
/// (web/manifest.json y web/index.html): el mensaje para negocios y los
/// colores de la marca.
void main() {
  final manifest = jsonDecode(
    File('web/manifest.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final index = File('web/index.html').readAsStringSync();

  String hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  test('la descripción habla a los negocios, igual en las dos', () {
    final description = manifest['description'] as String;
    expect(description, startsWith('Insumos gastronómicos para tu negocio'));
    expect(index, contains('<meta name="description" content="$description">'));
  });

  test('los colores son los de la marca', () {
    expect(manifest['theme_color'], hex(NeilsColors.primary.toARGB32()));
    expect(
      manifest['background_color'],
      hex(NeilsColors.background.toARGB32()),
    );
  });
}
