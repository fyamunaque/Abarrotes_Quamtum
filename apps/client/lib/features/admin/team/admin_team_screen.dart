import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/emails.dart';
import '../../../admin/staff/staff.dart';
import '../../../admin/staff/staff_providers.dart';
import '../../../session/session.dart';
import '../../../session/session_provider.dart';
import '../../shared/error_message.dart';
import '../shared/admin_page.dart';
import '../shared/admin_table.dart';
import '../shared/panel_note.dart';
import '../shared/refresh_button.dart';
import '../shared/search_field.dart';
import 'team_forms.dart';
import 'team_widgets.dart';

/// Las personas del equipo (solo con `staff.manage`, ver route_guard.dart):
/// buscar por correo, agregar uno o varios con un rol, cambiarles el rol y
/// desactivarlas. La fila propia no tiene acciones: nadie se cambia el rol
/// ni se desactiva a sí mismo.
class AdminTeamScreen extends ConsumerStatefulWidget {
  const AdminTeamScreen({super.key});

  @override
  ConsumerState<AdminTeamScreen> createState() => _AdminTeamScreenState();
}

class _AdminTeamScreenState extends ConsumerState<AdminTeamScreen> {
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

  StaffMembersNotifier get _notifier =>
      ref.read(staffMembersProvider(_filter).notifier);

  Future<void> _add() async {
    final notifier = _notifier;
    final summary = await showAdminForm<EmailAddSummary>(
      context,
      title: 'Agregar al equipo',
      builder: (_) => TeamAddForm(onSubmit: notifier.add),
    );
    final added = summary?.added.length ?? 0;
    if (added > 0 && mounted) {
      _notify(
        added == 1
            ? 'Agregaste 1 persona al equipo.'
            : 'Agregaste $added personas al equipo.',
      );
    }
  }

  Future<void> _changeRole(StaffMember member) async {
    final notifier = _notifier;
    final changed = await showAdminForm<StaffMember>(
      context,
      title: 'Cambiar el rol',
      builder: (_) => ChangeRoleForm(
        member: member,
        onSubmit: (roleId) => notifier.changeRole(member.id, roleId),
      ),
    );
    if (changed != null && mounted) {
      _notify('Ahora ${changed.email} tiene el rol ${changed.roleName}.');
    }
  }

  Future<void> _deactivate(StaffMember member) async {
    final notifier = _notifier;
    final confirmed = await confirmAction(
      context,
      title: '¿Desactivar a ${member.email}?',
      message:
          'Deja de entrar al panel desde su próxima acción. Queda en la '
          'tabla como desactivado; para que vuelva, agrégalo de nuevo.',
      confirmLabel: 'Desactivar',
    );
    if (!confirmed) return;
    try {
      await notifier.deactivate(member.id);
      if (mounted) _notify('Desactivaste a ${member.email}.');
    } catch (error) {
      if (!mounted) return;
      // El servidor dice por qué (p. ej. es el último Administrador).
      await showRejected(
        context,
        title: 'No se pudo desactivar a ${member.email}',
        message: errorMessage(error, 'No se pudo desactivar.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = staffMembersProvider(_filter);
    final myEmail = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => normalizeEmail(user.email),
      _ => null,
    };
    bool isMe(StaffMember member) => member.email == myEmail;
    String email(StaffMember member) =>
        isMe(member) ? '${member.email} (tú)' : member.email;
    String role(StaffMember member) => member.roleName ?? 'Sin rol';

    return AdminPage(
      title: 'Equipo',
      actions: [
        RefreshButton(onRefresh: ref.read(provider.notifier).refresh),
        FilledButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.person_add_alt_outlined),
          label: const Text('Agregar personas'),
        ),
      ],
      children: [
        const TeamTabs(current: TeamTab.people),
        const SizedBox(height: 16),
        const PanelNote(
          'Cada persona entra al panel con su correo, cuando ingresa a la '
          'tienda y lo tiene verificado. "Pendiente de registro": todavía no '
          'creó su cuenta con ese correo.',
        ),
        const SizedBox(height: 16),
        PanelSearchField(
          controller: _search,
          label: 'Buscar por correo',
          keyboardType: TextInputType.emailAddress,
          onChanged: _onSearch,
          onClear: _clearSearch,
        ),
        const SizedBox(height: 16),
        AdminTable<StaffMember>(
          value: ref.watch(provider),
          columns: [
            AdminColumn('Correo', (member) => Text(email(member)), flex: 4),
            AdminColumn('Rol', (member) => Text(role(member))),
            AdminColumn(
              'Estado',
              (member) => StaffStatusBadge(member.status),
              flex: 3,
            ),
          ],
          rowKey: (member) => member.id,
          rowLabel: (member) =>
              '${email(member)}, ${role(member)}, '
              '${StaffStatusBadge.label(member.status).toLowerCase()}',
          rowActions: [
            AdminRowAction(
              label: 'Cambiar rol',
              icon: Icons.manage_accounts_outlined,
              semanticLabel: (member) => 'Cambiar el rol de ${member.email}',
              onPressed: _changeRole,
              showFor: (member) => !isMe(member),
            ),
            AdminRowAction(
              label: 'Desactivar',
              icon: Icons.person_off_outlined,
              semanticLabel: (member) => 'Desactivar a ${member.email}',
              onPressed: _deactivate,
              destructive: true,
              showFor: (member) => member.active && !isMe(member),
            ),
          ],
          onPage: (page) => ref.read(provider.notifier).goTo(page),
          onRetry: () => ref.invalidate(provider),
          emptyText: _filter.isNotEmpty
              ? 'Ningún correo coincide con la búsqueda.'
              : 'Todavía no hay nadie en el equipo.',
        ),
      ],
    );
  }
}
