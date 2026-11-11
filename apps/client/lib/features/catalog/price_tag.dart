import 'package:flutter/material.dart';

import '../../catalog/product.dart';
import '../../common/money.dart';
import '../../theme/motion.dart';
import '../../theme/neils_theme.dart';
import '../shared/vip_tag.dart';
import '../../theme/palette.dart';

/// El precio que se paga hoy. En promoción, al lado va el precio normal tachado. Con un precio de cliente
/// VIP, además la insignia VIP, y el precio entra con una animación breve,
/// una sola vez.
class PriceTag extends StatelessWidget {
  PriceTag(Product product, {super.key, this.fontSize = 22})
    : priceCents = product.priceCents,
      promoPriceCents = product.promoPriceCents,
      vipPrice = product.vipPrice;

  /// Los precios sueltos, para lo que no es un producto del catálogo (p. ej.
  /// una oferta).
  const PriceTag.prices({
    super.key,
    required this.priceCents,
    this.promoPriceCents,
    this.vipPrice = false,
    this.fontSize = 22,
  });

  /// El precio normal.
  final int priceCents;

  /// El de la promoción, si hay.
  final int? promoPriceCents;

  /// Si esa promoción es VIP.
  final bool vipPrice;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tag = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          formatSoles(promoPriceCents ?? priceCents),
          // En oferta, en el rojo de la marca; si no, en tinta.
          style: NeilsText.price(
            fontSize: fontSize,
            color: promoPriceCents == null
                ? context.palette.ink
                : context.palette.brandText,
          ),
        ),
        if (promoPriceCents != null)
          Text(
            formatSoles(priceCents),
            // Tachado no se oye: el lector de pantalla dice "Antes".
            semanticsLabel: 'Antes ${formatSoles(priceCents)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        if (vipPrice) const VipTag(),
      ],
    );
    return vipPrice ? VipReveal(child: tag) : tag;
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
