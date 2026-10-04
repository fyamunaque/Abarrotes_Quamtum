import 'package:flutter/widgets.dart';

/// Movimiento de la marca. Todo respeta "reducir animaciones" del sistema
/// (Android: "Quitar animaciones"; web: prefers-reduced-motion): con eso
/// activo, cada animación salta directo a su estado final.
abstract final class NeilsMotion {
  /// El swoosh de la portada: se dibuja una vez, en menos de un segundo.
  static const swoosh = Duration(milliseconds: 700);

  /// La respuesta de un botón al presionarlo.
  static const press = Duration(milliseconds: 110);

  /// La línea del seguimiento de pedido cuando el estado avanza.
  static const progress = Duration(milliseconds: 500);

  /// Si la persona pidió reducir las animaciones.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
