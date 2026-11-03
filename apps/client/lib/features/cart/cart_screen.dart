import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../cart/cart.dart';
import '../../cart/cart_provider.dart';
import '../../cart/cart_quote_provider.dart';
import '../../cart/checkout_provider.dart';
import '../../common/money.dart';
import '../../orders/fulfillment.dart';
import '../../orders/order.dart';
import '../../orders/quote.dart';
import '../../router/routes.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import '../../store/store_providers.dart';
import '../../theme/brand_colors.dart';
import '../../theme/motion.dart';
import '../../theme/neils_theme.dart';
import '../catalog/product_photo.dart';
import '../shared/brand.dart';
import '../shared/error_message.dart';
import '../shared/info_line.dart';
import '../shared/press_scale.dart';
import '../shared/quantity_stepper.dart';
import '../shared/store_details.dart';
import '../shared/verify_email_notice.dart';
import '../shared/vip_tag.dart';

/// El carrito: cambiar cantidades, quitar productos, ver el total y hacer el
/// pedido. El total sale de la cotización del servidor ([cartQuoteProvider],
/// con las promociones de la cuenta: cada línea con lo que ahorra, los
/// regalos y los descuentos); mientras llega, o si falla (con un aviso),
/// es la estimación con los precios del catálogo. El precio final lo pone
/// el servidor al hacer el pedido.
///
/// En un teléfono (menos de [checkoutBarBelow]), el total y "Confirmar
/// pedido" van en una barra fija abajo: no hace falta bajar hasta el final.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  /// Por debajo de este ancho, la barra fija.
  static const checkoutBarBelow = 720.0;

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressField = GlobalKey();
  final _address = TextEditingController();
  bool _prefilled = false;

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

  /// Valida y hace el pedido. Si falta la dirección, lleva la pantalla hasta
  /// el campo, que muestra su error (desde la barra puede no estar a la
  /// vista).
  Future<void> _confirm() async {
    final form = _formKey.currentState;
    if (form == null || ref.read(checkoutProvider).busy) return;
    if (!form.validate()) {
      if (_addressField.currentContext case final field?) {
        await Scrollable.ensureVisible(
          field,
          alignment: 0.3,
          duration: NeilsMotion.reduced(context)
              ? Duration.zero
              : NeilsMotion.scrollTo,
        );
      }
      return;
    }
    final order = await ref
        .read(checkoutProvider.notifier)
        .confirm(deliveryAddress: _address.text.trim());
    if (order != null && mounted) context.go(Routes.myOrdersWithNew(order.id));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionProvider, (_, session) => _prefill(session));
    final cart = ref.watch(cartProvider);
    final quoted = ref.watch(cartQuoteProvider);
    final quote = quoteFor(cart, quoted.value);
    final quoteFailed = quoted.hasError && !quoted.isLoading;
    final totalCents = quote?.totalCents ?? cart.totalCents;
    final withBar =
        !cart.isEmpty &&
        MediaQuery.sizeOf(context).width < CartScreen.checkoutBarBelow;
    return PublicScaffold(
      title: 'Carrito',
      maxWidth: 720,
      // El aviso del correo va en el checkout, donde hace falta.
      showVerifyEmail: false,
      bottomBar: withBar
          ? _CheckoutBar(totalCents: totalCents, onConfirm: _confirm)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Carrito', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          if (cart.isEmpty)
            const _EmptyCart()
          else ...[
            for (final line in cart.lines)
              _CartLineTile(
                line,
                quoted: quote?.lineOf(line.product.id),
                key: ValueKey(line.product.id),
              ),
            for (final gift in quote?.gifts ?? const <OrderLine>[])
              _GiftLine(gift),
            if (quoteFailed)
              const _QuoteNotice(
                'No pudimos calcular las promociones. El total final se '
                'confirma al pedir.',
              )
            else
              for (final notice in quote?.notices ?? const <String>[])
                _QuoteNotice(notice),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => context.go(Routes.myCodesFrom(Routes.cart)),
                icon: const Icon(Icons.confirmation_number_outlined),
                label: const Text('¿Tienes un código?'),
              ),
            ),
            const Divider(height: 32),
            _Total(cart, quote: quote),
            const SizedBox(height: 24),
            _Checkout(
              formKey: _formKey,
              address: _address,
              addressField: _addressField,
              // Con la barra, el botón y el error van en ella.
              onConfirm: withBar ? null : _confirm,
            ),
          ],
        ],
      ),
    );
  }
}

/// Ingresar y volver al carrito.
void _signInForCart(BuildContext context) => context.go(
  Uri(path: Routes.login, queryParameters: {'from': Routes.cart}).toString(),
);

/// Una línea del carrito. Con [quoted] (la de la cotización), su precio, su
/// total y lo que ahorra cada promoción ("2x1 −S/ 24.90").
class _CartLineTile extends ConsumerWidget {
  const _CartLineTile(this.line, {this.quoted, super.key});

