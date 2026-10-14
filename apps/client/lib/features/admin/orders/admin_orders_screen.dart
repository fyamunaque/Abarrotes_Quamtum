import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/orders/admin_order.dart';
import '../../../admin/orders/admin_orders_providers.dart';
import '../../../common/money.dart';
import '../../../orders/fulfillment.dart';
import '../../../orders/order_status.dart';
import '../../../session/session_provider.dart';
import '../../../session/staff_permission.dart';
import '../../orders/order_tracker.dart';
import '../../shared/date_format.dart';
import '../../shared/error_message.dart';
import '../shared/admin_form.dart';
import '../shared/admin_page.dart';
import '../shared/admin_table.dart';
import '../shared/filter_chips.dart';
import '../shared/panel_note.dart';
import '../shared/refresh_button.dart';
import '../shared/status_badge.dart';

/// Los pedidos de todos los clientes, filtrados por estado. Tocar uno abre su
/// detalle, con el stepper para avanzarlo o cancelarlo (con
/// `orders.updateStatus`). Quién lo hizo, solo con `customers.view`.
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  /// Cada cuánto se vuelve a pedir la página mientras la pantalla está
  /// abierta.
  static const autoRefreshEvery = Duration(seconds: 30);

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  OrderStatus? _status;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    // Los pedidos nuevos aparecen solos, sin tocar "Actualizar". Si falla,
    // la tabla queda como estaba hasta la próxima vuelta.
    _autoRefresh = Timer.periodic(
      AdminOrdersScreen.autoRefreshEvery,
      (_) => ref
          .read(adminOrdersProvider(_status).notifier)
          .refresh()
          .catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminOrdersProvider(_status);
    final canSeeCustomers = ref
        .watch(permissionsProvider)
        .contains(StaffPermission.customersView);
    return AdminPage(
      title: 'Pedidos',
      actions: [RefreshButton(onRefresh: ref.read(provider.notifier).refresh)],
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
            if (canSeeCustomers)
              AdminColumn(
                'Cliente',
                (o) => Text(o.customer?.name ?? '—'),
                flex: 3,
              ),
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
                label: o.order.statusLabel,
                color: orderStatusColor(o.order.status),
              ),
              flex: 3,
            ),
          ],
          rowKey: (o) => o.id,
          rowLabel: (o) =>
              '${_title(o)}, '
              '${formatDateTime(context, o.order.createdAt)}, '
              '${formatSoles(o.order.totalCents)}, ${o.order.statusLabel}',
          onRowTap: (order) => showAdminForm<void>(
            context,
            title: _title(order),
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

/// "Pedido de Ana Quispe", o solo "Pedido" sin los datos del cliente.
String _title(AdminOrder order) => switch (order.customer) {
  final customer? => 'Pedido de ${customer.name}',
  null => 'Pedido',
};

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
    // Recoger en caja: el código que muestra el cliente.
    String? pickupCode;
    if (order.order.fulfillmentType == FulfillmentType.pickup &&
        next == OrderStatus.delivered) {
      pickupCode = await showDialog<String>(
        context: context,
        builder: (_) => const _PickupCodeDialog(),
      );
      if (pickupCode == null) return;
    }
    if (!mounted) return;
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
      await notifier.changeStatus(order, next, pickupCode: pickupCode);
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
    final type = order.order.fulfillmentType;
    // Lo calcula el servidor con el flujo del tipo de entrega.
    final next = order.order.allowedNextStatuses;
    final advance = next.where((s) => s != OrderStatus.cancelled).firstOrNull;
    final permissions = ref.watch(permissionsProvider);
    final canUpdate = permissions.contains(StaffPermission.ordersUpdateStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(formatDateTime(context, order.order.createdAt), style: muted),
        const SizedBox(height: 16),
        OrderTracker(status: status, fulfillmentType: type),
        const SizedBox(height: 16),
        if (_error case final error?) ...[
          FormError(error),
          const SizedBox(height: 12),
        ],
        if (next.isEmpty)
          Text('Este pedido ya no cambia de estado.', style: muted)
        else if (!canUpdate)
          const PanelNote(
            'Tu rol puede ver los pedidos, pero no cambiar su estado.',
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (advance != null)
                FilledButton(
                  onPressed: _busy ? null : () => _change(order, advance),
                  child: Text(type.actionLabelOf(advance)),
                ),
              if (next.contains(OrderStatus.cancelled))
                DestructiveButton(
                  label: OrderStatus.cancelled.actionLabel,
                  onPressed: _busy
                      ? null
                      : () => _change(order, OrderStatus.cancelled),
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
        if (order.customer case final customer?) ...[
          Text(customer.name),
          Text(customer.email, style: muted),
          if (customer.phone case final phone?) Text(phone, style: muted),
        ] else
          Text(
            'Tu rol no incluye ver los datos de los clientes.',
            style: muted,
          ),
        const SizedBox(height: 12),
        Text('Entrega', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        if (type == FulfillmentType.pickup) ...[
          const Text('Recojo en tienda'),
          if (order.order.pickupCode case final code?)
            Text('Código $code', style: muted),
        ] else
          Text(order.order.deliveryAddress ?? '—'),
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

/// Pide el código de recojo que muestra el cliente en caja. Devuelve lo que
/// se escribió, o null si se volvió atrás. El servidor lo compara (sin
/// espacios y sin importar mayúsculas) y responde 400 si no coincide.
class _PickupCodeDialog extends StatefulWidget {
  const _PickupCodeDialog();

  @override
  State<_PickupCodeDialog> createState() => _PickupCodeDialogState();
}

class _PickupCodeDialogState extends State<_PickupCodeDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _code.text.trim();
    if (code.isNotEmpty) Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Entregar el pedido'),
      content: TextField(
        controller: _code,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Código de recojo',
          helperText: 'El que muestra el cliente.',
        ),
        textCapitalization: TextCapitalization.characters,
        autocorrect: false,
        maxLength: 6,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        ListenableBuilder(
          listenable: _code,
          builder: (_, _) => FilledButton(
            onPressed: _code.text.trim().isEmpty ? null : _submit,
            child: const Text('Marcar recogido'),
          ),
        ),
      ],
    );
  }
}
