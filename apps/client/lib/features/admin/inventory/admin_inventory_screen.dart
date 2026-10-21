import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/inventory/inventory_providers.dart';
import '../../../admin/inventory/movement.dart';
import '../../../session/session_provider.dart';
import '../../../session/staff_permission.dart';
import '../../shared/date_format.dart';
import '../shared/admin_page.dart';
import '../shared/admin_table.dart';
import '../shared/panel_note.dart';
import '../shared/refresh_button.dart';
import 'movement_form.dart';

/// El historial de movimientos de stock (el más reciente primero) y, con
/// `inventory.adjust`, "Registrar movimiento": entradas, salidas y ajustes.
class AdminInventoryScreen extends ConsumerWidget {
  const AdminInventoryScreen({super.key});

  Future<void> _record(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(movementsProvider.notifier);
    final movement = await showAdminForm<Movement>(
      context,
      title: 'Registrar movimiento',
      builder: (_) => MovementForm(onSubmit: notifier.record),
    );
    if (movement == null || !context.mounted) return;
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
  Widget build(BuildContext context, WidgetRef ref) {
    final canAdjust = ref
        .watch(permissionsProvider)
        .contains(StaffPermission.inventoryAdjust);
    return AdminPage(
      title: 'Inventario',
      actions: [
        RefreshButton(onRefresh: ref.read(movementsProvider.notifier).refresh),
        if (canAdjust)
          FilledButton.icon(
            onPressed: () => _record(context, ref),
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
        AdminTable<Movement>(
          value: ref.watch(movementsProvider),
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
            AdminColumn('Motivo', (m) => Text(m.reason ?? '—'), flex: 4),
            AdminColumn('Quién', (m) => Text(m.userName), flex: 3),
          ],
          rowKey: (m) => m.id,
          rowLabel: (m) => [
            formatDateTime(context, m.createdAt),
            m.productName,
            m.type.label,
            signedQuantity(m.change),
            ?m.reason,
            m.userName,
          ].join(', '),
          onPage: (page) => ref.read(movementsProvider.notifier).goTo(page),
          onRetry: () => ref.invalidate(movementsProvider),
          emptyText: 'Todavía no hay movimientos.',
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
