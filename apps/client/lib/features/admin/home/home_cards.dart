import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../admin/stats/stats.dart';
import '../../../admin/stats/stats_providers.dart';
import '../../../common/days.dart';
import '../../../common/money.dart';
import '../../../orders/fulfillment.dart';
import '../../../orders/order_status.dart';
import '../../../router/routes.dart';
import '../../../session/session_provider.dart';
import '../../../theme/brand_colors.dart';
import '../../orders/order_tracker.dart';
import '../../shared/error_message.dart';
import 'sales_chart.dart';

/// Una tarjeta del inicio con su propio reporte: si ese reporte falla, solo
/// ella muestra el error y "Reintentar"; el resto del inicio se ve igual.
class HomeCard<T> extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.title,
    required this.value,
    required this.onRetry,
    required this.builder,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? Function(T data)? subtitle;
  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = value.value;
    final sub = data == null ? null : subtitle?.call(data);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(title, style: theme.textTheme.titleMedium),
                      ),
                      if (sub != null)
                        Text(
                          sub,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 12),
            switch (value) {
              AsyncValue(value: final data?) => builder(context, data),
              AsyncError(:final error) => Column(
                children: [
                  Text(
                    errorMessage(error, 'No se pudo cargar.'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
              _ => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ],
        ),
      ),
    );
  }
}

/// Ventas de hoy, la semana y el mes, el ticket promedio, y los pedidos por
/// estado y por tipo de entrega.
class KpiSection extends ConsumerWidget {
  const KpiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(overviewProvider)) {
      AsyncValue(value: final overview?) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveGrid(
            // De a 2 en un teléfono, de a 4 en escritorio.
            minWidth: 160,
            maxColumns: 4,
            children: [
              _StatTile('Ventas de hoy', overview.today),
              _StatTile('Ventas de la semana', overview.week),
              _StatTile('Ventas del mes', overview.month),
              _StatTile.averageTicket(overview.month),
            ],
          ),
          const SizedBox(height: 12),
          _OrdersByStatus(overview.ordersByStatus),
          const SizedBox(height: 12),
          _OrdersByFulfillment(overview.ordersByFulfillment),
        ],
      ),
      AsyncError(:final error) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(errorMessage(error, 'No se pudo cargar el resumen.')),
              TextButton(
                onPressed: () => ref.invalidate(overviewProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _StatTile extends StatelessWidget {
  _StatTile(this.label, SalesSummary summary)
    : value = formatSoles(summary.totalCents),
      detail = _orders(summary.orders);

  _StatTile.averageTicket(SalesSummary month)
    : label = 'Ticket promedio del mes',
      value = formatSoles(month.averageTicketCents),
      detail = 'en ${_orders(month.orders)}';

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text(value, style: theme.textTheme.headlineSmall),
              Text(detail, style: muted),
            ],
          ),
        ),
      ),
    );
  }
}

String _orders(int count) => count == 1 ? '1 pedido' : '$count pedidos';

/// Cuántos pedidos son a domicilio y cuántos de recojo en tienda, con su
/// parte del total.
class _OrdersByFulfillment extends StatelessWidget {
  const _OrdersByFulfillment(this.counts);

  final Map<FulfillmentType, int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = counts.values.fold(0, (sum, count) => sum + count);
    String share(int count) =>
        total == 0 ? '' : ' (${(count * 100 / total).round()} %)';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Pedidos por tipo de entrega',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                for (final type in FulfillmentType.values)
                  MergeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          switch (type) {
                            FulfillmentType.delivery =>
                              Icons.local_shipping_outlined,
                            FulfillmentType.pickup => Icons.storefront_outlined,
                          },
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            type.label,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${counts[type] ?? 0}${share(counts[type] ?? 0)}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Si la cuenta puede abrir [path]: los enlaces a otra sección solo salen
/// con su permiso.
bool _canOpen(WidgetRef ref, String path) =>
    Routes.allows(ref.watch(permissionsProvider), path);

/// Cuántos pedidos hay en cada estado: el punto con su color, el nombre y el
/// número (el color nunca va solo). Lleva a la lista de pedidos.
class _OrdersByStatus extends ConsumerWidget {
  const _OrdersByStatus(this.counts);

