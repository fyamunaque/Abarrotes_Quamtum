import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/theme/brand_colors.dart';
import 'package:neils/theme/neils_theme.dart';

import '../support.dart';

void main() {
  useBundledFonts();

  test('los tokens de marca son los de la nueva marca', () {
    expect(NeilsColors.primary, const Color(0xFFC8281E));
    expect(NeilsColors.primaryDark, const Color(0xFF9E1B14));
    expect(NeilsColors.primaryTint, const Color(0xFFFBE3E0));
    expect(NeilsColors.background, const Color(0xFFFBF7F2));
    expect(NeilsColors.surface, const Color(0xFFFFFFFF));
    expect(NeilsColors.ink, const Color(0xFF1F1A17));
    expect(NeilsColors.money, const Color(0xFF276B43));
    expect(NeilsColors.moneyTint, const Color(0xFFE3F2E7));
  });

  test('el rojo sirve para botones y para texto', () {
    final scheme = neilsTheme().colorScheme;
    void expectContrast(Color a, Color b, double atLeast) => expect(
      _contrast(a, b),
      greaterThanOrEqualTo(atLeast),
      reason: '$a sobre $b',
    );

    expectContrast(NeilsColors.onPrimary, NeilsColors.primary, 5.5);
    expectContrast(NeilsColors.primary, NeilsColors.background, 5.0);
    expectContrast(NeilsColors.primaryDark, NeilsColors.primaryTint, 6.5);
    expectContrast(NeilsColors.money, NeilsColors.moneyTint, 5.5);
    expectContrast(NeilsColors.ink, NeilsColors.background, 16);
    expectContrast(scheme.onSurfaceVariant, Colors.white, 4.5);
  });

  test('el ColorScheme usa el rojo como primary', () {
    final scheme = neilsTheme().colorScheme;

    expect(scheme.primary, NeilsColors.primary);
    expect(scheme.onPrimary, Colors.white);
    expect(scheme.primaryContainer, NeilsColors.primaryTint);
    expect(scheme.onPrimaryContainer, NeilsColors.primaryDark);
    expect(scheme.surface, NeilsColors.background);
    expect(scheme.onSurface, NeilsColors.ink);
    expect(scheme.surfaceContainerLowest, Colors.white);
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

  test('Confirmado en índigo, aparte de Entregado y de En camino', () {
    final scheme = neilsTheme().colorScheme;
    expect(OrderStatusColors.confirmed, const Color(0xFF4F5BB5));
    expect(OrderStatusColors.confirmed, isNot(OrderStatusColors.delivered));
    expect(OrderStatusColors.confirmed, isNot(OrderStatusColors.onTheWay));
    // Un punto de color: al menos 3:1 sobre el fondo de las tarjetas.
    expect(
      _contrast(OrderStatusColors.confirmed, scheme.surfaceContainerLowest),
      greaterThanOrEqualTo(3),
    );
    // "Activo" y lo que está vigente siguen en el verde de siempre.
    expect(StateColors.positive, OrderStatusColors.delivered);
    // La seguridad media de una contraseña: una barra, al menos 3:1.
    expect(
      _contrast(StateColors.caution, scheme.surfaceContainerLowest),
      greaterThanOrEqualTo(3),
    );
  });

  test('la inicial del marcador sin foto se lee sobre su fondo', () {
    for (final (background, foreground) in PlaceholderColors.pairs) {
      expect(
        _contrast(foreground, background),
        greaterThanOrEqualTo(4.5),
        reason: '$foreground sobre $background',
      );
    }
  });

  test('los títulos van en Poppins y el texto en Inter', () {
    final text = neilsTheme().textTheme;
    void expectFont(TextStyle? style, String family, FontWeight weight) {
      expect(style?.fontFamily, startsWith(family));
      expect(style?.fontWeight, weight);
    }

    expectFont(text.displayLarge, 'Poppins', FontWeight.w800);
    expectFont(text.headlineMedium, 'Poppins', FontWeight.w700);
    expectFont(text.titleLarge, 'Poppins', FontWeight.w700);
    expectFont(text.titleSmall, 'Poppins', FontWeight.w600);
    expectFont(text.labelLarge, 'Poppins', FontWeight.w600);
    expectFont(text.bodyLarge, 'Inter', FontWeight.w400);
    expectFont(text.bodyMedium, 'Inter', FontWeight.w400);
    expectFont(text.labelMedium, 'Inter', FontWeight.w500);
    expectFont(NeilsText.price(), 'Poppins', FontWeight.w700);
    expect(NeilsText.price().color, NeilsColors.ink);
    expect(
      NeilsText.price(color: NeilsColors.primary).color,
      NeilsColors.primary,
    );
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
