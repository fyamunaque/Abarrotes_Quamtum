import 'package:flutter/widgets.dart';

import '../../theme/motion.dart';

/// Achica un poco a [child] mientras se presiona: confirma el toque antes de
/// que la acción termine. Deshabilitado, o con "reducir animaciones", no
/// cambia de tamaño.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.94,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _press(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final shrink = _pressed && widget.enabled && !NeilsMotion.reduced(context);
    // Listener no compite con el botón por el gesto: solo mira el puntero.
    return Listener(
      onPointerDown: (_) => _press(true),
      onPointerUp: (_) => _press(false),
      onPointerCancel: (_) => _press(false),
      child: AnimatedScale(
        scale: shrink ? widget.pressedScale : 1,
        duration: NeilsMotion.press,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
