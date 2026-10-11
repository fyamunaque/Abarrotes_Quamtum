import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/staff/staff.dart';
import '../../../admin/staff/staff_providers.dart';
import '../../../common/page_list.dart';
import '../../../session/staff_permission.dart';
import '../../../theme/brand_colors.dart';
import '../shared/admin_page.dart';
import '../shared/admin_table.dart';
import '../shared/panel_note.dart';
import '../shared/refresh_button.dart';
import '../shared/status_badge.dart';
import 'role_form.dart';
import 'team_widgets.dart';

/// Los roles del equipo (solo con `staff.manage`): la lista, crear uno nuevo
/// y, al tocar uno, el editor con sus permisos. El rol del sistema se abre
/// bloqueado.
class AdminRolesScreen extends ConsumerWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(staffRolesProvider.notifier);
    // Todos en una página: son pocos y el servidor no los pagina.
    final roles = ref
        .watch(staffRolesProvider)
        .whenData(
          (roles) => PageList(
            roles,
            total: roles.length,
            pageSize: roles.isEmpty ? 1 : roles.length,
          ),
        );

    void notify(String? message) {
      if (message == null || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> create() async => notify(
      await showAdminForm<String>(
        context,
        title: 'Nuevo rol',
        builder: (_) => RoleForm(
          onSubmit: (input) =>
              notifier.create(name: input.name, permissions: input.permissions),
        ),
      ),
    );

    Future<void> edit(StaffRole role) async => notify(
      await showAdminForm<String>(
        context,
        title: role.isSystem ? 'Rol del sistema' : 'Editar rol',
        builder: (_) => RoleForm(
          role: role,
          onSubmit: (input) => notifier.save(
            role.id,
            name: input.name == role.name ? null : input.name,
            permissions: input.permissions,
            active: input.active == role.active ? null : input.active,
          ),
          onDelete: role.isSystem ? null : () => notifier.delete(role.id),
        ),
      ),
    );

    String permissions(StaffRole role) => role.isSystem
        ? 'Todos'
        : '${role.permissions.length} de ${StaffPermission.values.length}';

    return AdminPage(
      title: 'Equipo',
      actions: [
        RefreshButton(onRefresh: () => ref.refresh(staffRolesProvider.future)),
        FilledButton.icon(
          onPressed: create,
          icon: const Icon(Icons.add),
          label: const Text('Nuevo rol'),
        ),
      ],
      children: [
        const TeamTabs(current: TeamTab.roles),
        const SizedBox(height: 16),
        const PanelNote(
          'Cada rol es un conjunto de permisos. Toca uno para ver qué permite '
          'o cambiarlo: rige desde la próxima acción de quienes lo tienen.',
        ),
        const SizedBox(height: 16),
        AdminTable<StaffRole>(
          value: roles,
          columns: [
            AdminColumn('Rol', (role) => _RoleName(role), flex: 3),
            AdminColumn('Permisos', (role) => Text(permissions(role))),
            AdminColumn(
              'Personas activas',
              (role) => Text('${role.members}'),
              numeric: true,
            ),
            AdminColumn(
              'Estado',
              (role) => StatusBadge(
                label: role.active ? 'Activo' : 'Inactivo',
                color: role.active
                    ? OrderStatusColors.confirmed
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
          rowKey: (role) => role.id,
          rowLabel: (role) => [
            role.name,
            if (role.isSystem) 'rol del sistema, bloqueado',
            role.isSystem
                ? 'todos los permisos'
                : '${permissions(role)} permisos',
            role.members == 1
                ? '1 persona activa'
                : '${role.members} personas activas',
            if (!role.active) 'inactivo',
          ].join(', '),
          onRowTap: edit,
          onPage: (_) {},
          onRetry: () => ref.invalidate(staffRolesProvider),
          emptyText: 'Todavía no hay roles.',
        ),
      ],
    );
  }
}

/// El nombre del rol; el del sistema, con un candado.
class _RoleName extends StatelessWidget {
  const _RoleName(this.role);

  final StaffRole role;

  @override
  Widget build(BuildContext context) {
    if (!role.isSystem) return Text(role.name);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(role.name)),
        const SizedBox(width: 6),
        Tooltip(
          message: 'Rol del sistema: no se edita',
          child: Icon(
            Icons.lock_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
