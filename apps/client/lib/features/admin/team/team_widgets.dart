import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../admin/staff/staff.dart';
import '../../../admin/staff/staff_providers.dart';
import '../../../router/routes.dart';
import '../../../theme/brand_colors.dart';
import '../../shared/error_message.dart';
import '../shared/status_badge.dart';

/// Las dos pestañas de la sección Equipo: las personas y los roles.
enum TeamTab { people, roles }

class TeamTabs extends StatelessWidget {
  const TeamTabs({super.key, required this.current});

  final TeamTab current;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SegmentedButton<TeamTab>(
        segments: const [
          ButtonSegment(
            value: TeamTab.people,
            label: Text('Personas'),
            icon: Icon(Icons.badge_outlined),
          ),
          ButtonSegment(
            value: TeamTab.roles,
            label: Text('Roles'),
            icon: Icon(Icons.admin_panel_settings_outlined),
          ),
        ],
        selected: {current},
        showSelectedIcon: false,
        onSelectionChanged: (selected) => context.go(switch (selected.single) {
          TeamTab.people => Routes.adminTeam,
          TeamTab.roles => Routes.adminRoles,
        }),
      ),
    );
  }
}

/// Un texto de ayuda bajo el título, con el ícono de información.
class TeamNote extends StatelessWidget {
  const TeamNote(this.text, {super.key});

  final String text;

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
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}

/// El estado de una persona del equipo, en texto y con su color.
class StaffStatusBadge extends StatelessWidget {
  const StaffStatusBadge(this.status, {super.key});

  final StaffMemberStatus status;

  static String label(StaffMemberStatus status) => switch (status) {
    StaffMemberStatus.active => 'Activo',
    StaffMemberStatus.pendingSignUp => 'Pendiente de registro',
    StaffMemberStatus.deactivated => 'Desactivado',
  };

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: label(status),
      color: switch (status) {
        StaffMemberStatus.active => OrderStatusColors.confirmed,
        StaffMemberStatus.pendingSignUp => OrderStatusColors.pending,
        StaffMemberStatus.deactivated => Theme.of(context).colorScheme.outline,
      },
    );
  }
}

/// El rol para asignar: solo los activos (un rol inactivo no se asigna). Va
/// dentro de un formulario: sin elegir, "Elige un rol.".
class RoleField extends ConsumerWidget {
  const RoleField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(staffRolesProvider);
    final assignable = [
      for (final role in roles.value ?? const <StaffRole>[])
        if (role.active) role,
    ];
    final failed = roles.hasError && roles.value == null;
    return DropdownButtonFormField<String>(
      // Cambia de clave al llegar los roles, para tomar el valor inicial.
      key: ValueKey(assignable.length),
      style: Theme.of(context).textTheme.bodyLarge,
      initialValue: assignable.any((role) => role.id == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Rol',
        helperText: failed
            ? errorMessage(roles.error!, 'No se pudieron cargar los roles.')
            : roles.isLoading && roles.value == null
            ? 'Cargando los roles…'
            : null,
        helperMaxLines: 2,
        suffixIcon: failed
            ? IconButton(
                tooltip: 'Volver a cargar los roles',
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(staffRolesProvider),
              )
            : null,
      ),
      items: [
        for (final role in assignable)
          DropdownMenuItem(value: role.id, child: Text(role.name)),
      ],
      onChanged: enabled ? onChanged : null,
      validator: (id) => id == null ? 'Elige un rol.' : null,
    );
  }
}
