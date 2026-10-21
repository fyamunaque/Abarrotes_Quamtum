import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/products/admin_products_providers.dart';
import '../../../catalog/catalog_providers.dart';
import '../../../catalog/product.dart';
import '../../../common/money.dart';
import '../../../session/session_provider.dart';
import '../../../session/staff_permission.dart';
import '../../../theme/brand_colors.dart';
import '../shared/admin_page.dart';
import '../shared/admin_table.dart';
import '../shared/panel_note.dart';
import '../shared/refresh_button.dart';
import '../shared/search_field.dart';
import '../shared/status_badge.dart';
import 'product_form.dart';

/// Los productos, también los dados de baja (con `products.view`): buscar y
/// filtrar por categoría. Con `products.manage`, crear, editar y dar de
/// baja.
class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  ProductFilter _filter = (search: '', categoryId: null);

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Busca cuando se deja de escribir, no con cada letra.
  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (text.trim() == _filter.search) return;
      setState(
        () => _filter = (search: text.trim(), categoryId: _filter.categoryId),
      );
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    setState(() => _filter = (search: '', categoryId: _filter.categoryId));
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _create() async {
    final notifier = ref.read(adminProductsProvider(_filter).notifier);
    final created = await showAdminForm<Product>(
      context,
      title: 'Nuevo producto',
      builder: (_) => ProductForm(onSubmit: notifier.create),
    );
    if (created != null) _notify('Creaste "${created.name}".');
  }

  Future<void> _edit(Product product) async {
    final notifier = ref.read(adminProductsProvider(_filter).notifier);
    final saved = await showAdminForm<Product>(
      context,
      title: 'Editar producto',
      builder: (_) => ProductForm(
        product: product,
        onSubmit: (input) => notifier.save(product.id, input),
        onDeactivate: product.active
            ? () => notifier.deactivate(product.id)
            : null,
      ),
    );
    if (saved == null) return;
    _notify(
      product.active && !saved.active
          ? '"${saved.name}" quedó de baja.'
          : 'Guardaste "${saved.name}".',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = adminProductsProvider(_filter);
    final filtered = _filter.search.isNotEmpty || _filter.categoryId != null;
    final canManage = ref
        .watch(permissionsProvider)
        .contains(StaffPermission.productsManage);
    return AdminPage(
      title: 'Productos',
      actions: [
        RefreshButton(onRefresh: ref.read(provider.notifier).refresh),
        if (canManage)
          FilledButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo producto'),
          ),
      ],
      children: [
        if (!canManage) ...[
          const PanelNote(
            'Tu rol puede ver los productos, pero no crearlos ni editarlos.',
          ),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < PanelSearchField.narrowBelow;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: narrow ? constraints.maxWidth : 320,
                  child: PanelSearchField(
                    controller: _search,
                    label: 'Buscar por nombre o SKU',
                    onChanged: _onSearch,
                    onClear: _clearSearch,
                  ),
                ),
                SizedBox(
                  width: narrow ? constraints.maxWidth : 240,
                  child: _CategoryFilter(
                    value: _filter.categoryId,
                    onChanged: (id) => setState(
                      () => _filter = (search: _filter.search, categoryId: id),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        AdminTable<Product>(
          value: ref.watch(provider),
          columns: [
            AdminColumn('Producto', (p) => _NameCell(p), flex: 4),
            AdminColumn('Categoría', (p) => Text(p.category?.name ?? '—')),
            AdminColumn('Precio', (p) => _PriceCell(p), numeric: true),
            AdminColumn('Stock', (p) => _StockCell(p), numeric: true),
            AdminColumn(
              'Estado',
              (p) => StatusBadge(
                label: p.active ? 'Activo' : 'De baja',
                color: p.active
                    ? OrderStatusColors.confirmed
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
          rowKey: (p) => p.id,
          rowLabel: _rowLabel,
          onRowTap: canManage ? _edit : null,
          onPage: (page) => ref.read(provider.notifier).goTo(page),
          onRetry: () => ref.invalidate(provider),
          emptyText: filtered
              ? 'Ningún producto coincide con la búsqueda.'
              : 'Todavía no hay productos.',
        ),
      ],
    );
  }
}

String _rowLabel(Product p) => [
  p.name,
  'SKU ${p.sku}',
  ?p.category?.name,
  p.onSale
      ? 'en promoción a ${formatSoles(p.promoPriceCents!)}, '
            'antes ${formatSoles(p.priceCents)}'
      : formatSoles(p.priceCents),
  'stock ${p.stock}, mínimo ${p.minStock}${p.lowStock ? ', stock bajo' : ''}',
  p.active ? 'activo' : 'de baja',
].join(', ');

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    return DropdownButtonFormField<String?>(
      style: Theme.of(context).textTheme.bodyLarge,
      // Recién al cargar las categorías se puede mostrar la elegida.
      key: ValueKey(categories.length),
      initialValue: categories.any((c) => c.id == value) ? value : null,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Categoría'),
      items: [
        const DropdownMenuItem(child: Text('Todas')),
        for (final category in categories)
          DropdownMenuItem(value: category.id, child: Text(category.name)),
      ],
      onChanged: onChanged,
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell(this.product);

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.name),
        Text(
          product.sku,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// El precio de hoy y, si está en promoción, el normal tachado debajo.
class _PriceCell extends StatelessWidget {
  const _PriceCell(this.product);

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: AdminCellAlignment.of(context),
      children: [
        Text(formatSoles(product.finalPriceCents)),
        if (product.onSale)
          Text(
            formatSoles(product.priceCents),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}

/// El stock y su mínimo; en el mínimo o por debajo, resaltado.
class _StockCell extends StatelessWidget {
  const _StockCell(this.product);

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final low = product.lowStock;
    return Column(
      crossAxisAlignment: AdminCellAlignment.of(context),
      children: [
        Text(
          !low
              ? '${product.stock}'
              : product.stock == 0
              ? 'Agotado'
              : '${product.stock} · bajo',
          style: low
              ? TextStyle(
                  color: OrderStatusColors.cancelled,
                  fontWeight: FontWeight.w600,
                )
              : null,
        ),
        Text(
          'mín. ${product.minStock}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
