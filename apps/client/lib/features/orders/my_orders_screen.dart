import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/money.dart';
import '../../orders/order.dart';
import '../../orders/orders_providers.dart';
import '../../router/routes.dart';
import '../../theme/brand_colors.dart';
import '../../theme/neils_theme.dart';
import '../shared/brand.dart';
import '../shared/date_format.dart';
import '../shared/error_message.dart';
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
            const _ReceivedNotice(),
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

class _ReceivedNotice extends StatelessWidget {
  const _ReceivedNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                child: Text(
                  'Recibimos tu pedido. La tienda lo va a confirmar.',
                  style: theme.textTheme.bodyLarge,
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
            const SizedBox(height: 16),
            OrderTracker(status: order.status),
            const SizedBox(height: 16),
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
            const SizedBox(height: 8),
            Text('Entrega en ${order.deliveryAddress}', style: muted),
          ],
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
