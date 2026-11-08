import 'package:flutter/material.dart';

import 'brand_colors.dart';

/// Los colores de la app por su rol, en una versión clara y otra oscura. Las
/// pantallas los leen del tema ([NeilsPaletteContext.palette]) y nunca usan
/// un color suelto: así el modo oscuro cambia todo de una vez.
@immutable
class NeilsPalette extends ThemeExtension<NeilsPalette> {
  const NeilsPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.line,
    required this.ink,
    required this.inkMuted,
    required this.brandFill,
    required this.brandFillDeep,
    required this.onBrand,
    required this.brandText,
    required this.brandTint,
    required this.onBrandDivider,
    required this.money,
    required this.moneyTint,
    required this.statusPending,
    required this.statusConfirmed,
    required this.statusPreparing,
    required this.statusReady,
    required this.statusOnTheWay,
    required this.statusDelivered,
    required this.statusCancelled,
    required this.positive,
    required this.caution,
    required this.scrim,
    required this.placeholderPairs,
  });

  /// El fondo de las pantallas.
  final Color background;

  /// Tarjetas, filas y campos.
  final Color surface;

  /// Paneles y bloques informativos, un paso más oscuro que [background].
  final Color surfaceAlt;

  /// Bordes finos y separadores.
  final Color line;

  /// El texto.
  final Color ink;

  /// El texto secundario (4,5:1 sobre los fondos).
  final Color inkMuted;

  /// El rojo de los botones y las barras, con [onBrand] encima.
  final Color brandFill;
  final Color onBrand;

  /// Un rojo más hondo, para el fondo de una franja junto a [brandFill]
  /// (la de promociones), con [onBrand] encima.
  final Color brandFillDeep;

  /// El rojo de los textos, enlaces y precios en oferta: en oscuro, más claro
  /// que [brandFill], que sobre el carbón no llega al contraste de un texto.
  final Color brandText;

  /// El fondo de lo seleccionado (menú, pestañas del panel).
  final Color brandTint;

  /// Las rayas divisorias sobre [brandFill].
  final Color onBrandDivider;

  /// El total de una línea: [money] sobre [moneyTint].
  final Color money;
  final Color moneyTint;

  /// Los estados de un pedido, para puntos y líneas (3:1 sobre [surface]);
  /// el estado va siempre también en texto.
  final Color statusPending;
  final Color statusConfirmed;
  final Color statusPreparing;
  final Color statusReady;
  final Color statusOnTheWay;
  final Color statusDelivered;
  final Color statusCancelled;

  /// Algo vigente o que está bien ("Activo").
  final Color positive;

  /// Algo aceptable que podría estar mejor (una contraseña de seguridad media).
  final Color caution;

  /// El velo detrás de un menú o un diálogo.
  final Color scrim;

  /// Los pares (fondo, letra) del marcador de una categoría o un producto
  /// sin foto. La misma cantidad en las dos paletas: [placeholderFor] elige
  /// por posición.
  final List<(Color, Color)> placeholderPairs;

  /// El par de [key] (p. ej. el id de la categoría): el mismo lugar que
  /// [PlaceholderColors.of], así cada categoría conserva su tono en los dos
  /// modos.
  (Color, Color) placeholderFor(String key) {
    var hash = 7;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) % 2147483647;
    }
    return placeholderPairs[hash % placeholderPairs.length];
  }

  /// Los colores de hoy: el fondo hueso y el rojo del logo.
  static const light = NeilsPalette(
    background: NeilsColors.background,
    surface: NeilsColors.surface,
    surfaceAlt: Color(0xFFF3ECE4),
    line: Color(0xFFE5DCD3),
    ink: NeilsColors.ink,
    inkMuted: Color(0xFF5E534D),
    brandFill: NeilsColors.primary,
    brandFillDeep: NeilsColors.primaryDark,
    onBrand: NeilsColors.onPrimary,
    brandText: NeilsColors.primary,
    brandTint: NeilsColors.primaryTint,
    onBrandDivider: NeilsColors.onPrimaryDivider,
    money: NeilsColors.money,
    moneyTint: NeilsColors.moneyTint,
    statusPending: OrderStatusColors.pending,
    statusConfirmed: OrderStatusColors.confirmed,
    statusPreparing: OrderStatusColors.preparing,
    statusReady: OrderStatusColors.readyForPickup,
    statusOnTheWay: OrderStatusColors.onTheWay,
    statusDelivered: OrderStatusColors.delivered,
    statusCancelled: OrderStatusColors.cancelled,
    positive: StateColors.positive,
    caution: StateColors.caution,
    scrim: Color(0x731F1A17),
    placeholderPairs: PlaceholderColors.pairs,
  );

  /// Carbón cálido, no negro: la marca en oscuro.
  static const dark = NeilsPalette(
    background: Color(0xFF171513),
    surface: Color(0xFF24201C),
    surfaceAlt: Color(0xFF302A25),
    line: Color(0xFF3A322C),
    ink: Color(0xFFF4EEE7),
    inkMuted: Color(0xFFB9ADA3),
    brandFill: NeilsColors.primary,
    brandFillDeep: NeilsColors.primaryDark,
    onBrand: NeilsColors.onPrimary,
    brandText: Color(0xFFFF9A8F),
    brandTint: Color(0xFF4A1E1A),
    onBrandDivider: NeilsColors.onPrimaryDivider,
    money: Color(0xFFA9E2B8),
    moneyTint: Color(0xFF183B28),
    statusPending: Color(0xFFE3B261),
    statusConfirmed: Color(0xFFA9B1F0),
    statusPreparing: Color(0xFFC6A8E8),
    statusReady: Color(0xFF7FD3C8),
    statusOnTheWay: Color(0xFF8CBDE6),
    statusDelivered: Color(0xFF8FD1AE),
    statusCancelled: Color(0xFFF0A49B),
    positive: Color(0xFF8FD1AE),
    caution: Color(0xFFE3B261),
    scrim: Color(0x8C000000),
    placeholderPairs: [
      (Color(0xFF4A2E22), Color(0xFFF5C7A8)), // durazno
      (Color(0xFF2F3A28), Color(0xFFC9DDB8)), // salvia
      (Color(0xFF22323F), Color(0xFFB9D4EA)), // cielo
      (Color(0xFF45302A), Color(0xFFEBC6B0)), // arcilla
      (Color(0xFF3F3618), Color(0xFFEEDB9A)), // mantequilla
      (Color(0xFF46282D), Color(0xFFF2BCC5)), // rosa
      (Color(0xFF213A35), Color(0xFFB3E0D5)), // menta
      (Color(0xFF3B3129), Color(0xFFE3CFBC)), // arena
    ],
  );

  @override
  NeilsPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? line,
    Color? ink,
    Color? inkMuted,
    Color? brandFill,
    Color? brandFillDeep,
    Color? onBrand,
    Color? brandText,
    Color? brandTint,
    Color? onBrandDivider,
    Color? money,
    Color? moneyTint,
    Color? statusPending,
    Color? statusConfirmed,
    Color? statusPreparing,
    Color? statusReady,
    Color? statusOnTheWay,
    Color? statusDelivered,
    Color? statusCancelled,
    Color? positive,
    Color? caution,
    Color? scrim,
    List<(Color, Color)>? placeholderPairs,
  }) => NeilsPalette(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    line: line ?? this.line,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    brandFill: brandFill ?? this.brandFill,
    brandFillDeep: brandFillDeep ?? this.brandFillDeep,
    onBrand: onBrand ?? this.onBrand,
    brandText: brandText ?? this.brandText,
    brandTint: brandTint ?? this.brandTint,
    onBrandDivider: onBrandDivider ?? this.onBrandDivider,
    money: money ?? this.money,
    moneyTint: moneyTint ?? this.moneyTint,
    statusPending: statusPending ?? this.statusPending,
    statusConfirmed: statusConfirmed ?? this.statusConfirmed,
    statusPreparing: statusPreparing ?? this.statusPreparing,
    statusReady: statusReady ?? this.statusReady,
    statusOnTheWay: statusOnTheWay ?? this.statusOnTheWay,
    statusDelivered: statusDelivered ?? this.statusDelivered,
    statusCancelled: statusCancelled ?? this.statusCancelled,
    positive: positive ?? this.positive,
    caution: caution ?? this.caution,
    scrim: scrim ?? this.scrim,
    placeholderPairs: placeholderPairs ?? this.placeholderPairs,
  );

  /// Color a color, para la transición de [MaterialApp] al cambiar de modo.
  /// Los pares van por posición (las dos paletas tienen la misma cantidad).
  @override
  NeilsPalette lerp(covariant ThemeExtension<NeilsPalette>? other, double t) {
    if (other is! NeilsPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return NeilsPalette(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      line: mix(line, other.line),
      ink: mix(ink, other.ink),
      inkMuted: mix(inkMuted, other.inkMuted),
      brandFill: mix(brandFill, other.brandFill),
      brandFillDeep: mix(brandFillDeep, other.brandFillDeep),
      onBrand: mix(onBrand, other.onBrand),
      brandText: mix(brandText, other.brandText),
      brandTint: mix(brandTint, other.brandTint),
      onBrandDivider: mix(onBrandDivider, other.onBrandDivider),
      money: mix(money, other.money),
      moneyTint: mix(moneyTint, other.moneyTint),
      statusPending: mix(statusPending, other.statusPending),
      statusConfirmed: mix(statusConfirmed, other.statusConfirmed),
      statusPreparing: mix(statusPreparing, other.statusPreparing),
      statusReady: mix(statusReady, other.statusReady),
      statusOnTheWay: mix(statusOnTheWay, other.statusOnTheWay),
      statusDelivered: mix(statusDelivered, other.statusDelivered),
      statusCancelled: mix(statusCancelled, other.statusCancelled),
      positive: mix(positive, other.positive),
      caution: mix(caution, other.caution),
      scrim: mix(scrim, other.scrim),
      placeholderPairs: [
        for (var i = 0; i < placeholderPairs.length; i++)
          if (i < other.placeholderPairs.length)
            (
              mix(placeholderPairs[i].$1, other.placeholderPairs[i].$1),
              mix(placeholderPairs[i].$2, other.placeholderPairs[i].$2),
            )
          else
            placeholderPairs[i],
      ],
    );
  }
}

/// La paleta del tema de [BuildContext]; sin ella (un widget probado sin el
/// tema de la app), la clara.
extension NeilsPaletteContext on BuildContext {
  NeilsPalette get palette =>
      Theme.of(this).extension<NeilsPalette>() ?? NeilsPalette.light;
}
