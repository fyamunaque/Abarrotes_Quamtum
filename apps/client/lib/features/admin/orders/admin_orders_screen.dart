import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/orders/admin_order.dart';
import '../../../admin/orders/admin_orders_providers.dart';
import '../../../common/money.dart';
import '../../../orders/order_status.dart';
import '../../orders/order_tracker.dart';
import '../../shared/date_format.dart';
import '../../shared/error_message.dart';
import '../shared/admin_page.dart';
import '../shared/admin_table.dart';
import '../shared/filter_chips.dart';
import '../shared/status_badge.dart';

/// Los pedidos de todos los clientes, filtrados por estado. Tocar uno abre su
/// detalle, con el stepper para avanzarlo o cancelarlo.
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  OrderStatus? _status;

  @override
  Widget build(BuildContext context) {
    final provider = adminOrdersProvider(_status);
    return AdminPage(
      title: 'Pedidos',
      children: [
        FilterChips<OrderStatus?>(
          options: [
            (null, 'Todos'),
            for (final status in OrderStatus.values) (status, status.label),
          ],
          selected: _status,
          onSelected: (status) => setState(() => _status = status),
        ),
        const SizedBox(height: 16),
        AdminTable<AdminOrder>(
          value: ref.watch(provider),
          columns: [
            AdminColumn(
              'Fecha',
              (o) => Text(formatDateTime(context, o.order.createdAt)),
              flex: 3,
            ),
            AdminColumn('Cliente', (o) => Text(o.customerName), flex: 3),
            AdminColumn(
              'Productos',
              (o) => Text('${o.order.lines.length}'),
              numeric: true,
            ),
            AdminColumn(
              'Total',
              (o) => Text(formatSoles(o.order.totalCents)),
              numeric: true,
            ),
            AdminColumn(
              'Estado',
              (o) => StatusBadge(
                label: o.order.status.label,
                color: orderStatusColor(o.order.status),
              ),
              flex: 3,
            ),
          ],
          rowKey: (o) => o.id,
          rowLabel: (o) =>
              'Pedido de ${o.customerName}, '
              '${formatDateTime(context, o.order.createdAt)}, '
              '${formatSoles(o.order.totalCents)}, ${o.order.status.label}',
          onRowTap: (order) => showAdminForm<void>(
            context,
            title: 'Pedido de ${order.customerName}',
            builder: (_) =>
                AdminOrderDetail(orderId: order.id, filter: _status),
          ),
          onPage: (page) => ref.read(provider.notifier).goTo(page),
          onRetry: () => ref.invalidate(provider),
          emptyText: _status == null
              ? 'Todavía no hay pedidos.'
              : 'No hay pedidos en estado "${_status!.label}".',
        ),
      ],
    );
  }
}

/// El detalle de un pedido: el cliente, las líneas y el stepper (el
/// seguimiento con las acciones del estado actual). Lee el pedido de la
/// página que lo mostró, así cada cambio se ve también en la tabla.
class AdminOrderDetail extends ConsumerStatefulWidget {
  const AdminOrderDetail({
    super.key,
    required this.orderId,
    required this.filter,
  });

  final String orderId;

  /// El filtro de la tabla de donde se abrió (el argumento de su provider).
  final OrderStatus? filter;

  @override
  ConsumerState<AdminOrderDetail> createState() => _AdminOrderDetailState();
}

class _AdminOrderDetailState extends ConsumerState<AdminOrderDetail> {
  bool _busy = false;
  String? _error;

  Future<void> _change(AdminOrder order, OrderStatus next) async {
    if (next == OrderStatus.cancelled) {
      final confirmed = await confirmAction(
        context,
        title: '¿Cancelar este pedido?',
        message:
            'El stock de sus productos vuelve al inventario. No se puede '
            'deshacer.',
        confirmLabel: 'Cancelar pedido',
      );
      if (!confirmed) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final notifier = ref.read(adminOrdersProvider(widget.filter).notifier);
    try {
      await notifier.changeStatus(order, next);
    } catch (error) {
      // Lo más común: otra persona ya lo cambió. Se trae como está ahora.
      if (mounted) {
        setState(
          () => _error = errorMessage(error, 'No se pudo cambiar el estado.'),
        );
      }
      await notifier.refresh().catchError((_) {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(adminOrdersProvider(widget.filter)).value;
    final order = page?.items
        .where((order) => order.id == widget.orderId)
        .firstOrNull;
    if (order == null) {
      return const Text('Este pedido ya no está en la lista.');
    }

    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final status = order.order.status;
    final next = status.nextStatuses;
    final advance = next.where((s) => s != OrderStatus.cancelled).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(formatDateTime(context, order.order.createdAt), style: muted),
        const SizedBox(height: 16),
        OrderTracker(status: status),
        const SizedBox(height: 16),
        if (_error case final error?) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (next.isEmpty)
          Text('Este pedido ya no cambia de estado.', style: muted)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (advance != null)
                FilledButton(
                  onPressed: _busy ? null : () => _change(order, advance),
                  child: Text(advance.actionLabel),
                ),
              if (next.contains(OrderStatus.cancelled))
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: _busy
                      ? null
                      : () => _change(order, OrderStatus.cancelled),
                  child: Text(OrderStatus.cancelled.actionLabel),
                ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        const Divider(height: 32),
        Text('Cliente', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(order.customerName),
        Text(order.customerEmail, style: muted),
        if (order.customerPhone case final phone?) Text(phone, style: muted),
        const SizedBox(height: 12),
        Text('Entrega', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(order.order.deliveryAddress),
        const Divider(height: 32),
        for (final line in order.order.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text('${line.quantity} × ${line.name}')),
                Text(formatSoles(line.totalCents)),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: Text('Total', style: theme.textTheme.titleSmall)),
            Text(
              formatSoles(order.order.totalCents),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
