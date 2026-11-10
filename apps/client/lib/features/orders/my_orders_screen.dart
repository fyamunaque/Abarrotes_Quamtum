import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/money.dart';
import '../../orders/fulfillment.dart';
import '../../orders/order.dart';
import '../../orders/order_filter.dart';
import '../../orders/order_status.dart';
import '../../orders/orders_providers.dart';
import '../../router/routes.dart';
import '../../theme/neils_theme.dart';
import '../shared/brand.dart';
import '../shared/date_format.dart';
import '../shared/dates_filter.dart';
import '../shared/error_message.dart';
import '../shared/filter_chips.dart';
import '../shared/info_line.dart';
import '../shared/store_details.dart';
import 'order_lines.dart';
import 'order_tracker.dart';
import '../../theme/palette.dart';

/// Los pedidos de la cuenta, cada uno con su seguimiento, con la búsqueda
/// (N.º o producto) y los filtros por estado, entrega y fechas. Con
/// [newOrderId] (al venir de confirmar), un aviso de que el pedido llegó.
///
/// Desde [sideBySideFrom], la lista a la izquierda y el pedido elegido (al
/// principio, el primero) a la derecha; más angosto, los pedidos uno debajo
/// del otro.
class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key, this.newOrderId});

  final String? newOrderId;

  static const sideBySideFrom = 1100.0;

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  MyOrdersFilter _filter = allMyOrders;

  /// El pedido elegido en la lista (lado a lado); sin elegir, el primero.
  String? _chosenId;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _update({
    String? search,
    OrderProgress? Function()? progress,
    FulfillmentType? Function()? fulfillmentType,
    (DateTime?, DateTime?)? dates,
  }) => setState(
    () => _filter = (
      search: search ?? _filter.search,
      progress: progress == null ? _filter.progress : progress(),
      fulfillmentType: fulfillmentType == null
          ? _filter.fulfillmentType
          : fulfillmentType(),
      from: dates == null ? _filter.from : dates.$1,
      to: dates == null ? _filter.to : dates.$2,
    ),
  );

  /// Busca cuando se deja de escribir, no con cada letra.
  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (text.trim() != _filter.search) _update(search: text.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    _update(search: '');
  }

  void _clearFilters() {
    _debounce?.cancel();
    _search.clear();
    setState(() => _filter = allMyOrders);
  }

  @override
  Widget build(BuildContext context) {
    final provider = myOrdersProvider(_filter);
    final orders = ref.watch(provider);
    final newOrderId = widget.newOrderId;
    final sideBySide =
        MediaQuery.sizeOf(context).width >= MyOrdersScreen.sideBySideFrom;
    return PublicScaffold(
      title: 'Mis pedidos',
      maxWidth: sideBySide ? 1120 : 720,
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
                    ? () => _showErrors(ref.read(provider.notifier).refresh())
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
          _Filters(
            search: _search,
            filter: _filter,
            onSearch: _onSearch,
            onClearSearch: _clearSearch,
            onProgress: (progress) => _update(progress: () => progress),
            onFulfillmentType: (type) => _update(fulfillmentType: () => type),
            onDates: (from, to) => _update(dates: (from, to)),
          ),
          const SizedBox(height: 16),
          // Mientras recarga se sigue viendo la lista anterior.
          switch (orders) {
            AsyncValue(value: final list?)
                when list.items.isEmpty && _filter != allMyOrders =>
              _NoMatches(onClear: _clearFilters),
            AsyncValue(value: final list?) when list.items.isEmpty =>
              const _NoOrders(),
            AsyncValue(value: final list?) => () {
              final more = list.hasMore
                  ? Center(
                      child: list.loadingMore
                          ? const CircularProgressIndicator()
                          : OutlinedButton(
                              onPressed: () => _showErrors(
                                ref.read(provider.notifier).loadMore(),
                              ),
                              child: const Text('Ver más pedidos'),
                            ),
                    )
                  : null;
              if (!sideBySide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final order in list.items) ...[
                      _OrderCard(order, key: ValueKey(order.id)),
                      const SizedBox(height: 16),
                    ],
                    ?more,
                  ],
                );
              }
              final chosen = list.items.firstWhere(
                (order) => order.id == _chosenId,
                orElse: () => list.items.first,
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 380,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _OrderList(
                          list.items,
                          chosenId: chosen.id,
                          onChoose: (id) => setState(() => _chosenId = id),
                        ),
                        if (more != null) ...[const SizedBox(height: 16), more],
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: KeyedSubtree(
                      key: const ValueKey('pedido-elegido'),
                      child: _OrderCard(chosen, key: ValueKey(chosen.id)),
                    ),
                  ),
                ],
              );
            }(),
            AsyncError(:final error) => Column(
              children: [
                Text(
                  errorMessage(error, 'No se pudieron cargar tus pedidos.'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(provider),
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

  Future<void> _showErrors(Future<void> action) async {
    try {
      await action;
    } catch (error) {
      if (mounted) {
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

/// "Buscar por N.º o producto", los chips de estado y de entrega, y las
/// fechas. En el teléfono los chips se deslizan de lado.
class _Filters extends StatelessWidget {
  const _Filters({
    required this.search,
    required this.filter,
    required this.onSearch,
    required this.onClearSearch,
    required this.onProgress,
    required this.onFulfillmentType,
    required this.onDates,
  });

  final TextEditingController search;
  final MyOrdersFilter filter;
  final ValueChanged<String> onSearch;
  final VoidCallback onClearSearch;
  final ValueChanged<OrderProgress?> onProgress;
  final ValueChanged<FulfillmentType?> onFulfillmentType;
  final void Function(DateTime? from, DateTime? to) onDates;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: search,
          decoration: InputDecoration(
            labelText: 'Buscar por N.º o producto',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: ListenableBuilder(
              listenable: search,
              builder: (_, _) => search.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'Borrar la búsqueda',
                      icon: const Icon(Icons.close),
                      onPressed: onClearSearch,
                    ),
            ),
          ),
          textInputAction: TextInputAction.search,
          onChanged: onSearch,
        ),
        const SizedBox(height: 12),
        FilterChips<OrderProgress?>(
          options: [
            (null, 'Todos'),
            for (final progress in OrderProgress.values)
              (progress, progress.label),
          ],
          selected: filter.progress,
          onSelected: onProgress,
        ),
        const SizedBox(height: 8),
        FilterChips<FulfillmentType?>(
          options: const [
            (null, 'Domicilio y recojo'),
            (FulfillmentType.delivery, 'Domicilio'),
            (FulfillmentType.pickup, 'Recojo'),
          ],
          selected: filter.fulfillmentType,
          onSelected: onFulfillmentType,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: DatesFilter(
            from: filter.from,
            to: filter.to,
            helpText: 'Pedidos entre',
            onChanged: onDates,
          ),
        ),
      ],
    );
  }
}

/// Con la búsqueda o los filtros, ningún pedido: "Quitar filtros" vuelve a
/// todos.
class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            'Ningún pedido coincide con la búsqueda.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onClear,
            child: const Text('Quitar filtros'),
          ),
        ],
      ),
    );
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
          border: Border.all(color: context.palette.positive),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: context.palette.positive),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(switch (order?.number) {
                      final number? =>
                        'Recibimos tu pedido N.º $number. La tienda lo va a '
                            'confirmar.',
                      null =>
                        'Recibimos tu pedido. La tienda lo va a confirmar.',
                    }, style: theme.textTheme.bodyLarge),
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
                      // El total de la línea si el carrito tenía la
                      // cotización; si no, el precio por unidad.
                      for (final change in order.priceChanges)
                        Text(switch (change) {
                          PriceChange(
                            shownLineTotalCents: final shown?,
                            lineTotalCents: final charged?,
                          ) =>
                            '${change.name}: ${formatSoles(shown)} → '
                                '${formatSoles(charged)}',
                          _ =>
                            '${change.name}: '
                                '${formatSoles(change.shownUnitPriceCents ?? 0)} → '
                                '${formatSoles(change.unitPriceCents ?? 0)}',
                        }, style: muted),
                    ],
                    if (order != null)
                      for (final notice in order.notices) ...[
                        const SizedBox(height: 4),
                        Text(notice, style: muted),
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

/// La lista de lado a lado: un bloque con una fila por pedido (el número,
/// la fecha y el estado, y el total); la elegida, en el tono de lo
/// seleccionado.
class _OrderList extends StatelessWidget {
  const _OrderList(
    this.orders, {
    required this.chosenId,
    required this.onChoose,
  });

  final List<Order> orders;
  final String chosenId;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Material(
      key: const ValueKey('lista-de-pedidos'),
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, order) in orders.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: palette.line),
            ListTile(
              selected: order.id == chosenId,
              selectedTileColor: palette.brandTint,
              onTap: () => onChoose(order.id),
              title: Text(order.title, style: text.titleSmall),
              subtitle: Text(
                '${formatDateTime(context, order.createdAt)} · '
                '${order.fulfillmentType.labelOf(order.status)}',
              ),
              trailing: Text(
                formatSoles(order.totalCents),
                style: NeilsText.price(fontSize: 16),
              ),
            ),
          ],
        ],
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
                // El número, para nombrarlo si se llama a la tienda.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.title, style: theme.textTheme.titleMedium),
                      Text(
                        date,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
            switch (order.fulfillmentType) {
              FulfillmentType.pickup => _PickupDetails(order),
              FulfillmentType.delivery => _DeliveryDetails(order),
            },
            const SizedBox(height: 16),
            OrderLines(order: order),
          ],
        ),
      ),
    );
  }
}

