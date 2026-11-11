import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/promotions/promotion.dart';
import '../../../admin/promotions/promotions_providers.dart';
import '../../../admin/vip/vip_providers.dart';
import '../../../common/days.dart';
import '../../../common/money.dart';
import '../../../router/routes.dart';
import '../../shared/date_format.dart';
import '../../shared/filter_chips.dart';
import '../shared/admin_page.dart';
import '../shared/admin_table.dart';
import '../shared/panel_tabs.dart';
import '../shared/refresh_button.dart';
import '../shared/status_badge.dart';
import '../shared/vip_badge.dart';
import 'promotion_form.dart';
import 'promotions_tabs.dart';
import '../../../theme/palette.dart';

/// Las promociones, filtradas por estado: crear, editar (precio, fechas,
/// encendida, título y audiencia) y eliminar. Las exclusivas de los clientes
/// VIP llevan la insignia VIP.
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
        // La de un código se edita con su código fijo.
        promoCodeId: promotion?.audience == PromotionAudience.code
            ? promotion?.promoCodeId
            : null,
        onSubmit: (input, {required confirmOverlap}) => promotion == null
            ? notifier.create(input, confirmOverlap: confirmOverlap)
            : notifier.save(
                promotion.id,
                input,
                confirmOverlap: confirmOverlap,
              ),
        searchVips: ref.read(vipSearchProvider),
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
        RefreshButton(onRefresh: ref.read(provider.notifier).refresh),
        FilledButton.icon(
          onPressed: _open,
          icon: const Icon(Icons.add),
          label: const Text('Nueva promoción'),
        ),
      ],
      children: [
        const PanelTabs(tabs: promotionsTabs, current: Routes.adminPromotions),
        const SizedBox(height: 16),
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
            AdminColumn(
              'Promoción',
              (p) => _PriceCell(p),
              flex: 3,
              numeric: true,
            ),
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
          rowLabel: (p) => [
            p.productName,
            ?p.title,
            if (p.audience == PromotionAudience.vip) 'solo clientes VIP',
            if (p.audience == PromotionAudience.selected)
              'para ${p.recipients.length} clientes VIP elegidos',
            if (p.promoCode case final code?) 'del código $code',
            ...switch (_promoCents(p)) {
              final cents? => [
                'de ${formatSoles(p.priceCents)} a ${formatSoles(cents)}',
                '${p.discountPercent} % menos',
              ],
              null => [p.label],
            },
            period(p),
            p.status.label,
          ].join(', '),
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
      PromotionStatus.active => context.palette.positive,
      PromotionStatus.scheduled => context.palette.statusOnTheWay,
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
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(promotion.productName),
            if (promotion.vipOnly) const VipBadge(),
            if (promotion.audience == PromotionAudience.selected)
              Text(
                'Elegidos (${promotion.recipients.length})',
                style: theme.textTheme.labelMedium,
              ),
            if (promotion.promoCode case final code?)
              Text('Código $code', style: theme.textTheme.labelMedium),
          ],
        ),
        Text(
          [?promotion.title, promotion.sku].join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// El precio con la promoción de un precio especial o un %; null en los
/// demás tipos.
int? _promoCents(Promotion promotion) => switch (promotion.type) {
  PromotionType.specialPrice => promotion.promoPriceCents,
  PromotionType.percentOff =>
    (promotion.priceCents * (100 - promotion.percent!) / 100).round(),
  _ => null,
};

/// "S/ 24.90 → S/ 19.90" y debajo el descuento; en un NxM, una unidad
/// extra o un regalo, cómo se nombra ("2x1") y debajo el precio normal.
class _PriceCell extends StatelessWidget {
  const _PriceCell(this.promotion);

  final Promotion promotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final promoCents = _promoCents(promotion);
    if (promoCents == null) {
      return Column(
        crossAxisAlignment: AdminCellAlignment.of(context),
        children: [
          Text(promotion.label),
          Text('Precio ${formatSoles(promotion.priceCents)}', style: muted),
        ],
      );
    }
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
              TextSpan(text: formatSoles(promoCents)),
            ],
          ),
        ),
        Text('${promotion.discountPercent} % menos', style: muted),
      ],
    );
  }
}
