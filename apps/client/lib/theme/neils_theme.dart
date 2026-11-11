import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'brand_colors.dart';
import 'palette.dart';

/// El rojo de la marca alcanza el contraste de un texto sobre el fondo
/// (5,2:1) y con texto blanco encima (5,6:1): `primary` sirve para botones y
/// para enlaces. Lo seleccionado va en rojo muy claro con texto rojo oscuro.
const neilsColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: NeilsColors.primary,
  onPrimary: NeilsColors.onPrimary,
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

/// El esquema oscuro: carbón cálido. El `primary` es el rojo claro de los
/// textos ([NeilsPalette.brandText]); los botones rellenos fijan su fondo en
/// el rojo del logo (ver [neilsTheme]).
const neilsDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFFF9A8F),
  onPrimary: Color(0xFF3B0B07),
  primaryContainer: Color(0xFF4A1E1A),
  onPrimaryContainer: Color(0xFFFFD9D4),
  secondary: Color(0xFFFF9A8F),
  onSecondary: Color(0xFF3B0B07),
  secondaryContainer: Color(0xFF4A1E1A),
  onSecondaryContainer: Color(0xFFFFD9D4),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF171513),
  onSurface: Color(0xFFF4EEE7),
  onSurfaceVariant: Color(0xFFB9ADA3),
  outline: Color(0xFF8E8177),
  outlineVariant: Color(0xFF3A322C),
  surfaceContainerLowest: Color(0xFF24201C),
  surfaceContainerLow: Color(0xFF2A2420),
  surfaceContainer: Color(0xFF302A25),
  surfaceContainerHigh: Color(0xFF362F29),
  surfaceContainerHighest: Color(0xFF3D352F),
  inverseSurface: Color(0xFFF4EEE7),
  onInverseSurface: Color(0xFF171513),
);

/// La sombra cálida y suave de las tarjetas, en lugar del borde.
const neilsCardShadow = Color(0x331F1A17);

/// La sombra de las tarjetas en oscuro: negra, porque sobre el carbón la
/// cálida no se ve.
const _darkCardShadow = Color(0x66000000);

/// Tema de la app, claro u oscuro según [brightness]. Lleva la paleta de ese
/// modo como extensión ([NeilsPalette]): las pantallas toman de ahí sus
/// colores. En los dos, los botones rellenos van en el rojo del logo con
/// texto blanco.
ThemeData neilsTheme([Brightness brightness = Brightness.light]) {
  final dark = brightness == Brightness.dark;
  final palette = dark ? NeilsPalette.dark : NeilsPalette.light;
  final textTheme = neilsTextTheme(palette.ink);
  const buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
  );
  const buttonSize = Size(64, 44);
  return ThemeData(
    colorScheme: dark ? neilsDarkColorScheme : neilsColorScheme,
    extensions: [palette],
    scaffoldBackgroundColor: palette.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.ink,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 1,
      shadowColor: dark ? _darkCardShadow : neilsCardShadow,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.brandFill,
        foregroundColor: palette.onBrand,
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
      style: TextButton.styleFrom(shape: buttonShape, minimumSize: buttonSize),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      filled: true,
      fillColor: palette.surface,
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      selectedColor: palette.brandTint,
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
  final palette = base.extension<NeilsPalette>() ?? NeilsPalette.light;
  final shadow = base.brightness == Brightness.dark
      ? _darkCardShadow
      : neilsCardShadow;
  // Lo elegido (navegación): el texto sobre el tono claro, que en oscuro es
  // el rosado claro del esquema.
  final selected = scheme.onPrimaryContainer;
  return base.copyWith(
    // La barra, blanca y con una sombra fina abajo.
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: scheme.surfaceContainerLowest,
      elevation: 1,
      scrolledUnderElevation: 1,
      shadowColor: shadow,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLowest,
      elevation: 1,
      shadowColor: shadow,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.background,
      indicatorColor: palette.brandTint,
      selectedIconTheme: IconThemeData(color: selected),
      unselectedIconTheme: IconThemeData(color: muted),
      selectedLabelTextStyle: text.labelLarge?.copyWith(color: selected),
      unselectedLabelTextStyle: text.labelLarge?.copyWith(
        color: muted,
        fontWeight: FontWeight.w500,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: palette.brandTint,
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
      selectedColor: palette.brandTint,
      checkmarkColor: palette.ink,
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: text.labelLarge?.copyWith(color: palette.ink),
    ),
    // Como los chips: el segmento elegido en el tono claro, no en rojo.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: palette.ink,
        selectedBackgroundColor: palette.brandTint,
        selectedForegroundColor: palette.ink,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: palette.background),
  );
}

/// Poppins (600/700/800) para títulos y botones; Inter (400/500) para el
/// resto, que en textos largos y tablas se lee mejor.
TextTheme neilsTextTheme([Color ink = NeilsColors.ink]) {
  final base = Typography.material2021().black;
  TextStyle poppins(TextStyle? style, FontWeight weight) =>
      GoogleFonts.poppins(textStyle: style, fontWeight: weight);
  TextStyle inter(TextStyle? style, FontWeight weight) =>
      GoogleFonts.inter(textStyle: style, fontWeight: weight);

  return TextTheme(
    displayLarge: poppins(base.displayLarge, FontWeight.w800),
    displayMedium: poppins(base.displayMedium, FontWeight.w800),
    displaySmall: poppins(base.displaySmall, FontWeight.w800),
    headlineLarge: poppins(base.headlineLarge, FontWeight.w700),
    headlineMedium: poppins(base.headlineMedium, FontWeight.w700),
    headlineSmall: poppins(base.headlineSmall, FontWeight.w700),
    titleLarge: poppins(base.titleLarge, FontWeight.w700),
    titleMedium: poppins(base.titleMedium, FontWeight.w600),
    titleSmall: poppins(base.titleSmall, FontWeight.w600),
    bodyLarge: inter(base.bodyLarge, FontWeight.w400),
    bodyMedium: inter(base.bodyMedium, FontWeight.w400),
    bodySmall: inter(base.bodySmall, FontWeight.w400),
    labelLarge: poppins(base.labelLarge, FontWeight.w600),
    labelMedium: inter(base.labelMedium, FontWeight.w500),
    labelSmall: inter(base.labelSmall, FontWeight.w500),
  ).apply(bodyColor: ink, displayColor: ink);
}

/// Estilos de la marca que no son parte del TextTheme de Material.
abstract final class NeilsText {
  /// Precios: Poppins Bold. Sin [color], el del texto del tema (tinta en
  /// claro, crema en oscuro). Un precio en oferta va en el rojo de los textos
  /// de la paleta.
  static TextStyle price({double fontSize = 22, Color? color}) =>
      GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
      );
}