  final Map<OrderStatus, int> counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Pedidos por estado',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                if (_canOpen(ref, Routes.adminOrders))
                  TextButton(
                    onPressed: () => context.go(Routes.adminOrders),
                    child: const Text('Ver pedidos'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                for (final status in OrderStatus.values)
                  MergeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: orderStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // En un teléfono angosto el nombre se parte en dos
                        // líneas en vez de salirse de la tarjeta.
                        Flexible(
                          child: Text(
                            status.label,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${counts[status] ?? 0}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Las ventas de 30 días: el gráfico, o la tabla con el valor de cada día.
class SalesCard extends ConsumerStatefulWidget {
  const SalesCard({super.key});

  @override
  ConsumerState<SalesCard> createState() => _SalesCardState();
}

class _SalesCardState extends ConsumerState<SalesCard> {
  bool _table = false;

  @override
  Widget build(BuildContext context) {
    String summary(SalesReport report) =>
        '${formatSoles(report.summary.totalCents)} en '
        '${_orders(report.summary.orders)}';
    return HomeCard<SalesReport>(
      title: 'Ventas de los últimos 30 días',
      subtitle: summary,
      value: ref.watch(salesProvider),
      onRetry: () => ref.invalidate(salesProvider),
      action: TextButton(
        onPressed: () => setState(() => _table = !_table),
        child: Text(_table ? 'Ver el gráfico' : 'Ver los datos'),
      ),
      builder: (context, report) => _table
          ? _SalesTable(report.daily)
          : SizedBox(
              height: 240,
              child: SalesChart(
                daily: report.daily,
                semanticSummary:
                    'Ventas de los últimos 30 días: ${summary(report)}. '
                    'Para el detalle por día, "Ver los datos".',
              ),
            ),
    );
  }
}

class _SalesTable extends StatelessWidget {
  const _SalesTable(this.daily);

  final List<DailySales> daily;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final header = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    Widget row(List<Widget> cells) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: cells[0]),
          Expanded(
            flex: 2,
            child: Align(alignment: Alignment.centerRight, child: cells[1]),
          ),
          Expanded(
            flex: 2,
            child: Align(alignment: Alignment.centerRight, child: cells[2]),
          ),
        ],
      ),
    );
    return Column(
      children: [
        row([
          Text('Día', style: header),
          Text('Pedidos', style: header),
          Text('Ventas', style: header),
        ]),
        const Divider(),
        // El más reciente primero.
        for (final day in daily.reversed)
          MergeSemantics(
            child: row([
              Text(localizations.formatMediumDate(parseDay(day.date))),
              Text('${day.orders}'),
              Text(formatSoles(day.totalCents)),
            ]),
          ),
      ],
    );
  }
}

/// Productos con el stock en su mínimo o por debajo.
class LowStockCard extends ConsumerWidget {
  const LowStockCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HomeCard<List<LowStockItem>>(
      title: 'Stock bajo',
      subtitle: (items) => items.isEmpty ? null : _products(items.length),
      value: ref.watch(lowStockProvider),
      onRetry: () => ref.invalidate(lowStockProvider),
      action: _canOpen(ref, Routes.adminInventory)
          ? TextButton(
              onPressed: () => context.go(Routes.adminInventory),
              child: const Text('Inventario'),
            )
          : null,
      builder: (context, items) => items.isEmpty
          ? const Text('Todo el stock está sobre su mínimo.')
          : _ItemList([
              for (final item in items)
                (
                  item.name,
                  item.currentStock == 0
                      ? 'Agotado (mínimo ${item.minStock})'
                      : '${item.currentStock} de ${item.minStock} como mínimo',
                ),
            ]),
    );
  }
}

/// Productos con stock que vencen en los próximos 7 días (o ya vencieron).
class ExpiringCard extends ConsumerWidget {
  const ExpiringCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = MaterialLocalizations.of(context);
    return HomeCard<List<ExpiringItem>>(
      title: 'Por vencer en 7 días',
      subtitle: (items) => items.isEmpty ? null : _products(items.length),
      value: ref.watch(expiringProvider),
      onRetry: () => ref.invalidate(expiringProvider),
      action: _canOpen(ref, Routes.adminProducts)
          ? TextButton(
              onPressed: () => context.go(Routes.adminProducts),
              child: const Text('Productos'),
            )
          : null,
      builder: (context, items) => items.isEmpty
          ? const Text('Nada vence en los próximos 7 días.')
          : _ItemList([
              for (final item in items)
                (
                  item.name,
                  '${expiresIn(item.daysLeft)}, '
                      '${localizations.formatShortMonthDay(parseDay(item.expirationDate))}',
                ),
            ]),
    );
  }
}

/// "vence hoy", "vence mañana", "vence en 3 días", "venció ayer",
/// "venció hace 2 días".
String expiresIn(int daysLeft) => switch (daysLeft) {
  0 => 'vence hoy',
  1 => 'vence mañana',
  -1 => 'venció ayer',
  > 1 => 'vence en $daysLeft días',
  _ => 'venció hace ${-daysLeft} días',
};

String _products(int count) => count == 1 ? '1 producto' : '$count productos';

/// Los 5 más vendidos de los últimos 30 días, por unidades. La barra muestra
/// cuánto vendió cada uno al lado del primero.
class TopProductsCard extends ConsumerWidget {
  const TopProductsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return HomeCard<List<TopProduct>>(
      title: 'Más vendidos',
      subtitle: (_) => 'Unidades en los últimos 30 días',
      value: ref.watch(topProductsProvider),
      onRetry: () => ref.invalidate(topProductsProvider),
      builder: (context, products) {
        if (products.isEmpty) {
          return const Text('Todavía no hay ventas en los últimos 30 días.');
        }
        final top = products.first.quantity;
        return Column(
          children: [
            for (final (i, product) in products.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 20,
                            child: Text(
                              '${i + 1}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(child: Text(product.name)),
                          Text(
                            '${product.quantity} u.',
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Row(
                          children: [
                            Expanded(child: _Meter(product.quantity / top)),
                            const SizedBox(width: 12),
                            Text(
                              formatSoles(product.revenueCents),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Una barra fina: el riel en naranja muy claro y lo lleno en `primary`.
class _Meter extends StatelessWidget {
  const _Meter(this.fraction);

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 6,
          color: NeilsColors.primaryTint,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction.clamp(0, 1),
            heightFactor: 1,
            child: ColoredBox(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

/// Una lista corta de "producto: detalle".
class _ItemList extends StatelessWidget {
  const _ItemList(this.items);

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final (i, (name, detail)) in items.indexed) ...[
          if (i > 0) const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(name)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      detail,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Columnas de al menos [minWidth], entre 1 y [maxColumns], todas del mismo
/// ancho. Las tarjetas de una fila tienen el alto de la más alta.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    required this.minWidth,
    required this.maxColumns,
  });

  final List<Widget> children;
  final double minWidth;
  final int maxColumns;

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minWidth).floor().clamp(
          1,
          maxColumns,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var start = 0; start < children.length; start += columns) ...[
              if (start > 0) const SizedBox(height: _gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = start; i < start + columns; i++) ...[
                      if (i > start) const SizedBox(width: _gap),
                      // La última fila, si queda incompleta, con huecos.
                      Expanded(
                        child: i < children.length
                            ? children[i]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
