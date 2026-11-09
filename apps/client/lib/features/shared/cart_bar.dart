import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cart/cart_provider.dart';
import '../../cart/cart_quote_provider.dart';
import '../../common/money.dart';
import '../../router/routes.dart';
import '../../session/session_provider.dart';
import '../../theme/neils_theme.dart';
import '../../theme/palette.dart';
import 'value_fade.dart';

/// La barra roja fija de abajo, en el teléfono: el ícono del carrito con
/// [count] unidades, [label] ("Continuar", "Confirmar pedido") y el total,
/// con [totalLabel] encima si lo hay ("Total estimado"). Toda la barra es el
/// botón; sin [onPressed], se ve apagada. [busy] cambia el texto por un
/// indicador mientras se envía.
class CartBar extends StatelessWidget {
  const CartBar({
    super.key,
    required this.label,
    required this.totalCents,
    required this.onPressed,
    this.count,
    this.totalLabel,
    this.busy = false,
  });

  final String label;
  final int totalCents;
  final VoidCallback? onPressed;
  final int? count;
  final String? totalLabel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final enabled = onPressed != null && !busy;
    // La semántica envuelve al InkWell para que el nodo del botón lleve su
    // acción de tocar: el lector de pantalla lee la barra entera y la activa.
    return Opacity(
      opacity: enabled || busy ? 1 : 0.5,
      child: MergeSemantics(
        child: Semantics(
          button: true,
          enabled: enabled,
          child: Material(
            color: context.palette.brandFill,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      if (count case final count?) ...[
                        _CartCount(count),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: busy
                            ? Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: context.palette.onBrand,
                                    semanticsLabel: 'Enviando',
                                  ),
                                ),
                              )
                            : Text(
                                label,
                                style: text.titleMedium?.copyWith(
                                  color: context.palette.onBrand,
                                ),
                              ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: context.palette.onBrandDivider,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (totalLabel case final totalLabel?)
                            Text(
                              totalLabel,
                              style: text.labelSmall?.copyWith(
                                color: context.palette.onBrand,
                              ),
                            ),
                          ValueFade(
                            value: totalCents,
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              formatSoles(totalCents),
                              style: NeilsText.price(
                                fontSize: 20,
                                color: context.palette.onBrand,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El carrito con su número en un círculo blanco.
class _CartCount extends StatelessWidget {
  const _CartCount(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.shopping_cart_outlined,
          color: context.palette.onBrand,
          size: 28,
        ),
        PositionedDirectional(
          top: -6,
          end: -8,
          child: Container(
            constraints: const BoxConstraints(minWidth: 20),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: context.palette.onBrand,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              semanticsLabel: count == 1 ? '1 unidad' : '$count unidades',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.palette.brandFill,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// La [CartBar] de la tienda: "Continuar" lleva al carrito. Con el carrito
/// vacío no ocupa lugar. El total es el de la cotización si ya llegó la del
/// carrito tal como está; si no, el estimado.
class StoreCartBar extends ConsumerWidget {
  const StoreCartBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    if (cart.isEmpty) return const SizedBox.shrink();
    final quote = shownQuote(
      cart,
      ref.watch(cartQuoteProvider),
      ref.watch(sessionProvider),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: CartBar(
          label: 'Continuar',
          count: cart.count,
          totalCents: quote?.totalCents ?? cart.totalCents,
          onPressed: () => context.go(Routes.cart),
        ),
      ),
    );
  }
}
