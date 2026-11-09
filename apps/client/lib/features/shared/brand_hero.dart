import 'package:flutter/material.dart';

import '../../theme/motion.dart';
import '../../theme/palette.dart';
import 'account.dart';
import 'brand.dart';
import 'diagonal_band.dart';

/// El encabezado de la portada: el titular (con [titleAccent] en el rojo de
/// la marca), el texto, una nota opcional ([note], p. ej. el horario), las
/// acciones y la franja diagonal con la foto [image] (o, sin ella, el bloque
/// rojo con el logo en blanco).
///
/// Desde [AccountActions.wideFrom], el texto a la izquierda y la franja a la
/// derecha; más angosto, la franja arriba y el texto debajo.
///
/// Con [entrance], entra una vez al aparecer: el texto sube 12 px desde
/// transparente y la foto se asienta de 1,03 a 1, en [NeilsMotion.entrance].
/// Con "reducir animaciones", está desde el primer cuadro. La entrada no
/// bloquea nada: se puede tocar y escribir mientras tanto.
class BrandHero extends StatefulWidget {
  const BrandHero({
    super.key,
    required this.titleStart,
    required this.titleAccent,
    required this.body,
    required this.actions,
    this.note,
    this.image,
    this.entrance = false,
  });

  final String titleStart;
  final String titleAccent;
  final String body;
  final String? note;
  final List<Widget> actions;
  final String? image;
  final bool entrance;

  @override
  State<BrandHero> createState() => _BrandHeroState();
}

class _BrandHeroState extends State<BrandHero>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: NeilsMotion.entrance,
    value: widget.entrance ? 0 : 1,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (NeilsMotion.reduced(context)) {
      _controller.value = 1;
    } else if (widget.entrance) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AccountActions.wideFrom;
    final text = Theme.of(context).textTheme;
    final muted = context.palette.inkMuted;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Un solo encabezado para el lector de pantalla.
        MergeSemantics(
          child: Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: widget.titleStart),
                  TextSpan(
                    text: widget.titleAccent,
                    style: TextStyle(color: context.palette.brandText),
                  ),
                ],
              ),
              style: (wide ? text.displaySmall : text.headlineMedium)?.copyWith(
                height: 1.1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(widget.body, style: text.bodyLarge?.copyWith(color: muted)),
        if (widget.note case final note?) ...[
          const SizedBox(height: 8),
          Text(
            note,
            style: text.labelLarge?.copyWith(color: context.palette.ink),
          ),
        ],
        const SizedBox(height: 24),
        Wrap(spacing: 12, runSpacing: 12, children: widget.actions),
      ],
    );
    final band = DiagonalBand(
      image: widget.image,
      child: Opacity(
        opacity: 0.7,
        child: NeilsLogo.white(height: wide ? 140 : 80),
      ),
    );

    // La entrada: el texto sube desde transparente; la foto se asienta.
    final enteringCopy = AnimatedBuilder(
      animation: _curve,
      builder: (_, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: copy,
    );
    final settlingBand = ClipRect(
      child: AnimatedBuilder(
        animation: _curve,
        builder: (_, child) =>
            Transform.scale(scale: 1.03 - 0.03 * _curve.value, child: child),
        child: band,
      ),
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 160, child: settlingBand),
          const SizedBox(height: 20),
          enteringCopy,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 55, child: enteringCopy),
        const SizedBox(width: 32),
        Expanded(flex: 45, child: SizedBox(height: 320, child: settlingBand)),
      ],
    );
  }
}