  final CartLine line;
  final OrderLine? quoted;

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
                  child: ProductPhoto(
                    product.imageUrl,
                    name: product.name,
                    colorKey: product.category?.id,
                    initialSize: 28,
                  ),
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
                          '${formatSoles(quoted?.unitPriceCents ?? product.finalPriceCents)} c/u',
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
                formatSoles(quoted?.lineTotalCents ?? line.totalCents),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          for (final promotion in quoted?.promotions ?? const [])
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                '${promotion.label} −${formatSoles(promotion.savedCents)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: StateColors.positive,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Un regalo de la cotización: "1 × Sal 1 kg" y "Regalo".
class _GiftLine extends StatelessWidget {
  const _GiftLine(this.gift);

  final OrderLine gift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 64,
            child: Icon(
              Icons.card_giftcard_outlined,
              size: 28,
              color: StateColors.positive,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${gift.quantity} × ${gift.name}',
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Regalo',
            style: theme.textTheme.titleMedium?.copyWith(
              color: StateColors.positive,
            ),
          ),
        ],
      ),
    );
  }
}

/// Un aviso de la cotización ("Solo quedaba 1 de Sal 1 kg para regalo") o
/// de que no se pudo cotizar.
class _QuoteNotice extends StatelessWidget {
  const _QuoteNotice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      InfoLine(icon: Icons.info_outline, text: text);
}

/// El total: el de la cotización ([quote]), con el subtotal y los
/// descuentos si los hay, o la estimación del carrito.
class _Total extends StatelessWidget {
  const _Total(this.cart, {this.quote});

  final Cart cart;
  final Quote? quote;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final quote = this.quote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (quote != null && quote.discountCents > 0) ...[
          Row(
            children: [
              Expanded(child: Text('Subtotal', style: text.bodyLarge)),
              Text(formatSoles(quote.subtotalCents), style: text.bodyLarge),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text('Descuentos', style: text.bodyLarge)),
              Text(
                '−${formatSoles(quote.discountCents)}',
                style: text.bodyLarge?.copyWith(color: StateColors.positive),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            // Con el texto agrandado, "Total estimado" baja de línea antes
            // que el monto se salga de la pantalla.
            Expanded(child: Text('Total estimado', style: text.titleLarge)),
            const SizedBox(width: 12),
            Text(
              formatSoles(quote?.totalCents ?? cart.totalCents),
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

/// Desde este ancho, las opciones de entrega llevan su ícono.
const _segmentIconsMinWidth = 440.0;

/// Cómo llega el pedido (a domicilio o para recoger en la tienda) y
/// "Confirmar pedido". A domicilio pide la dirección; con recojo muestra
/// dónde y cuándo recogerlo. Sin cuenta, lleva a ingresar y vuelve aquí.
///
/// Sin [onConfirm] (en el teléfono), sin el botón ni el error: van en la
/// barra fija ([_CheckoutBar]).
class _Checkout extends ConsumerWidget {
  const _Checkout({
    required this.formKey,
    required this.address,
    required this.addressField,
    required this.onConfirm,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController address;

  /// El campo de la dirección, para llevar la pantalla hasta él.
  final GlobalKey addressField;

  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final checkout = ref.watch(checkoutProvider);
    final notifier = ref.read(checkoutProvider.notifier);
    final onConfirm = this.onConfirm;
    return switch (ref.watch(sessionProvider)) {
      SessionLoading() => const SizedBox.shrink(),
      SignedOut() when onConfirm == null => const SizedBox.shrink(),
      SignedOut() => FilledButton(
        onPressed: () => _signInForCart(context),
        child: const Text('Ingresar para confirmar'),
      ),
      SignedIn(:final user) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_missingToOrder(user) case final missing?) ...[
              _MissingToOrder(user, missing),
              const SizedBox(height: 16),
            ],
            Semantics(
              header: true,
              child: Text(
                '¿Cómo quieres recibirlo?',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            // En un teléfono, sin íconos: así cada opción entra en una línea.
            LayoutBuilder(
              builder: (context, constraints) {
                final icons = constraints.maxWidth >= _segmentIconsMinWidth;
                return SegmentedButton<FulfillmentType>(
                  segments: [
                    ButtonSegment(
                      value: FulfillmentType.delivery,
                      label: const Text('Entrega a domicilio'),
                      icon: icons
                          ? const Icon(Icons.local_shipping_outlined)
                          : null,
                    ),
                    ButtonSegment(
                      value: FulfillmentType.pickup,
                      label: const Text('Recoger en tienda'),
                      icon: icons
                          ? const Icon(Icons.storefront_outlined)
                          : null,
                    ),
                  ],
                  selected: {checkout.fulfillmentType},
                  showSelectedIcon: false,
                  onSelectionChanged: checkout.busy
                      ? null
                      : (selected) => notifier.choose(selected.single),
                );
              },
            ),
            const SizedBox(height: 16),
            if (checkout.fulfillmentType == FulfillmentType.delivery)
              TextFormField(
                key: addressField,
                controller: address,
                decoration: const InputDecoration(
                  labelText: 'Dirección de entrega',
                  helperText: 'Calle, número y distrito',
                ),
                textCapitalization: TextCapitalization.sentences,
                autofillHints: const [AutofillHints.fullStreetAddress],
                validator: validateDeliveryAddress,
              )
            else
              const _PickupSummary(),
            if (onConfirm != null) ...[
              if (checkout.error case final error?) ...[
                const SizedBox(height: 16),
                _CheckoutError(error),
              ],
              const SizedBox(height: 16),
              _ConfirmButton(
                busy: checkout.busy,
                onPressed: _missingToOrder(user) == null ? onConfirm : null,
              ),
            ],
          ],
        ),
      ),
    };
  }
}

/// En el teléfono: el total y "Confirmar pedido" (o "Ingresar para
/// confirmar"), fijos abajo de la pantalla. Arriba, el error del último
/// intento.
class _CheckoutBar extends ConsumerWidget {
  const _CheckoutBar({required this.totalCents, required this.onConfirm});

  final int totalCents;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final checkout = ref.watch(checkoutProvider);
    final session = ref.watch(sessionProvider);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (session case SignedIn(:final user)
                  when _missingToOrder(user) != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _missingToOrder(user)!.short,
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else if (checkout.error case final error?
                  when session is SignedIn)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CheckoutError(error),
                ),
              // El total a la izquierda y el botón a la derecha; si no entran
              // en una línea (p. ej. con el texto agrandado), el botón va
              // debajo.
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.start,
                spacing: 12,
                overflowSpacing: 8,
                children: [
                  MergeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total estimado',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          formatSoles(totalCents),
                          style: NeilsText.price(fontSize: 22),
                        ),
                      ],
                    ),
                  ),
                  switch (session) {
                    SessionLoading() => const SizedBox.shrink(),
                    SignedOut() => FilledButton(
                      onPressed: () => _signInForCart(context),
                      child: const Text('Ingresar para confirmar'),
                    ),
                    SignedIn(:final user) => _ConfirmButton(
                      busy: checkout.busy,
                      onPressed: _missingToOrder(user) == null
                          ? onConfirm
                          : null,
                    ),
                  },
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.busy, required this.onPressed});

  final bool busy;

  /// Null: desactivado (p. ej. falta confirmar el correo).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      enabled: !busy,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Confirmar pedido'),
      ),
    );
  }
}

