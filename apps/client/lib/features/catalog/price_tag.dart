import 'package:flutter/material.dart';

import '../../catalog/product.dart';
import '../../common/money.dart';
import '../../theme/motion.dart';
import '../../theme/neils_theme.dart';
import '../shared/swoosh.dart';
import '../shared/vip_tag.dart';

/// El precio que se paga hoy, subrayado con el swoosh de la marca. En
/// promoción, al lado va el precio normal tachado. Con un precio de cliente
/// VIP, además la insignia VIP, y el precio entra con una animación breve,
/// una sola vez.
class PriceTag extends StatelessWidget {
  const PriceTag(this.product, {super.key, this.fontSize = 22});

  final Product product;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = fontSize / 22;
    final tag = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                formatSoles(product.finalPriceCents),
                style: NeilsText.price(fontSize: fontSize),
              ),
              // Sube para quedar pegado a los números, como en el logo.
              Transform.translate(
                offset: Offset(0, -5 * scale),
                child: Swoosh(height: 8 * scale),
              ),
            ],
          ),
        ),
        if (product.onSale)
          Text(
            formatSoles(product.priceCents),
            // Tachado no se oye: el lector de pantalla dice "Antes".
            semanticsLabel: 'Antes ${formatSoles(product.priceCents)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        if (product.vipPrice) const VipTag(),
      ],
    );
    return product.vipPrice ? VipReveal(child: tag) : tag;
  }
}

/// La entrada de un precio VIP: crece un poco y aparece, en
/// [NeilsMotion.reveal]. Corre una vez, al aparecer; con "reducir
/// animaciones", el precio está desde el principio.
class VipReveal extends StatelessWidget {
  const VipReveal({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: NeilsMotion.reduced(context)
          ? Duration.zero
          : NeilsMotion.reveal,
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(
          scale: 0.9 + 0.1 * t,
          alignment: AlignmentDirectional.centerStart.resolve(
            Directionality.of(context),
          ),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
