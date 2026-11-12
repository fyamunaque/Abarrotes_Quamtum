import 'package:flutter/material.dart';

import '../../common/money.dart';
import '../../theme/neils_theme.dart';
import '../../theme/palette.dart';

/// El resumen del carrito, como un ticket: sobre el panel cálido
/// ([NeilsPalette.surfaceAlt]) y con el borde de arriba perforado. Siempre
/// "Subtotal", "Total estimado" y la nota de que el precio final lo confirma
/// la tienda; "Descuentos", solo si hay.
class CartTicket extends StatelessWidget {
  const CartTicket({
    super.key,
    required this.subtotalCents,
    required this.discountCents,
    required this.totalCents,
  });

  final int subtotalCents;
  final int discountCents;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    Widget row(String label, String amount, {Color? color}) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: text.bodyLarge)),
        const SizedBox(width: 12),
        Text(amount, style: text.bodyLarge?.copyWith(color: color)),
      ],
    );
    return ClipPath(
      clipper: const PerforatedEdgeClipper(),
      child: ColoredBox(
        color: palette.surfaceAlt,
        child: Padding(
          // Arriba, lugar para las perforaciones.
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row('Subtotal', formatSoles(subtotalCents)),
              if (discountCents > 0) ...[
                const SizedBox(height: 4),
                row(
                  'Descuentos',
                  '−${formatSoles(discountCents)}',
                  color: palette.positive,
                ),
              ],
              const SizedBox(height: 10),
              Divider(height: 1, color: palette.line),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Con el texto agrandado, "Total estimado" baja de línea
                  // antes que el monto se salga de la pantalla.
                  Expanded(
                    child: Text('Total estimado', style: text.titleLarge),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatSoles(totalCents),
                    style: NeilsText.price(fontSize: 26),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'El precio final lo confirma la tienda al hacer el pedido.',
                style: text.bodySmall?.copyWith(color: palette.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un rectángulo con el borde de arriba perforado: medios círculos de
/// [radius] cada [pitch] px, como el corte de un ticket.
class PerforatedEdgeClipper extends CustomClipper<Path> {
  const PerforatedEdgeClipper({this.radius = 5, this.pitch = 16});

  final double radius;
  final double pitch;

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, 0);
    // Los agujeros, repartidos parejo a lo ancho.
    final holes = (size.width / pitch).floor().clamp(1, 1000);
    final step = size.width / holes;
    for (var i = 0; i < holes; i++) {
      final center = step * i + step / 2;
      path
        ..lineTo(center - radius, 0)
        ..arcToPoint(
          Offset(center + radius, 0),
          radius: Radius.circular(radius),
          clockwise: false,
        );
    }
    return path
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(PerforatedEdgeClipper oldClipper) =>
      oldClipper.radius != radius || oldClipper.pitch != pitch;
}