/// Lo que le falta a una cuenta para pedir: lo mismo que revisa el servidor
/// (`POST /orders` responde 403 sin esto).
enum _Missing {
  email('Para pedir, confirma tu correo.'),
  profile('Para pedir, completa tu cuenta.');

  const _Missing(this.short);

  /// Para la barra del teléfono, al lado del botón desactivado.
  final String short;
}

_Missing? _missingToOrder(SessionUser user) => !user.emailVerified
    ? _Missing.email
    : !user.profileComplete
    ? _Missing.profile
    : null;

/// Antes del formulario, qué falta para pedir: el aviso para confirmar el
/// correo (reenviarlo y "Ya lo verifiqué"), o completar la cuenta en "Mi
/// cuenta", que vuelve al carrito.
class _MissingToOrder extends StatelessWidget {
  const _MissingToOrder(this.user, this.missing);

  final SessionUser user;
  final _Missing missing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return switch (missing) {
      _Missing.email => VerifyEmailNotice(
        user,
        key: ValueKey(user.id),
        title: 'Para hacer pedidos, confirma tu correo.',
      ),
      _Missing.profile => DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InfoLine(
                icon: Icons.person_outline,
                text:
                    'Para hacer pedidos, completa tu cuenta: tu celular y '
                    'aceptar los términos.',
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => context.go(Routes.myAccountFrom(Routes.cart)),
                child: const Text('Completar mi cuenta'),
              ),
            ],
          ),
        ),
      ),
    };
  }
}

/// Por qué no salió el pedido, con el mensaje del servidor si lo hay.
class _CheckoutError extends StatelessWidget {
  const _CheckoutError(this.error);

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        errorMessage(error, 'No se pudo hacer el pedido.'),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// Con recojo: el pedido se recoge en la tienda, dónde y cuándo, y cómo
/// (el código que se da al confirmar).
class _PickupSummary extends ConsumerWidget {
  const _PickupSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final store = ref.watch(storeSettingsProvider);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recoges tu pedido en ${storeNameOf(store)}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const StoreDetails(),
            const SizedBox(height: 4),
            Text(
              'No hay costo de envío. Te avisamos cuando esté listo y, al '
              'confirmarlo, te damos un código para mostrar en caja.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
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
