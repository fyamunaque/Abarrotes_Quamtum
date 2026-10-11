import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/emails.dart';
import '../../../admin/vip/vip_customer.dart';
import '../../../admin/vip/vip_providers.dart';
import '../../../session/session.dart';
import '../../../session/session_provider.dart';
import '../../../theme/brand_colors.dart';
import '../../shared/date_format.dart';
import '../../shared/error_message.dart';
import '../shared/admin_page.dart';
import '../shared/admin_table.dart';
import '../shared/refresh_button.dart';
import '../shared/status_badge.dart';
import 'vip_add_form.dart';

/// Los clientes VIP: buscar por correo y, solo para admin, agregar y quitar.
/// Staff ve la lista en modo lectura (el servidor tampoco lo deja cambiarla).
class AdminVipScreen extends ConsumerStatefulWidget {
  const AdminVipScreen({super.key});

  @override
  ConsumerState<AdminVipScreen> createState() => _AdminVipScreenState();
}

class _AdminVipScreenState extends ConsumerState<AdminVipScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _filter = '';

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

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    final notifier = ref.read(vipCustomersProvider(_filter).notifier);
    final summary = await showAdminForm<EmailAddSummary>(
      context,
      title: 'Agregar clientes VIP',
      builder: (_) => VipAddForm(onSubmit: notifier.add),
    );
    final added = summary?.added.length ?? 0;
    if (added > 0 && mounted) {
      _notify(
        added == 1
            ? 'Agregaste 1 cliente VIP.'
            : 'Agregaste $added clientes VIP.',
      );
    }
  }

  Future<void> _remove(VipCustomer vip) async {
    final notifier = ref.read(vipCustomersProvider(_filter).notifier);
    final confirmed = await confirmAction(
      context,
      title: '¿Quitar a ${vip.email} de los clientes VIP?',
      message:
          'Deja de ver las promociones VIP desde ahora. Puedes volver a '
          'agregarlo cuando quieras.',
      confirmLabel: 'Quitar',
    );
    if (!confirmed) return;
    try {
      await notifier.remove(vip.id);
      if (mounted) _notify('Quitaste a ${vip.email} de los clientes VIP.');
    } catch (error) {
      if (mounted) {
        _notify(errorMessage(error, 'No se pudo quitar al cliente VIP.'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = vipCustomersProvider(_filter);
    final isAdmin = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user.role.isAdmin,
      _ => false,
    };
    String since(VipCustomer vip) => formatDate(context, vip.createdAt);
    String status(VipCustomer vip) =>
        vip.hasAccount ? 'Registrado' : 'Aún sin cuenta';

    return AdminPage(
      title: 'Clientes VIP',
      actions: [
        RefreshButton(onRefresh: ref.read(provider.notifier).refresh),
        if (isAdmin)
          FilledButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.person_add_alt_outlined),
            label: const Text('Agregar clientes'),
          ),
      ],
      children: [
        _Note(readOnly: !isAdmin),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            width: constraints.maxWidth < 560 ? constraints.maxWidth : 320,
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                labelText: 'Buscar por correo',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ListenableBuilder(
                  listenable: _search,
                  builder: (_, _) => _search.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: 'Borrar la búsqueda',
                          icon: const Icon(Icons.close),
                          onPressed: _clearSearch,
                        ),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.search,
              onChanged: _onSearch,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AdminTable<VipCustomer>(
          value: ref.watch(provider),
          columns: [
            AdminColumn('Correo', (vip) => Text(vip.email), flex: 4),
            AdminColumn(
              'Estado',
              (vip) => StatusBadge(
                label: status(vip),
                color: vip.hasAccount
                    ? OrderStatusColors.confirmed
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            AdminColumn('Alta', (vip) => Text(since(vip))),
          ],
          rowKey: (vip) => vip.id,
          rowLabel: (vip) =>
              '${vip.email}, ${status(vip).toLowerCase()}, alta ${since(vip)}',
          rowActions: [
            if (isAdmin)
              AdminRowAction(
                label: 'Quitar',
                icon: Icons.person_remove_outlined,
                semanticLabel: (vip) => 'Quitar a ${vip.email}',
                onPressed: _remove,
                destructive: true,
              ),
          ],
          onPage: (page) => ref.read(provider.notifier).goTo(page),
          onRetry: () => ref.invalidate(provider),
          emptyText: _filter.isNotEmpty
              ? 'Ningún correo coincide con la búsqueda.'
              : isAdmin
              ? 'Todavía no hay clientes VIP. Agrégalos con '
                    '"Agregar clientes".'
              : 'Todavía no hay clientes VIP.',
        ),
      ],
    );
  }
}

/// Qué significa ser VIP y, para staff, por qué no hay botones.
class _Note extends StatelessWidget {
  const _Note({required this.readOnly});

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 20, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Ven las promociones VIP cuando ingresan a la tienda con ese '
            'correo y lo tienen verificado.'
            '${readOnly ? ' Solo un admin puede agregar o quitar clientes '
                      'VIP.' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
