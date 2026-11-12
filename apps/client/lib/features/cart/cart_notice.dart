import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../catalog/product.dart';
import '../../router/routes.dart';
import '../../theme/palette.dart';
import '../catalog/product_photo.dart';

/// Cuánto se ve el aviso del carrito antes de irse solo.
const cartNoticeDuration = Duration(seconds: 3);

/// Muestra el aviso del carrito ([CartNotice]) flotando abajo (en el
/// teléfono, sobre la barra roja). Se va solo a los [cartNoticeDuration] o al
/// deslizarlo hacia abajo; "Ver carrito" lo cierra y lleva al carrito.
void showCartNotice(
  BuildContext context, {
  required Product product,
  required String title,
  bool stockLimit = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  // Ahora, mientras la pantalla de origen sigue montada: al tocar "Ver
  // carrito" puede que ya no lo esté. Sin router (una pieza suelta, fuera de
  // la app), "Ver carrito" solo cierra el aviso.
  final router = GoRouter.maybeOf(context);
  // El SnackBar cambia el tema de lo que lleva adentro: la tarjeta usa el de
  // la pantalla, en claro o en oscuro.
  final theme = Theme.of(context);
  final wide = MediaQuery.sizeOf(context).width >= 560;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        // La tarjeta pone su fondo, su borde y su forma.
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        width: wide ? 420 : null,
        margin: wide ? null : const EdgeInsets.fromLTRB(12, 0, 12, 12),
        duration: cartNoticeDuration,
        // Un SnackBar con acción (SnackBarAction) queda fijo hasta que lo
        // cierren; el aviso de antes llevaba "Ver carrito" así. Este se va
        // solo, aunque algún día lleve una acción.
        persist: false,
        dismissDirection: DismissDirection.down,
        content: Theme(
          data: theme,
          child: CartNotice(
            product: product,
            title: title,
            stockLimit: stockLimit,
            onOpenCart: () {
              messenger.hideCurrentSnackBar();
              router?.go(Routes.cart);
            },
          ),
        ),
      ),
    );
}

/// La tarjeta del aviso del carrito: la foto del producto, qué pasó
/// ([title], con un check o, si ya no queda stock para sumar, con un ícono de
/// aviso), el nombre y "Ver carrito".
class CartNotice extends StatelessWidget {
  const CartNotice({
    super.key,
    required this.product,
    required this.title,
    required this.onOpenCart,
    this.stockLimit = false,
  });

  final Product product;
  final String title;
  final VoidCallback onOpenCart;

  /// Ya estaba en el carrito todo el stock: el aviso no suma, avisa.
  final bool stockLimit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: palette.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox.square(
                dimension: 40,
                child: ProductPhoto(
                  product.imageUrl,
                  name: product.name,
                  colorKey: product.category?.id,
                  initialSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        stockLimit ? Icons.info_outline : Icons.check_circle,
                        size: 16,
                        color: stockLimit ? palette.caution : palette.positive,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          title,
                          style: text.labelLarge?.copyWith(color: palette.ink),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(color: palette.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: onOpenCart,
              style: TextButton.styleFrom(foregroundColor: palette.brandText),
              child: const Text('Ver carrito'),
            ),
          ],
        ),
      ),
    );
  }
}
