import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/theme/brand_colors.dart';
import 'package:neils/theme/neils_theme.dart';
import 'package:neils/theme/palette.dart';

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

  group('paletas', () {
    const paletas = {'claro': NeilsPalette.light, 'oscuro': NeilsPalette.dark};

    void expectContrast(Color a, Color b, double atLeast, String nombre) =>
        expect(
          _contrast(a, b),
          greaterThanOrEqualTo(atLeast),
          reason: '$nombre: $a sobre $b',
        );

    test('los textos del claro y del oscuro pasan 4,5:1', () {
      for (final MapEntry(key: nombre, value: p) in paletas.entries) {
        for (final fondo in [p.background, p.surface, p.surfaceAlt]) {
          expectContrast(p.ink, fondo, 4.5, nombre);
          expectContrast(p.inkMuted, fondo, 4.5, nombre);
        }
        for (final fondo in [p.background, p.surface]) {
          expectContrast(p.brandText, fondo, 4.5, nombre);
        }
        expectContrast(p.onBrand, p.brandFill, 4.5, nombre);
        expectContrast(p.money, p.moneyTint, 4.5, nombre);
      }
    });

    test('cada estado pasa 3:1 sobre surface', () {
      for (final MapEntry(key: nombre, value: p) in paletas.entries) {
        for (final estado in [
          p.statusPending,
          p.statusConfirmed,
          p.statusPreparing,
          p.statusReady,
          p.statusOnTheWay,
          p.statusDelivered,
          p.statusCancelled,
          p.positive,
          p.caution,
        ]) {
          expectContrast(estado, p.surface, 3, nombre);
        }
      }
    });

    test('cada par de categoría pasa 4,5:1', () {
      for (final MapEntry(key: nombre, value: p) in paletas.entries) {
        for (final (fondo, letra) in p.placeholderPairs) {
          expectContrast(letra, fondo, 4.5, nombre);
        }
      }
    });

    test('sin lavanda', () {
      expect([
        for (final (fondo, _) in NeilsPalette.light.placeholderPairs) fondo,
      ], isNot(contains(const Color(0xFFE4DCF0))));
      expect(
        PlaceholderColors.pairs,
        isNot(contains((const Color(0xFFE4DCF0), const Color(0xFF533A7A)))),
      );
    });

    test('el oscuro es el de la spec', () {
      const p = NeilsPalette.dark;
      expect(p.background, const Color(0xFF171513));
      expect(p.surface, const Color(0xFF24201C));
      expect(p.brandFill, const Color(0xFFC8281E));
      expect(p.brandText, const Color(0xFFFF9A8F));
    });

    test('el claro es el de hoy', () {
      const p = NeilsPalette.light;
      expect(p.background, NeilsColors.background);
      expect(p.surface, NeilsColors.surface);
      expect(p.ink, NeilsColors.ink);
      expect(p.brandFill, NeilsColors.primary);
      expect(p.brandText, NeilsColors.primary);
      expect(p.brandTint, NeilsColors.primaryTint);
      expect(p.money, NeilsColors.money);
      expect(p.moneyTint, NeilsColors.moneyTint);
    });

    test('lerp va de una paleta a la otra sin saltos', () {
      final medio = NeilsPalette.light.lerp(NeilsPalette.dark, 0.5);
      expect(
        medio.background,
        Color.lerp(
          NeilsPalette.light.background,
          NeilsPalette.dark.background,
          0.5,
        ),
      );
      final (fondoClaro, _) = NeilsPalette.light.placeholderPairs.first;
      final (fondoOscuro, _) = NeilsPalette.dark.placeholderPairs.first;
      expect(
        medio.placeholderPairs.first.$1,
        Color.lerp(fondoClaro, fondoOscuro, 0.5),
      );
      expect(NeilsPalette.light.lerp(null, 0.5), same(NeilsPalette.light));
    });

    test('copyWith cambia solo lo pedido', () {
      final p = NeilsPalette.light.copyWith(
        background: const Color(0xFF000000),
      );
      expect(p.background, const Color(0xFF000000));
      expect(p.surface, NeilsPalette.light.surface);
      expect(p.placeholderPairs, NeilsPalette.light.placeholderPairs);
    });

    test('las dos paletas tienen la misma cantidad de pares', () {
      expect(
        NeilsPalette.dark.placeholderPairs,
        hasLength(NeilsPalette.light.placeholderPairs.length),
      );
    });

    test('placeholderFor da el mismo par que PlaceholderColors.of', () {
      for (final id in ['cat-embutidos', 'cat-lacteos', 'a', '']) {
        final i = PlaceholderColors.pairs.indexOf(PlaceholderColors.of(id));
        expect(
          NeilsPalette.dark.placeholderFor(id),
          NeilsPalette.dark.placeholderPairs[i],
        );
      }
    });
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
