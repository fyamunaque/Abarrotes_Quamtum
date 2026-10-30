import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/orders/admin_order.dart';
import '../../../admin/orders/admin_orders_providers.dart';
import '../../../common/money.dart';
import '../../../orders/fulfillment.dart';
import '../../../orders/order_status.dart';
import '../../../router/routes.dart';
import '../../../session/session_provider.dart';
import '../../../session/staff_permission.dart';
import '../../orders/order_tracker.dart';
import '../../shared/date_format.dart';
import '../../shared/error_message.dart';
import '../shared/admin_form.dart';
import '../shared/admin_page.dart';
import '../shared/admin_table.dart';
import '../shared/filter_chips.dart';
import '../shared/fulfillment_badge.dart';
import '../shared/panel_note.dart';
import '../shared/panel_tabs.dart';
import '../shared/refresh_button.dart';
import '../shared/search_field.dart';
import '../shared/status_badge.dart';
import 'order_code_dialog.dart';

/// Las dos vistas de Pedidos: todos, y los de recojo para caja.
const ordersTabs = <PanelTab>[
  (
    label: 'Todos los pedidos',
    icon: Icons.receipt_long_outlined,
    path: Routes.adminOrders,
  ),
  (
    label: 'Para recoger',
    icon: Icons.storefront_outlined,
    path: Routes.adminPickup,
  ),
];

