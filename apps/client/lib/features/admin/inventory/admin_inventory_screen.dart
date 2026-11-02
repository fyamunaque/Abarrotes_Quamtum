import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/inventory/inventory_providers.dart';
import '../../../admin/inventory/movement.dart';
import '../../../session/session_provider.dart';
import '../../../session/staff_permission.dart';
import '../../shared/date_format.dart';
import '../../shared/dates_filter.dart';
import '../../shared/filter_chips.dart';
import '../shared/admin_page.dart';
import '../shared/admin_table.dart';
import '../shared/category_filter.dart';
import '../shared/panel_note.dart';
import '../shared/refresh_button.dart';
import '../shared/search_field.dart';
import 'movement_form.dart';

/// El historial de movimientos de stock (el más reciente primero), con la
/// búsqueda (producto, SKU o N.º de pedido) y los filtros por origen,
/// categoría y fechas. Con `inventory.adjust`, "Registrar movimiento":
/// entradas, salidas y ajustes.
class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  ConsumerState<AdminInventoryScreen> createState() =>
      _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  MovementsFilter _filter = allMovements;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _update({
    String? search,
    MovementOrigin? Function()? origin,
    String? Function()? categoryId,
    (DateTime?, DateTime?)? dates,
  }) => setState(
    () => _filter = (
      search: search ?? _filter.search,
      origin: origin == null ? _filter.origin : origin(),
      categoryId: categoryId == null ? _filter.categoryId : categoryId(),
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

  Future<void> _record() async {
    final notifier = ref.read(movementsProvider(_filter).notifier);
    final movement = await showAdminForm<Movement>(
      context,
      title: 'Registrar movimiento',
      builder: (_) => MovementForm(onSubmit: notifier.record),
    );
    if (movement == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Movimiento registrado: ${movement.productName}, '
            '${signedQuantity(movement.change)}.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = movementsProvider(_filter);
    final filtered = _filter != allMovements;
    final canAdjust = ref
        .watch(permissionsProvider)
        .contains(StaffPermission.inventoryAdjust);
    return AdminPage(
      title: 'Inventario',
      actions: [
        RefreshButton(onRefresh: ref.read(provider.notifier).refresh),
        if (canAdjust)
          FilledButton.icon(
            onPressed: _record,
            icon: const Icon(Icons.add),
            label: const Text('Registrar movimiento'),
          ),
      ],
      children: [
        if (!canAdjust) ...[
          const PanelNote(
            'Tu rol puede ver el inventario, pero no registrar movimientos.',
          ),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < PanelSearchField.narrowBelow;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: narrow ? constraints.maxWidth : 340,
                  child: PanelSearchField(
                    controller: _search,
                    label: 'Buscar producto, SKU o N.º de pedido',
                    onChanged: _onSearch,
                    onClear: _clearSearch,
                  ),
                ),
                SizedBox(
                  width: narrow ? constraints.maxWidth : 240,
                  child: CategoryFilter(
                    value: _filter.categoryId,
                    onChanged: (id) => _update(categoryId: () => id),
                  ),
                ),
                DatesFilter(
                  from: _filter.from,
                  to: _filter.to,
                  helpText: 'Movimientos entre',
                  onChanged: (from, to) => _update(dates: (from, to)),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        FilterRow(
          label: 'Origen',
          child: FilterChips<MovementOrigin?>(
            options: [
              (null, 'Todos'),
              for (final origin in MovementOrigin.values)
                (origin, origin.label),
            ],
            selected: _filter.origin,
            onSelected: (origin) => _update(origin: () => origin),
          ),
        ),
        const SizedBox(height: 16),
        AdminTable<Movement>(
          value: ref.watch(provider),
          columns: [
            AdminColumn(
              'Fecha',
              (m) => Text(formatDateTime(context, m.createdAt)),
              flex: 3,
            ),
            AdminColumn('Producto', (m) => _ProductCell(m), flex: 4),
            AdminColumn('Tipo', (m) => Text(m.type.label)),
            AdminColumn(
              'Cantidad',
              (m) => Text(signedQuantity(m.change)),
              numeric: true,
            ),
            AdminColumn('Motivo', (m) => Text(m.reasonLabel ?? '—'), flex: 4),
            AdminColumn('Quién', (m) => Text(m.userName), flex: 3),
          ],
          rowKey: (m) => m.id,
          rowLabel: (m) => [
            formatDateTime(context, m.createdAt),
            m.productName,
            m.type.label,
            signedQuantity(m.change),
            ?m.reasonLabel,
            m.userName,
          ].join(', '),
          onPage: (page) => ref.read(provider.notifier).goTo(page),
          onRetry: () => ref.invalidate(provider),
          emptyText: filtered
              ? 'Ningún movimiento coincide con los filtros.'
              : 'Todavía no hay movimientos.',
        ),
      ],
    );
  }
}

/// "+12" o "−3" (con el signo menos de verdad, no un guion).
String signedQuantity(int change) => change < 0 ? '−${-change}' : '+$change';

class _ProductCell extends StatelessWidget {
  const _ProductCell(this.movement);

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(movement.productName),
        Text(
          movement.sku,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
