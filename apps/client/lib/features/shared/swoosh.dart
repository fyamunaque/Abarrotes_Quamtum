import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/brand_colors.dart';
import '../../theme/motion.dart';

/// El trazo de pincel del logo: nace fino a la izquierda, sube hacia la
/// derecha, engorda pasada la mitad y termina en punta.
///
/// [progress] (de 0 a 1) dibuja solo el tramo inicial, como si el pincel
/// avanzara. Por defecto está completo.
class SwooshPainter extends CustomPainter {
  const SwooshPainter({
    this.progress = const AlwaysStoppedAnimation(1),
    this.color = NeilsColors.accent,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  /// Puntos por borde del trazo completo: de sobra para que la curva se vea
  /// lisa a cualquier ancho.
  static const _samples = 48;

  /// El contorno del tramo dibujado hasta [progress], en un lienzo de [size].
  static Path outline(Size size, double progress) {
    final end = progress.clamp(0.0, 1.0);
    final path = Path();
    if (end == 0 || size.isEmpty) return path;

    final count = math.max(2, (_samples * end).ceil());
    final edge = <Offset>[];
    final otherEdge = <Offset>[];
    for (var i = 0; i <= count; i++) {
      final t = end * i / count;
      final center = _point(size, t);
      final offset = _normal(size, t) * (_thickness(size, t) / 2);
      edge.add(center + offset);
      otherEdge.add(center - offset);
    }
    path.moveTo(edge.first.dx, edge.first.dy);
    for (final point in [...edge.skip(1), ...otherEdge.reversed]) {
      path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  // La línea central es una Bézier cúbica: de abajo a la izquierda a arriba a
  // la derecha, con la panza hacia arriba, como en el logo.
  static const _p0 = Offset(0, 0.9);
  static const _p1 = Offset(0.3, 0.7);
  static const _p2 = Offset(0.65, 0.3);
  static const _p3 = Offset(1, 0.2);

  static Offset _point(Size size, double t) {
    final u = 1 - t;
    final p =
        _p0 * (u * u * u) +
        _p1 * (3 * u * u * t) +
        _p2 * (3 * u * t * t) +
        _p3 * (t * t * t);
    return Offset(p.dx * size.width, p.dy * size.height);
  }

  /// La perpendicular unitaria a la curva en [t].
  static Offset _normal(Size size, double t) {
    final u = 1 - t;
    final d =
        (_p1 - _p0) * (3 * u * u) +
        (_p2 - _p1) * (6 * u * t) +
        (_p3 - _p2) * (3 * t * t);
    final tangent = Offset(d.dx * size.width, d.dy * size.height);
    return Offset(-tangent.dy, tangent.dx) / tangent.distance;
  }

  /// El grosor en [t]: una cola fina que crece hacia la derecha, el máximo
  /// (la mitad del alto) cerca de t = 0,78 y un final corto y redondeado.
  static double _thickness(Size size, double t) {
    final body = math.pow(t, 0.9) * math.sqrt(1 - math.pow(t, 6));
    return size.height * 0.5 * body / 0.705;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(outline(size, progress.value), Paint()..color = color);
  }

  @override
  bool shouldRepaint(SwooshPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// El swoosh quieto, p. ej. como subrayado del precio. Ocupa el ancho que le
/// den. Es decoración: los lectores de pantalla lo saltan.
class Swoosh extends StatelessWidget {
  const Swoosh({super.key, this.height = 8, this.color = NeilsColors.accent});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: SwooshPainter(color: color)),
      ),
    );
  }
}

/// El swoosh dibujándose al aparecer: una sola vez, en [NeilsMotion.swoosh],
/// sin repetirse aunque la pantalla se reconstruya. Con "reducir animaciones"
/// aparece completo.
class AnimatedSwoosh extends StatefulWidget {
  const AnimatedSwoosh({
    super.key,
    this.height = 18,
    this.color = NeilsColors.accent,
  });

  final double height;
  final Color color;

  @override
  State<AnimatedSwoosh> createState() => _AnimatedSwooshState();
}

class _AnimatedSwooshState extends State<AnimatedSwoosh>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: NeilsMotion.swoosh,
  );
  late final _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (NeilsMotion.reduced(context)) {
      // También si se activa a mitad del trazo: termina de golpe.
      _controller.value = 1;
    } else if (!_started) {
      _controller.forward();
    }
    _started = true;
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: CustomPaint(
            painter: SwooshPainter(progress: _progress, color: widget.color),
          ),
        ),
      ),
    );
  }
}
