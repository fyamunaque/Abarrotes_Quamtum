import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/money.dart';
import '../../orders/fulfillment.dart';
import '../../orders/order.dart';
import '../../orders/order_status.dart';
import '../../orders/orders_providers.dart';
import '../../router/routes.dart';
import '../../theme/brand_colors.dart';
import '../../theme/neils_theme.dart';
import '../shared/brand.dart';
import '../shared/date_format.dart';
import '../shared/error_message.dart';
import '../shared/store_details.dart';
import 'order_tracker.dart';

/// Los pedidos de la cuenta, cada uno con su seguimiento. Con [newOrderId]
/// (al venir de confirmar), un aviso de que el pedido llegó.
class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key, this.newOrderId});

  final String? newOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    return PublicScaffold(
      title: 'Mis pedidos',
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mis pedidos',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                tooltip: 'Actualizar',
                icon: const Icon(Icons.refresh),
                onPressed: orders.hasValue
                    ? () => _refresh(context, ref)
                    : null,
              ),
            ],
          ),
          if (newOrderId != null) ...[
            const SizedBox(height: 12),
            _ReceivedNotice(
              // El pedido recién hecho, con lo que cobró la tienda (si es
              // este: un enlace viejo con ?nuevo= no lo trae).
              switch (ref.watch(placedOrderProvider)) {
                final order? when order.id == newOrderId => order,
                _ => null,
              },
            ),
          ],
          const SizedBox(height: 16),
          // Mientras recarga se sigue viendo la lista anterior.
          switch (orders) {
            AsyncValue(value: final list?) when list.items.isEmpty =>
              const _NoOrders(),
            AsyncValue(value: final list?) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final order in list.items) ...[
                  _OrderCard(order, key: ValueKey(order.id)),
                  const SizedBox(height: 16),
                ],
                if (list.hasMore)
                  Center(
                    child: list.loadingMore
                        ? const CircularProgressIndicator()
                        : OutlinedButton(
                            onPressed: () => _loadMore(context, ref),
                            child: const Text('Ver más pedidos'),
                          ),
                  ),
              ],
            ),
            AsyncError(:final error) => Column(
              children: [
                Text(
                  errorMessage(error, 'No se pudieron cargar tus pedidos.'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(myOrdersProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
            _ => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) =>
      _showErrors(context, ref.read(myOrdersProvider.notifier).refresh());

  Future<void> _loadMore(BuildContext context, WidgetRef ref) =>
      _showErrors(context, ref.read(myOrdersProvider.notifier).loadMore());

  Future<void> _showErrors(BuildContext context, Future<void> action) async {
    try {
      await action;
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage(error, 'No se pudieron cargar tus pedidos.'),
            ),
          ),
        );
      }
    }
  }
}

/// "Recibimos tu pedido", con el total que cobró la tienda y, si alguno
/// cambió desde el carrito, cuál y cuánto.
class _ReceivedNotice extends StatelessWidget {
  const _ReceivedNotice(this.order);

  final Order? order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = this.order;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          border: Border.all(color: OrderStatusColors.confirmed),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: OrderStatusColors.confirmed,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recibimos tu pedido. La tienda lo va a confirmar.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (order != null)
                      Text(
                        'Total: ${formatSoles(order.totalCents)}',
                        style: theme.textTheme.titleMedium,
                      ),
                    if (order != null && order.priceChanges.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Algunos precios cambiaron desde que los agregaste:',
                        style: muted,
                      ),
                      for (final change in order.priceChanges)
                        Text(
                          '${change.name}: '
                          '${formatSoles(change.shownUnitPriceCents)} → '
                          '${formatSoles(change.unitPriceCents)}',
                          style: muted,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard(this.order, {super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = formatDateTime(context, order.createdAt);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Card.outlined(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Pedido del $date',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  formatSoles(order.totalCents),
                  style: NeilsText.price(fontSize: 20),
                ),
              ],
            ),
            if (order.status == OrderStatus.readyForPickup) ...[
              const SizedBox(height: 12),
              const _ReadyForPickupNotice(),
            ],
            const SizedBox(height: 16),
            OrderTracker(
              status: order.status,
              fulfillmentType: order.fulfillmentType,
            ),
            const SizedBox(height: 16),
            if (order.fulfillmentType == FulfillmentType.pickup) ...[
              _PickupDetails(order),
              const SizedBox(height: 16),
            ],
            for (final line in order.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text('${line.quantity} × ${line.name}')),
                    Text(formatSoles(line.totalCents)),
                  ],
                ),
              ),
            if (order.fulfillmentType == FulfillmentType.delivery) ...[
              const SizedBox(height: 8),
              Text('Entrega en ${order.deliveryAddress ?? '—'}', style: muted),
            ],
          ],
        ),
      ),
    );
  }
}

/// Los estados en que el cliente necesita su código: desde que la tienda
/// confirma el pedido hasta que lo recoge.
const _codeStatuses = {
  OrderStatus.confirmed,
  OrderStatus.preparing,
  OrderStatus.readyForPickup,
};

/// Un pedido de recojo: dónde y cuándo recogerlo y, desde que está
/// confirmado, el código en grande para mostrar en caja. Ya recogido o
/// cancelado, solo que era de recojo.
class _PickupDetails extends StatelessWidget {
  const _PickupDetails(this.order);

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final code = order.pickupCode;
    if (order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled) {
      return Text('Recojo en tienda', style: muted);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_codeStatuses.contains(order.status) && code != null) ...[
          _PickupCode(code),
          const SizedBox(height: 12),
        ],
        Text('Recojo en tienda', style: theme.textTheme.titleSmall),
        const StoreDetails(),
        if (order.status == OrderStatus.pendingConfirmation)
          Text(
            'Te damos tu código de recojo cuando la tienda confirme el pedido.',
            style: muted,
          ),
      ],
    );
  }
}

/// El código de recojo, en grande y bien visible, para enseñarlo en caja.
/// El lector de pantalla lo deletrea.
class _PickupCode extends StatelessWidget {
  const _PickupCode(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: 'Tu código de recojo: ${code.split('').join(' ')}',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              children: [
                Text(
                  'Tu código de recojo',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    code,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                  ),
                ),
                Text(
                  'Muéstralo en caja al recoger tu pedido.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El pedido ya se puede recoger: se destaca arriba del detalle (el aviso
/// push también llega).
class _ReadyForPickupNotice extends StatelessWidget {
  const _ReadyForPickupNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          border: Border.all(color: OrderStatusColors.readyForPickup, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                color: OrderStatusColors.readyForPickup,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Tu pedido está listo para recoger!',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Acércate a la tienda y muestra tu código en caja.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoOrders extends StatelessWidget {
  const _NoOrders();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            'Todavía no hiciste pedidos.',
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
