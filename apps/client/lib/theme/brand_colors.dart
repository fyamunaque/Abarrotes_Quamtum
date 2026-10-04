import 'package:flutter/painting.dart';

/// Tokens de marca de Neil's Food Services: los mismos que la app Kotlin
/// (ui/theme/Theme.kt).
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
  static const delivered = Color(0xFF3C7A5F);

  /// Este sí sirve para texto sobre crema (6,8:1).
  static const cancelled = Color(0xFF8C3B33);
}
