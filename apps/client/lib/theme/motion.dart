import 'package:flutter/widgets.dart';

/// Movimiento de la marca. Todo respeta "reducir animaciones" del sistema
/// (Android: "Quitar animaciones"; web: prefers-reduced-motion): con eso
/// activo, cada animación salta directo a su estado final.
abstract final class NeilsMotion {
  /// La curva de todo: arranca rápido y se asienta suave, sin pasarse.
  static const ease = Cubic(.2, .8, .2, 1);

  /// La respuesta de un botón al presionarlo.
  static const press = Duration(milliseconds: 90);

  /// Un número que cambia (la cantidad, un total, el del carrito): el de
  /// antes sale y el nuevo entra.
  static const fade = Duration(milliseconds: 160);

  /// Una tarjeta bajo el mouse.
  static const hover = Duration(milliseconds: 180);

  /// La foto de una tarjeta bajo el mouse, que se acerca un poco.
  static const photoZoom = Duration(milliseconds: 600);

  /// La entrada del encabezado de la portada, una vez al abrirla.
  static const entrance = Duration(milliseconds: 600);

  /// La línea del seguimiento de pedido cuando el estado avanza.
  static const progress = Duration(milliseconds: 500);

  /// La entrada de un precio VIP en su tarjeta: una vez, al aparecer.
  static const reveal = Duration(milliseconds: 300);

  /// Llevar la pantalla hasta un campo que falta completar.
  static const scrollTo = Duration(milliseconds: 300);

  /// Si la persona pidió reducir las animaciones.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
