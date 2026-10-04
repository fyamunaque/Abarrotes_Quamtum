import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cart/cart_provider.dart';
import '../../router/routes.dart';
import '../../theme/motion.dart';

/// El carrito en la barra, con cuántas unidades tiene. Cuando se agrega algo,
/// da un rebote corto (salvo con "reducir animaciones").
class CartButton extends ConsumerStatefulWidget {
  const CartButton({super.key});

  @override
  ConsumerState<CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends ConsumerState<CartButton>
    with SingleTickerProviderStateMixin {
  late final _bump = AnimationController(
    vsync: this,
    duration: NeilsMotion.bump,
  );

  late final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.25,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.25,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 60,
    ),
  ]).animate(_bump);

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cartProvider.select((cart) => cart.count), (previous, count) {
      if (previous != null &&
          count > previous &&
          !NeilsMotion.reduced(context)) {
        _bump.forward(from: 0);
      }
    });
    final count = ref.watch(cartProvider.select((cart) => cart.count));
    return IconButton(
      tooltip: count == 0 ? 'Carrito' : 'Carrito: $count',
      onPressed: () => context.go(Routes.cart),
      icon: ScaleTransition(
        scale: _scale,
        child: Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
      ),
    );
  }
}