/// Un pedido a domicilio: adónde va, en el mismo lugar que los datos de la
/// tienda en uno de recojo, y mientras está en curso, el código en grande
/// para dárselo al repartidor. Ya entregado o cancelado, en una línea tenue.
class _DeliveryDetails extends StatelessWidget {
  const _DeliveryDetails(this.order);

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = order.deliveryAddress ?? '—';
    if (order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled) {
      return Text(
        'Entrega en $address',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (order.deliveryCode case final code?) ...[
          _OrderCode(
            code,
            title: 'Tu código de entrega',
            hint: 'Dáselo al repartidor cuando recibas tu pedido.',
          ),
          const SizedBox(height: 12),
        ],
        Text('Entrega a domicilio', style: theme.textTheme.titleSmall),
        InfoLine(icon: Icons.place_outlined, text: address),
      ],
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
          _OrderCode(
            code,
            title: 'Tu código de recojo',
            hint: 'Muéstralo en caja al recoger tu pedido.',
          ),
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

/// El código de recojo o de entrega, en grande y bien visible, para
/// enseñarlo en caja o dárselo al repartidor. El lector de pantalla lo
/// deletrea.
class _OrderCode extends StatelessWidget {
  const _OrderCode(this.code, {required this.title, required this.hint});

  final String code;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Semantics(
      container: true,
      label: '$title: ${code.split('').join(' ')}',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: palette.inkMuted,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    code,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: palette.ink,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                  ),
                ),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.inkMuted,
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
          border: Border.all(color: context.palette.statusReady, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: context.palette.statusReady,
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