/// Los pedidos de todos los clientes, filtrados por estado y por tipo de
/// entrega, o buscados por su número. Tocar uno abre su detalle, con el stepper para avanzarlo o
/// cancelarlo (con `orders.updateStatus`). Quién lo hizo, solo con
/// `customers.view`.
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  /// Cada cuánto se vuelve a pedir la página mientras la pantalla está
  /// abierta.
  static const autoRefreshEvery = Duration(seconds: 30);

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  AdminOrdersFilter _filter = allOrders;
  final _number = TextEditingController();
  Timer? _debounce;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    // Los pedidos nuevos aparecen solos, sin tocar "Actualizar". Si falla,
    // la tabla queda como estaba hasta la próxima vuelta.
    _autoRefresh = Timer.periodic(
      AdminOrdersScreen.autoRefreshEvery,
      (_) => ref
          .read(adminOrdersProvider(_filter).notifier)
          .refresh()
          .catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _debounce?.cancel();
    _number.dispose();
    super.dispose();
  }

  /// Busca cuando se deja de escribir, no con cada número.
  void _onNumber(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final number = int.tryParse(text);
      if (number == _filter.number) return;
      setState(() => _filter = _with(number: number));
    });
  }

  void _clearNumber() {
    _debounce?.cancel();
    _number.clear();
    setState(() => _filter = _with(number: null));
  }

  /// [_filter] con [number] cambiado (null: sin buscar).
  AdminOrdersFilter _with({required int? number}) => (
    status: _filter.status,
    fulfillmentType: _filter.fulfillmentType,
    number: number,
  );

  @override
  Widget build(BuildContext context) {
    final provider = adminOrdersProvider(_filter);
    final status = _filter.status;
    final type = _filter.fulfillmentType;
    final canSeeCustomers = ref
        .watch(permissionsProvider)
        .contains(StaffPermission.customersView);
    return AdminPage(
      title: 'Pedidos',
      actions: [RefreshButton(onRefresh: ref.read(provider.notifier).refresh)],
      children: [
        const PanelTabs(tabs: ordersTabs, current: Routes.adminOrders),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < PanelSearchField.narrowBelow;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: narrow ? constraints.maxWidth : 240,
                  child: PanelSearchField(
                    controller: _number,
                    label: 'Buscar por N.º',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _onNumber,
                    onClear: _clearNumber,
                  ),
                ),
                SizedBox(
                  width: narrow ? constraints.maxWidth : 260,
                  child: _StatusFilter(
                    value: status,
                    onChanged: (status) => setState(
                      () => _filter = (
                        status: status,
                        fulfillmentType: type,
                        number: _filter.number,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _FilterRow(
          label: 'Entrega',
          child: FilterChips<FulfillmentType?>(
            options: [
              (null, 'Domicilio y recojo'),
              for (final type in FulfillmentType.values)
                (type, FulfillmentBadge.label(type)),
            ],
            selected: type,
            onSelected: (type) => setState(
              () => _filter = (
                status: status,
                fulfillmentType: type,
                number: _filter.number,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AdminTable<AdminOrder>(
          value: ref.watch(provider),
          columns: [
            AdminColumn(
              'N.º',
              (o) => Text(switch (o.order.number) {
                final number? => '$number',
                null => '—',
              }),
              flex: 1,
            ),
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
              'Entrega',
              (o) => FulfillmentBadge(o.order.fulfillmentType),
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
              '${formatSoles(o.order.totalCents)}, '
              '${FulfillmentBadge.label(o.order.fulfillmentType)}, '
              '${o.order.statusLabel}',
          onRowTap: (order) => showAdminForm<void>(
            context,
            title: _title(order),
            builder: (_) =>
                AdminOrderDetail(orderId: order.id, filter: _filter),
          ),
          onPage: (page) => ref.read(provider.notifier).goTo(page),
          onRetry: () => ref.invalidate(provider),
          emptyText: switch ((status, type, _filter.number)) {
            (null, null, null) => 'Todavía no hay pedidos.',
            (null, null, final number?) =>
              'No hay un pedido con el N.º $number.',
            (_, _, final number?) =>
              'El pedido N.º $number no coincide con los filtros.',
            (final status?, null, null) =>
              'No hay pedidos en estado "${status.label}".',
            _ => 'Ningún pedido coincide con los filtros.',
          },
        ),
      ],
    );
  }
}

/// Una fila de chips con su nombre adelante. Si los chips bajan a otra
/// línea, el nombre queda a la altura de la primera.
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 68,
          // El alto de un chip, con su área táctil.
          height: kMinInteractiveDimension,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// El estado de los pedidos que se muestran: "Todos" o uno, cada uno con su
/// punto de color, como en la tabla.
class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.value, required this.onChanged});

  final OrderStatus? value;
  final ValueChanged<OrderStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<OrderStatus?>(
      style: Theme.of(context).textTheme.bodyLarge,
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Estado'),
      items: [
        const DropdownMenuItem(child: Text('Todos')),
        for (final status in OrderStatus.values)
          DropdownMenuItem(
            value: status,
            child: StatusBadge(
              label: status.label,
              color: orderStatusColor(status),
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// "Pedido N.º 1024 de Ana Quispe", o "Pedido N.º 1024" sin los datos del
/// cliente.
String _title(AdminOrder order) => switch (order.customer) {
  final customer? => '${order.order.title} de ${customer.name}',
  null => order.order.title,
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
  final AdminOrdersFilter filter;

  @override
  ConsumerState<AdminOrderDetail> createState() => _AdminOrderDetailState();
}

class _AdminOrderDetailState extends ConsumerState<AdminOrderDetail> {
  bool _busy = false;
  String? _error;

  Future<void> _change(AdminOrder order, OrderStatus next) async {
    final notifier = ref.read(adminOrdersProvider(widget.filter).notifier);
    final type = order.order.fulfillmentType;
    // Entregarlo: el código que da el cliente (el de recojo en caja, el de
    // entrega al repartidor; los pedidos a domicilio de antes no tienen).
    // Si no coincide, el diálogo lo dice y deja volver a escribirlo.
    final needsCode = switch (type) {
      FulfillmentType.pickup => true,
      FulfillmentType.delivery => order.order.hasDeliveryCode,
    };
    if (next == OrderStatus.delivered && needsCode) {
      // Sin el código, solo quien administra la tienda (el servidor lo
      // vuelve a revisar).
      final canSkipCode =
          type == FulfillmentType.delivery &&
          ref.read(permissionsProvider).contains(StaffPermission.staffManage);
      setState(() => _error = null);
      await showOrderCodeDialog(
        context,
        type: type,
        onSubmit: (code) => notifier.changeStatus(order, next, code: code),
        onDeliverWithoutCode: canSkipCode
            ? (reason) =>
                  notifier.changeStatus(order, next, withoutCodeReason: reason)
            : null,
      );
      return;
    }
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
          if (customer.dni case final dni?) Text('DNI $dni', style: muted),
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
        ] else ...[
          Text(order.order.deliveryAddress ?? '—'),
          if (order.order.deliveredWithoutCodeReason case final reason?)
            Text('Entregado sin código: $reason', style: muted),
        ],
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
