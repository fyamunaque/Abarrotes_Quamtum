import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/promotions/promotion.dart';
import '../../../admin/promotions/promotions_providers.dart';
import '../../../common/days.dart';
import '../../../common/money.dart';
import '../../../theme/brand_colors.dart';
import '../../shared/date_format.dart';
import '../shared/admin_page.dart';
import '../shared/admin_table.dart';
import '../shared/filter_chips.dart';
import '../shared/status_badge.dart';
import 'promotion_form.dart';

/// Las promociones, filtradas por estado: crear, editar (precio, fechas,
/// encendida) y eliminar.
class AdminPromotionsScreen extends ConsumerStatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  ConsumerState<AdminPromotionsScreen> createState() =>
      _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends ConsumerState<AdminPromotionsScreen> {
  PromotionStatus? _status;

  Future<void> _open({Promotion? promotion}) async {
    final notifier = ref.read(promotionsProvider(_status).notifier);
    final message = await showAdminForm<String>(
      context,
      title: promotion == null ? 'Nueva promoción' : 'Editar promoción',
      builder: (_) => PromotionForm(
        promotion: promotion,
        onSubmit: promotion == null
            ? notifier.create
            : (input) => notifier.save(promotion.id, input),
        onDelete: promotion == null
            ? null
            : () => notifier.delete(promotion.id),
      ),
    );
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = promotionsProvider(_status);
    String period(Promotion p) =>
        formatStoreRange(context, parseDay(p.startDate), parseDay(p.endDate));
    return AdminPage(
      title: 'Promociones',
      actions: [
        FilledButton.icon(
          onPressed: _open,
          icon: const Icon(Icons.add),
          label: const Text('Nueva promoción'),
        ),
      ],
      children: [
        FilterChips<PromotionStatus?>(
          options: [
            (null, 'Todas'),
            for (final status in PromotionStatus.values)
              (status, status.pluralLabel),
          ],
          selected: _status,
          onSelected: (status) => setState(() => _status = status),
        ),
        const SizedBox(height: 16),
        AdminTable<Promotion>(
          value: ref.watch(provider),
          columns: [
            AdminColumn('Producto', (p) => _ProductCell(p), flex: 4),
            AdminColumn('Precio', (p) => _PriceCell(p), flex: 3, numeric: true),
            AdminColumn('Vigencia', (p) => Text(period(p)), flex: 3),
            AdminColumn(
              'Estado',
              (p) => StatusBadge(
                label: p.status.label,
                color: promotionStatusColor(context, p.status),
              ),
            ),
          ],
          rowKey: (p) => p.id,
          rowLabel: (p) =>
              '${p.productName}, de ${formatSoles(p.priceCents)} a '
              '${formatSoles(p.promoPriceCents)}, ${p.discountPercent} % menos, '
              '${period(p)}, ${p.status.label}',
          onRowTap: (p) => _open(promotion: p),
          onPage: (page) => ref.read(provider.notifier).goTo(page),
          onRetry: () => ref.invalidate(provider),
          emptyText: _status == null
              ? 'Todavía no hay promociones.'
              : 'No hay promociones ${_status!.pluralLabel.toLowerCase()}.',
        ),
      ],
    );
  }
}

/// Verde la que rige hoy, azul la que viene; las demás, apagadas en gris.
/// Siempre con el estado en texto al lado.
Color promotionStatusColor(BuildContext context, PromotionStatus status) =>
    switch (status) {
      PromotionStatus.active => OrderStatusColors.confirmed,
      PromotionStatus.scheduled => OrderStatusColors.onTheWay,
      PromotionStatus.expired ||
      PromotionStatus.disabled => Theme.of(context).colorScheme.outline,
    };

class _ProductCell extends StatelessWidget {
  const _ProductCell(this.promotion);

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(promotion.productName),
        Text(
          promotion.sku,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// "S/ 24.90 → S/ 19.90" y debajo el descuento.
class _PriceCell extends StatelessWidget {
  const _PriceCell(this.promotion);

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: AdminCellAlignment.of(context),
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${formatSoles(promotion.priceCents)} → ',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              TextSpan(text: formatSoles(promotion.promoPriceCents)),
            ],
          ),
        ),
        Text('${promotion.discountPercent} % menos', style: muted),
      ],
    );
  }
}
