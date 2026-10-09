import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'brand_colors.dart';

/// Material usa `primary` a la vez como fondo de botón y como color de texto
/// (TextButton, etiqueta del campo con foco). El naranja de marca sobre crema
/// da 3,0:1, así que `primary` es primaryDark (4,6:1 sobre crema; blanco
/// encima, 5,1:1). El naranja va en `secondaryContainer`, con texto tinta
/// (5,9:1): lo usan los botones tonales, como "Agregar".
const neilsColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: NeilsColors.primaryDark,
  onPrimary: Colors.white,
  primaryContainer: NeilsColors.primaryTint,
  onPrimaryContainer: NeilsColors.ink,
  secondary: NeilsColors.accent,
  onSecondary: NeilsColors.cream,
  secondaryContainer: NeilsColors.primary,
  onSecondaryContainer: NeilsColors.ink,
  error: Color(0xFFBA1A1A),
  onError: Colors.white,
  // Sin estos, ColorScheme usa error/onError, y un campo con error bajo el
  // mouse pinta la etiqueta de blanco (onErrorContainer) sobre el fondo claro.
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF93000A),
  surface: NeilsColors.cream,
  onSurface: NeilsColors.ink,
  // Neutros: tinta mezclada con crema (como ink/70, ink/50 e ink/15 en la web).
  onSurfaceVariant: Color(0xFF5F4D49),
  outline: Color(0xFF8B7C76),
  outlineVariant: Color(0xFFD8CFC5),
  surfaceContainerLowest: Color(0xFFFFFCF6),
  surfaceContainerLow: Color(0xFFF5EDDF),
  surfaceContainer: Color(0xFFF1E8D9),
  surfaceContainerHigh: Color(0xFFECE2D1),
  surfaceContainerHighest: Color(0xFFE7DCCA),
  inverseSurface: NeilsColors.ink,
  onInverseSurface: NeilsColors.cream,
);

/// Tema de la app. Como la web y Android, siempre la paleta clara de la marca
/// (fondo crema), sin modo oscuro: la tienda se ve igual en todas partes.
ThemeData neilsTheme() {
  final textTheme = neilsTextTheme();
  return ThemeData(
    colorScheme: neilsColorScheme,
    scaffoldBackgroundColor: NeilsColors.cream,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: NeilsColors.cream,
      foregroundColor: NeilsColors.ink,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: Color(0xFFFFFCF6),
    ),
  );
}

/// El tema del panel (/admin): la misma marca, más calmada. Crema de fondo,
/// texto en tinta, tarjetas claras con borde fino y sin sombra. Lo
/// seleccionado (navegación, filtros) va en naranja muy claro; el `primary`
/// queda para lo importante: el ítem activo, la acción principal de cada
/// pantalla y la línea del gráfico.
ThemeData neilsAdminTheme(ThemeData base) {
  final scheme = base.colorScheme;
  final text = base.textTheme;
  final muted = scheme.onSurfaceVariant;
  return base.copyWith(
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLowest,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: NeilsColors.cream,
      indicatorColor: NeilsColors.primaryTint,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: IconThemeData(color: muted),
      selectedLabelTextStyle: text.labelLarge?.copyWith(color: scheme.primary),
      unselectedLabelTextStyle: text.labelLarge?.copyWith(
        color: muted,
        fontWeight: FontWeight.w500,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: NeilsColors.primaryTint,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? scheme.primary : muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium?.copyWith(
          color: states.contains(WidgetState.selected) ? scheme.primary : muted,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: scheme.surfaceContainerLowest,
      selectedColor: NeilsColors.primaryTint,
      checkmarkColor: NeilsColors.ink,
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: text.labelLarge?.copyWith(color: NeilsColors.ink),
    ),
    // Como los chips: el segmento elegido en el tono claro, no en naranja.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: NeilsColors.ink,
        selectedBackgroundColor: NeilsColors.primaryTint,
        selectedForegroundColor: NeilsColors.ink,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: NeilsColors.cream),
  );
}

/// Baloo 2 (600/700/800) para títulos; Inter (400/500/600) para el resto.
TextTheme neilsTextTheme() {
  final base = Typography.material2021().black;
  TextStyle baloo(TextStyle? style, FontWeight weight) =>
      GoogleFonts.baloo2(textStyle: style, fontWeight: weight);
  TextStyle inter(TextStyle? style, FontWeight weight) =>
      GoogleFonts.inter(textStyle: style, fontWeight: weight);

  return TextTheme(
    displayLarge: baloo(base.displayLarge, FontWeight.w800),
    displayMedium: baloo(base.displayMedium, FontWeight.w800),
    displaySmall: baloo(base.displaySmall, FontWeight.w800),
    headlineLarge: baloo(base.headlineLarge, FontWeight.w700),
    headlineMedium: baloo(base.headlineMedium, FontWeight.w700),
    headlineSmall: baloo(base.headlineSmall, FontWeight.w700),
    titleLarge: baloo(base.titleLarge, FontWeight.w700),
    titleMedium: baloo(base.titleMedium, FontWeight.w600),
    titleSmall: baloo(base.titleSmall, FontWeight.w600),
    bodyLarge: inter(base.bodyLarge, FontWeight.w400),
    bodyMedium: inter(base.bodyMedium, FontWeight.w400),
    bodySmall: inter(base.bodySmall, FontWeight.w400),
    labelLarge: inter(base.labelLarge, FontWeight.w600),
    labelMedium: inter(base.labelMedium, FontWeight.w500),
    labelSmall: inter(base.labelSmall, FontWeight.w500),
  ).apply(bodyColor: NeilsColors.ink, displayColor: NeilsColors.ink);
}

/// Estilos de la marca que no son parte del TextTheme de Material.
abstract final class NeilsText {
  /// Precios: Baloo 2 ExtraBold en primaryDark, que sobre crema tiene buen
  /// contraste.
  static TextStyle price({double fontSize = 22}) => GoogleFonts.baloo2(
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    color: NeilsColors.primaryDark,
  );
}
