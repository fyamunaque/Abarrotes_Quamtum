import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cart/cart.dart';
import '../../cart/cart_provider.dart';
import '../../common/money.dart';
import '../../router/routes.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import '../../theme/neils_theme.dart';
import '../catalog/product_photo.dart';
import '../shared/brand.dart';
import '../shared/error_message.dart';
import '../shared/press_scale.dart';
import '../shared/quantity_stepper.dart';
import '../shared/vip_tag.dart';

/// El carrito: cambiar cantidades, quitar productos, ver el total estimado
/// (con los precios de la cuenta, p. ej. los VIP) y hacer el pedido. El
/// precio final lo pone el servidor.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return PublicScaffold(
      title: 'Carrito',
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Carrito', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          if (cart.isEmpty)
            const _EmptyCart()
          else ...[
            for (final line in cart.lines)
              _CartLineTile(line, key: ValueKey(line.product.id)),
            const Divider(height: 32),
            _Total(cart),
            const SizedBox(height: 24),
            const _Checkout(),
          ],
        ],
      ),
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  const _CartLineTile(this.line, {super.key});

  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final product = line.product;
    final cart = ref.read(cartProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.square(
                  dimension: 64,
                  child: ProductPhoto(product.imageUrl, iconSize: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: theme.textTheme.titleMedium),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${formatSoles(product.finalPriceCents)} c/u',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (product.vipPrice && ref.watch(isVipProvider))
                          const VipTag(),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Quitar del carrito',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => cart.remove(product.id),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              QuantityStepper(
                quantity: line.quantity,
                max: product.maxQuantity,
                onChanged: (quantity) => cart.setQuantity(product.id, quantity),
              ),
              const Spacer(),
              Text(
                formatSoles(line.totalCents),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total(this.cart);

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Total estimado', style: text.titleLarge),
            const Spacer(),
            Text(
              formatSoles(cart.totalCents),
              style: NeilsText.price(fontSize: 26),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'El precio final lo confirma la tienda al hacer el pedido.',
          style: text.bodySmall,
        ),
      ],
    );
  }
}

/// La dirección de entrega y "Confirmar pedido". Sin cuenta, lleva a ingresar
/// y vuelve aquí.
class _Checkout extends ConsumerStatefulWidget {
  const _Checkout();

  @override
  ConsumerState<_Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends ConsumerState<_Checkout> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  bool _prefilled = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefill(ref.read(sessionProvider));
  }

  /// Propone la dirección del perfil una vez, apenas se sabe la cuenta (al
  /// abrir, o cuando la sesión termina de cargar).
  void _prefill(Session session) {
    if (_prefilled || session is! SignedIn) return;
    _prefilled = true;
    if (_address.text.isEmpty) _address.text = session.user.address ?? '';
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await ref
          .read(cartProvider.notifier)
          .placeOrder(deliveryAddress: _address.text.trim());
      if (mounted) context.go(Routes.myOrdersWithNew(order.id));
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = errorMessage(error, 'No se pudo hacer el pedido.'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.listen(sessionProvider, (_, session) => _prefill(session));
    return switch (ref.watch(sessionProvider)) {
      SessionLoading() => const SizedBox.shrink(),
      SignedOut() => FilledButton(
        onPressed: () => context.go(
          Uri(
            path: Routes.login,
            queryParameters: {'from': Routes.cart},
          ).toString(),
        ),
        child: const Text('Ingresar para confirmar'),
      ),
      SignedIn() => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Dirección de entrega',
                helperText: 'Calle, número y distrito',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofillHints: const [AutofillHints.fullStreetAddress],
              validator: validateDeliveryAddress,
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            PressScale(
              enabled: !_busy,
              child: FilledButton(
                onPressed: _busy ? null : _confirm,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmar pedido'),
              ),
            ),
          ],
        ),
      ),
    };
  }
}

/// El servidor guarda hasta 255 caracteres.
String? validateDeliveryAddress(String? value) {
  final address = value?.trim() ?? '';
  if (address.isEmpty) return 'Escribe a dónde llevamos el pedido.';
  if (address.length > 255) return 'Usa hasta 255 caracteres.';
  return null;
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Tu carrito está vacío.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go(Routes.catalog),
            child: const Text('Ver el catálogo'),
          ),
        ],
      ),
    );
  }
}
