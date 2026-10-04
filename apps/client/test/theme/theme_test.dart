import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/theme/brand_colors.dart';
import 'package:neils/theme/neils_theme.dart';

import '../support.dart';

void main() {
  useBundledFonts();

  test('los tokens de marca son los de Neil\'s', () {
    expect(NeilsColors.primary, const Color(0xFFE8652F));
    expect(NeilsColors.primaryDark, const Color(0xFFB54F25));
    expect(NeilsColors.accent, const Color(0xFFA1241B));
    expect(NeilsColors.cream, const Color(0xFFF9F3E7));
    expect(NeilsColors.ink, const Color(0xFF1D0605));
  });

  test('el ColorScheme prioriza el contraste sobre crema', () {
    final scheme = neilsTheme().colorScheme;

    expect(scheme.primary, NeilsColors.primaryDark);
    expect(scheme.secondaryContainer, NeilsColors.primary);
    expect(scheme.onSecondaryContainer, NeilsColors.ink);
    expect(scheme.secondary, NeilsColors.accent);
    expect(scheme.surface, NeilsColors.cream);
    expect(scheme.onSurface, NeilsColors.ink);
  });

  test('el texto de error se lee sobre el fondo de los campos', () {
    final scheme = neilsTheme().colorScheme;
    // Un campo con error bajo el mouse pinta la etiqueta con onErrorContainer.
    // Sin definirlo, ColorScheme usa onError (blanco).
    for (final color in [scheme.error, scheme.onErrorContainer]) {
      expect(
        _contrast(color, scheme.surfaceContainerLowest),
        greaterThanOrEqualTo(4.5),
        reason: '$color',
      );
    }
  });

  test('Baloo 2 para títulos y precios; Inter para el resto', () {
    final text = neilsTheme().textTheme;
    void expectFont(TextStyle? style, String family, FontWeight weight) {
      expect(style?.fontFamily, startsWith(family));
      expect(style?.fontWeight, weight);
    }

    expectFont(text.displayLarge, 'Baloo2', FontWeight.w800);
    expectFont(text.headlineMedium, 'Baloo2', FontWeight.w700);
    expectFont(text.titleLarge, 'Baloo2', FontWeight.w700);
    expectFont(text.titleSmall, 'Baloo2', FontWeight.w600);
    expectFont(text.bodyLarge, 'Inter', FontWeight.w400);
    expectFont(text.labelMedium, 'Inter', FontWeight.w500);
    expectFont(text.labelLarge, 'Inter', FontWeight.w600);
    expectFont(NeilsText.price(), 'Baloo2', FontWeight.w800);
    expect(NeilsText.price().color, NeilsColors.primaryDark);
    expect(text.bodyLarge?.color, NeilsColors.ink);
  });
}

/// Contraste WCAG entre dos colores (de 1 a 21).
double _contrast(Color a, Color b) {
  final (lighter, darker) = a.computeLuminance() > b.computeLuminance()
      ? (a, b)
      : (b, a);
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
