import 'package:flutter/material.dart';

import 'account.dart';
import 'brand.dart';
import 'diagonal_band.dart';
import '../../theme/palette.dart';

/// El encabezado de la portada: el titular (con [titleAccent] en el rojo de
/// la marca), el texto, las acciones y la franja diagonal con la foto
/// [image] (o, sin ella, el bloque rojo con el logo en blanco).
///
/// Desde [AccountActions.wideFrom], el texto a la izquierda y la franja a la
/// derecha; más angosto, la franja arriba y el texto debajo.
class BrandHero extends StatelessWidget {
  const BrandHero({
    super.key,
    required this.titleStart,
    required this.titleAccent,
    required this.body,
    required this.actions,
    this.image,
  });

  final String titleStart;
  final String titleAccent;
  final String body;
  final List<Widget> actions;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AccountActions.wideFrom;
    final text = Theme.of(context).textTheme;
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
                  TextSpan(text: titleStart),
                  TextSpan(
                    text: titleAccent,
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
        Text(
          body,
          style: text.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(spacing: 12, runSpacing: 12, children: actions),
      ],
    );
    final band = DiagonalBand(
      image: image,
      child: Opacity(
        opacity: 0.7,
        child: NeilsLogo.white(height: wide ? 140 : 80),
      ),
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 160, child: band),
          const SizedBox(height: 20),
          copy,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 55, child: copy),
        const SizedBox(width: 24),
        Expanded(flex: 45, child: SizedBox(height: 320, child: band)),
      ],
    );
  }
}

/// Los tres sellos de la portada, con su ícono: en fila desde
/// [AccountActions.wideFrom] (y en dos líneas si no entran), y en columna en
/// el teléfono.
class TrustBadges extends StatelessWidget {
  const TrustBadges({super.key});

  static const _badges = [
    (Icons.local_shipping_outlined, 'Entrega confiable'),
    (Icons.verified_outlined, 'Calidad garantizada'),
    (Icons.support_agent, 'Atención personalizada'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AccountActions.wideFrom;
    final style = Theme.of(context).textTheme.labelLarge;
    Widget badge((IconData, String) item) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.$1, color: context.palette.brandText, size: 28),
        const SizedBox(width: 10),
        Flexible(child: Text(item.$2, style: style)),
      ],
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, item) in _badges.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            badge(item),
          ],
        ],
      );
    }
    // Si no entran en una línea, siguen en la de abajo.
    return Wrap(
      spacing: 40,
      runSpacing: 12,
      children: [for (final item in _badges) badge(item)],
    );
  }
}
