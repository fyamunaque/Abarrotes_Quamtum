import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/orders/admin_order.dart';
import '../../../admin/orders/admin_orders_providers.dart';
import '../../../common/money.dart';
import '../../../orders/order_status.dart';
import '../../../router/routes.dart';
import '../../../session/session_provider.dart';
import '../../../session/staff_permission.dart';
import '../../orders/order_tracker.dart';
import '../../shared/date_format.dart';
import '../../shared/error_message.dart';
import '../shared/admin_page.dart';
import '../shared/panel_note.dart';
import '../shared/panel_tabs.dart';
import '../shared/refresh_button.dart';
import '../shared/search_field.dart';
import '../shared/status_badge.dart';
import 'admin_orders_screen.dart';
import 'pickup_code_dialog.dart';

/// Para caja (con `orders.view`): los pedidos de recojo que se preparan o
/// esperan a su cliente, con el código en grande y cuánto hace que están
/// listos. Se busca por el código que dicta el cliente o por su nombre (si
/// el rol ve los datos de los clientes). Con `orders.updateStatus`, el botón
/// del paso siguiente; entregar pide el código.
class AdminPickupScreen extends ConsumerStatefulWidget {
  const AdminPickupScreen({super.key});

  /// Cada cuánto se vuelve a pedir la lista (y se actualiza "hace X min").
  static const autoRefreshEvery = Duration(seconds: 30);

  @override
  ConsumerState<AdminPickupScreen> createState() => _AdminPickupScreenState();
}

class _AdminPickupScreenState extends ConsumerState<AdminPickupScreen> {
  final _search = TextEditingController();
  Timer? _autoRefresh;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _autoRefresh = Timer.periodic(AdminPickupScreen.autoRefreshEvery, (_) {
      ref
          .read(pickupQueueProvider.notifier)
          .refresh()
          .catchError((Object _) {});
      // Aunque falle, el tiempo transcurrido avanza.
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(pickupQueueProvider);
    final notifier = ref.read(pickupQueueProvider.notifier);
    return AdminPage(
      title: 'Pedidos',
      actions: [RefreshButton(onRefresh: notifier.refresh)],
      children: [
        const PanelTabs(tabs: ordersTabs, current: Routes.adminPickup),
        const SizedBox(height: 16),
        const PanelNote(
          'Los pedidos de recojo que se preparan o esperan en la tienda. '
          'Busca por el código que te dice el cliente o por su nombre.',
        ),
        const SizedBox(height: 16),
        PanelSearchField(
          controller: _search,
          label: 'Buscar por código o nombre',
          width: 360,
          textCapitalization: TextCapitalization.characters,
          onChanged: (text) => setState(() => _query = text),
          onClear: () => setState(() {
            _search.clear();
            _query = '';
          }),
        ),
        const SizedBox(height: 16),
        switch (queue) {
          AsyncValue(value: final orders?) => _Tickets(
            [
              for (final order in orders)
                if (matchesPickupSearch(order, _query)) order,
            ],
            empty: orders.isEmpty
                ? 'No hay pedidos de recojo en preparación ni en espera.'
                : 'Ningún pedido coincide con la búsqueda.',
          ),
          AsyncError(:final error) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    errorMessage(error, 'No se pudieron cargar los pedidos.'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(pickupQueueProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          _ => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }
}

/// Si [order] coincide con lo buscado: el código (sin espacios ni
/// mayúsculas) o el nombre del cliente (sin tildes ni mayúsculas).
bool matchesPickupSearch(AdminOrder order, String query) {
  final text = _fold(query.trim());
  if (text.isEmpty) return true;
  final code = order.order.pickupCode?.toLowerCase() ?? '';
  final name = _fold(order.customer?.name ?? '');
  return code.contains(text.replaceAll(' ', '')) || name.contains(text);
}

/// En minúsculas, sin tildes y con la ñ como n, para comparar nombres
/// (en caja se escribe rápido).
String _fold(String text) {
  const from = 'áéíóúüàèìòùñ';
  const to = 'aeiouuaeioun';
  final lower = text.toLowerCase();
  return String.fromCharCodes([
    for (final char in lower.runes)
      switch (from.indexOf(String.fromCharCode(char))) {
        -1 => char,
        final i => to.codeUnitAt(i),
      },
  ]);
}

class _Tickets extends StatelessWidget {
  const _Tickets(this.orders, {required this.empty});

  final List<AdminOrder> orders;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(empty, textAlign: TextAlign.center),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final order in orders)
          Padding(
            key: ValueKey(order.id),
            padding: const EdgeInsets.only(bottom: 12),
            child: _Ticket(order),
          ),
      ],
    );
  }
}

/// Un pedido para caja: el código en grande, el estado, quién lo hizo,
/// cuánto hace que está listo y el botón del paso siguiente.
class _Ticket extends ConsumerStatefulWidget {
  const _Ticket(this.order);

  final AdminOrder order;

  @override
  ConsumerState<_Ticket> createState() => _TicketState();
}

class _TicketState extends ConsumerState<_Ticket> {
  bool _busy = false;

  Future<void> _advance(OrderStatus next) async {
    final notifier = ref.read(pickupQueueProvider.notifier);
    final order = widget.order;
    if (next == OrderStatus.delivered) {
      final delivered = await showPickupCodeDialog(
        context,
        onSubmit: (code) =>
            notifier.changeStatus(order, next, pickupCode: code),
      );
      if (delivered && mounted) {
        _notify('Entregaste el pedido ${order.order.pickupCode}.');
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await notifier.changeStatus(order, next);
      if (mounted) {
        _notify(
          'El pedido ${order.order.pickupCode} está '
          '${order.order.fulfillmentType.labelOf(next).toLowerCase()}.',
        );
      }
    } catch (error) {
      if (mounted) {
        // Lo más común: otra persona ya lo cambió.
        await showRejected(
          context,
          title: 'No se pudo cambiar el pedido',
          message: errorMessage(error, 'No se pudo cambiar el estado.'),
        );
        await notifier.refresh().catchError((Object _) {});
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order.order;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final canUpdate = ref
        .watch(permissionsProvider)
        .contains(StaffPermission.ordersUpdateStatus);
    final next = order.allowedNextStatuses
        .where((status) => status != OrderStatus.cancelled)
        .firstOrNull;
    final readyAt = order.readyForPickupAt;
    final waiting =
        order.status == OrderStatus.readyForPickup && readyAt != null
        ? 'Listo ${formatElapsed(readyAt, DateTime.now())}'
        : 'Pedido ${formatElapsed(order.createdAt, DateTime.now())}';
    final code = order.pickupCode ?? '—';

    final info = MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                label: 'Código ${code.split('').join(' ')}',
                child: ExcludeSemantics(
                  child: Text(
                    code,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
              StatusBadge(
                label: order.statusLabel,
                color: orderStatusColor(order.status),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(waiting, style: muted),
          Text(
            [
              ?widget.order.customer?.name,
              formatSoles(order.totalCents),
            ].join(' · '),
            style: muted,
          ),
        ],
      ),
    );
    final action = canUpdate && next != null
        ? FilledButton(
            onPressed: _busy ? null : () => _advance(next),
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(order.fulfillmentType.actionLabelOf(next)),
          )
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        // El botón a la derecha; si no hay ancho, debajo.
        child: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 520
              ? Row(
                  children: [
                    Expanded(child: info),
                    ?action,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    info,
                    if (action != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: action,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
