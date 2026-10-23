import 'package:flutter/painting.dart';

/// Tokens de marca de Neil's Food Services.
abstract final class NeilsColors {
  static const primary = Color(0xFFE8652F);
  static const primaryDark = Color(0xFFB54F25);
  static const accent = Color(0xFFA1241B);
  static const cream = Color(0xFFF9F3E7);
  static const ink = Color(0xFF1D0605);

  /// Naranja muy claro, para fondos de contenedores y chips.
  static const primaryTint = Color(0xFFF6D9C6);
}

/// Colores de los estados de pedido (seguimiento, chips). Son para gráficos:
/// puntos y líneas. El estado también va siempre en texto, en tinta: el ámbar
/// de pendiente sobre crema no alcanza el contraste de un texto.
abstract final class OrderStatusColors {
  static const pending = Color(0xFFD98C21);
  static const confirmed = Color(0xFF3C7A5F);
  static const onTheWay = Color(0xFF2E6F9E);

  /// Recojo en tienda: preparando, y en espera de recojo.
  static const preparing = Color(0xFF7A5A9E);
  static const readyForPickup = Color(0xFF2A8C82);
  static const delivered = Color(0xFF3C7A5F);

  /// Este sí sirve para texto sobre crema (6,8:1).
  static const cancelled = Color(0xFF8C3B33);
}

/// El marcador de un producto sin foto: un fondo suave y la inicial en un
/// tono oscuro del mismo color (contraste de al menos 4.5:1). Cada categoría
/// tiene siempre el mismo par, así el catálogo no se ve repetido.
abstract final class PlaceholderColors {
  static const pairs = <(Color background, Color foreground)>[
    (Color(0xFFF8DCC8), Color(0xFF8A3A12)), // durazno
    (Color(0xFFDCE8D2), Color(0xFF3E5A2A)), // salvia
    (Color(0xFFD6E6F2), Color(0xFF24506E)), // cielo
    (Color(0xFFE4DCF0), Color(0xFF533A7A)), // lavanda
    (Color(0xFFF6EAC2), Color(0xFF6E5410)), // mantequilla
    (Color(0xFFF4D6DA), Color(0xFF82313F)), // rosa
    (Color(0xFFD3ECE6), Color(0xFF1F5C50)), // menta
    (Color(0xFFEADFD2), Color(0xFF5C4532)), // arena
  ];

  /// El par de [key] (p. ej. el id de la categoría). Con un hash propio y no
  /// `hashCode`, que puede cambiar entre la web y Android; sus números nunca
  /// pasan de 2^53, así da lo mismo con los enteros de JavaScript.
  static (Color, Color) of(String key) {
    var hash = 7;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) % 2147483647;
    }
    return pairs[hash % pairs.length];
  }
}
