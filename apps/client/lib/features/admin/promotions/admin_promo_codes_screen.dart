import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/promo_codes/promo_code.dart';
import '../../../admin/promo_codes/promo_codes_providers.dart';
import '../../../common/days.dart';
import '../../../router/routes.dart';
import '../../shared/date_format.dart';
import '../../shared/filter_chips.dart';
import '../shared/admin_page.dart';
import '../shared/admin_table.dart';
import '../shared/panel_tabs.dart';
import '../shared/refresh_button.dart';
import '../shared/search_field.dart';
import '../shared/status_badge.dart';
import 'promo_code_form.dart';
import 'promotions_tabs.dart';
import '../../../theme/palette.dart';

/// Los códigos promocionales: chips por estado, buscar por texto, crear,
/// editar (con sus promociones) y eliminar. Con el permiso de las
/// promociones.
class AdminPromoCodesScreen extends ConsumerStatefulWidget {
  const AdminPromoCodesScreen({super.key});

  @override
  ConsumerState<AdminPromoCodesScreen> createState() =>
      _AdminPromoCodesScreenState();
}

class _AdminPromoCodesScreenState extends ConsumerState<AdminPromoCodesScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  PromoCodeStatus? _status;
  String _filter = '';

  PromoCodesFilter get _codesFilter => (status: _status, search: _filter);

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
      if (text.trim() == _filter) return;
      setState(() => _filter = text.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    setState(() => _filter = '');
  }

  Future<void> _open({PromoCode? code}) async {
    final notifier = ref.read(promoCodesProvider(_codesFilter).notifier);
    final message = await showAdminForm<String>(
      context,
      title: code == null ? 'Nuevo código' : 'Editar código',
      builder: (_) => PromoCodeForm(
        code: code,
        onSubmit: code == null
            ? notifier.create
            : (input) => notifier.save(code.id, input),
        onDelete: code == null ? null : () => notifier.delete(code.id),
      ),
    );
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = promoCodesProvider(_codesFilter);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    String period(PromoCode code) => formatStoreRange(
      context,
      parseDay(code.startDate),
      parseDay(code.endDate),
    );
    return AdminPage(
      title: 'Promociones',
      actions: [
        RefreshButton(onRefresh: ref.read(provider.notifier).refresh),
        FilledButton.icon(
          onPressed: _open,
          icon: const Icon(Icons.add),
          label: const Text('Nuevo código'),
        ),
      ],
      children: [
        const PanelTabs(tabs: promotionsTabs, current: Routes.adminPromoCodes),
        const SizedBox(height: 16),
        FilterChips<PromoCodeStatus?>(
          options: [
            (null, 'Todos'),
            for (final status in PromoCodeStatus.values)
              (status, status.pluralLabel),
          ],
          selected: _status,
          onSelected: (status) => setState(() => _status = status),
        ),
        const SizedBox(height: 12),
        PanelSearchField(
          controller: _search,
          label: 'Buscar código',
          textCapitalization: TextCapitalization.characters,
          onChanged: _onSearch,
          onClear: _clearSearch,
        ),
        const SizedBox(height: 16),
        AdminTable<PromoCode>(
          value: ref.watch(provider),
          columns: [
            AdminColumn(
              'Código',
              (code) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(code.code, style: theme.textTheme.titleSmall),
                  Text(_promotionsSummary(code), style: muted),
                ],
              ),
              flex: 4,
            ),
            AdminColumn(
              'Estado',
              (code) => StatusBadge(
                label: code.status.label,
                color: promoCodeStatusColor(context, code.status),
              ),
            ),
            AdminColumn('Vigencia', (code) => Text(period(code)), flex: 3),
            AdminColumn(
              'Activaciones',
              (code) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(code.redemptionsLabel),
                  if (code.maxRedemptions == null)
                    Text('Sin límite', style: muted),
                ],
              ),
              flex: 3,
            ),
            AdminColumn(
              'Pedidos',
              (code) => Text('${code.orders}'),
              numeric: true,
            ),
          ],
          rowKey: (code) => code.id,
          rowLabel: (code) => [
            code.code,
            _promotionsSummary(code),
            code.status.label,
            period(code),
            code.redemptionsLabel,
            if (code.maxRedemptions == null) 'sin límite',
            'usado en ${code.orders} pedidos',
          ].join(', '),
          onRowTap: (code) => _open(code: code),
          onPage: (page) => ref.read(provider.notifier).goTo(page),
          onRetry: () => ref.invalidate(provider),
          emptyText: _filter.isNotEmpty
              ? 'Ningún código coincide con la búsqueda.'
              : _status == null
              ? 'Todavía no hay códigos.'
              : 'No hay códigos ${_status!.pluralLabel.toLowerCase()}.',
        ),
      ],
    );
  }

  /// "2x1 en Arroz extra 5 kg", "2 promociones" o "Sin promociones".
  static String _promotionsSummary(PromoCode code) => switch (code.promotions) {
    [] => 'Sin promociones',
    [final only] => '${only.label} en ${only.productName}',
    final all => '${all.length} promociones',
  };
}

/// Verde el que se puede activar hoy, azul el que viene; los demás, en
/// gris. Siempre con el estado en texto al lado.
Color promoCodeStatusColor(BuildContext context, PromoCodeStatus status) =>
    switch (status) {
      PromoCodeStatus.active => context.palette.positive,
      PromoCodeStatus.scheduled => context.palette.statusOnTheWay,
      PromoCodeStatus.expired ||
      PromoCodeStatus.paused => Theme.of(context).colorScheme.outline,
    };
