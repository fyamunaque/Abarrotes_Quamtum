import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'brand_colors.dart';

/// El rojo de la marca alcanza el contraste de un texto sobre el fondo
/// (5,2:1) y con texto blanco encima (5,6:1): `primary` sirve para botones y
/// para enlaces. Lo seleccionado va en rojo muy claro con texto rojo oscuro.
const neilsColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: NeilsColors.primary,
  onPrimary: Colors.white,
  primaryContainer: NeilsColors.primaryTint,
  onPrimaryContainer: NeilsColors.primaryDark,
  secondary: NeilsColors.primaryDark,
  onSecondary: Colors.white,
  secondaryContainer: NeilsColors.primaryTint,
  onSecondaryContainer: NeilsColors.primaryDark,
  error: Color(0xFFBA1A1A),
  onError: Colors.white,
  // Sin estos, ColorScheme usa error/onError, y un campo con error bajo el
  // mouse pinta la etiqueta de blanco (onErrorContainer) sobre el fondo claro.
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF93000A),
  surface: NeilsColors.background,
  onSurface: NeilsColors.ink,
  // Neutros cálidos, entre la tinta y el hueso.
  onSurfaceVariant: Color(0xFF5E534D),
  outline: Color(0xFF8C7F77),
  outlineVariant: Color(0xFFE5DCD3),
  surfaceContainerLowest: NeilsColors.surface,
  surfaceContainerLow: Color(0xFFF7F1EA),
  surfaceContainer: Color(0xFFF3ECE4),
  surfaceContainerHigh: Color(0xFFEEE6DD),
  surfaceContainerHighest: Color(0xFFE8DFD5),
  inverseSurface: NeilsColors.ink,
  onInverseSurface: NeilsColors.background,
);

/// La sombra cálida y suave de las tarjetas, en lugar del borde.
const neilsCardShadow = Color(0x331F1A17);

/// Tema de la app. Como la web y Android, siempre la paleta clara de la marca
/// (fondo hueso), sin modo oscuro: la tienda se ve igual en todas partes.
ThemeData neilsTheme() {
  final textTheme = neilsTextTheme();
  const buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
  );
  const buttonSize = Size(64, 44);
  return ThemeData(
    colorScheme: neilsColorScheme,
    scaffoldBackgroundColor: NeilsColors.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: NeilsColors.background,
      foregroundColor: NeilsColors.ink,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: const CardThemeData(
      color: NeilsColors.surface,
      elevation: 1,
      shadowColor: neilsCardShadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: buttonShape,
        minimumSize: buttonSize,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: buttonShape,
        minimumSize: buttonSize,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: buttonShape,
        minimumSize: buttonSize,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      filled: true,
      fillColor: NeilsColors.surface,
    ),
    chipTheme: const ChipThemeData(
      shape: StadiumBorder(),
      selectedColor: NeilsColors.primaryTint,
    ),
  );
}

/// El tema del panel (/admin): la misma marca, más calmada. Fondo hueso,
/// texto en tinta, tarjetas blancas con sombra suave. Lo seleccionado
/// (navegación, filtros) va en rojo muy claro; el `primary` queda para lo
/// importante: la acción principal de cada pantalla y la línea del gráfico.
ThemeData neilsAdminTheme(ThemeData base) {
  final scheme = base.colorScheme;
  final text = base.textTheme;
  final muted = scheme.onSurfaceVariant;
  return base.copyWith(
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLowest,
      elevation: 1,
      shadowColor: neilsCardShadow,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: NeilsColors.background,
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
    // Como los chips: el segmento elegido en el tono claro, no en rojo.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: NeilsColors.ink,
        selectedBackgroundColor: NeilsColors.primaryTint,
        selectedForegroundColor: NeilsColors.ink,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: NeilsColors.background),
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
