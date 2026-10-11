import 'package:flutter/material.dart';

import '../../../admin/emails.dart';
import '../../../admin/staff/staff.dart';
import '../../../common/api_client.dart';
import '../../shared/error_message.dart';
import '../shared/admin_form.dart';
import '../shared/emails_add_form.dart';
import 'team_widgets.dart';

/// Agregar personas al equipo: uno o varios correos con un mismo rol, con el
/// resumen de lo que respondió el servidor (ver [EmailsAddForm]).
class TeamAddForm extends StatefulWidget {
  const TeamAddForm({super.key, required this.onSubmit});

  final Future<EmailAddSummary> Function(List<String> emails, String roleId)
  onSubmit;

  @override
  State<TeamAddForm> createState() => _TeamAddFormState();
}

class _TeamAddFormState extends State<TeamAddForm> {
  String? _roleId;

  static String _allAdded(int count) => count == 1
      ? 'Listo: el correo ya está en el equipo.'
      : 'Listo: los $count correos ya están en el equipo.';

  @override
  Widget build(BuildContext context) {
    return EmailsAddForm(
      // El validator del rol corre antes: aquí ya hay uno.
      onSubmit: (emails) => widget.onSubmit(emails, _roleId!),
      texts: const EmailsAddTexts(
        note:
            'Entran al panel cuando ingresan a la tienda con ese correo y lo '
            'tienen verificado. Si alguno estaba desactivado, vuelve con este '
            'rol.',
        allAdded: _allAdded,
        duplicatesNote:
            'Ya estaban en el equipo o se repetían en la lista. Para '
            'cambiarles el rol, usa "Cambiar rol" en la tabla.',
      ),
      extraField: (busy) => RoleField(
        value: _roleId,
        enabled: !busy,
        onChanged: (id) => setState(() => _roleId = id),
      ),
    );
  }
}

/// Cambiar el rol de una persona. Si el servidor lo rechaza (es el último
/// Administrador), el motivo queda en el formulario.
class ChangeRoleForm extends StatefulWidget {
  const ChangeRoleForm({
    super.key,
    required this.member,
    required this.onSubmit,
  });

  final StaffMember member;
  final Future<StaffMember> Function(String roleId) onSubmit;

  @override
  State<ChangeRoleForm> createState() => _ChangeRoleFormState();
}

class _ChangeRoleFormState extends State<ChangeRoleForm> {
  final _formKey = GlobalKey<FormState>();
  late String? _roleId = widget.member.roleId;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    // El mismo rol: no hay nada que guardar.
    if (_roleId == widget.member.roleId) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final member = await widget.onSubmit(_roleId!);
      if (mounted) Navigator.of(context).pop(member);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (error) {
      if (mounted) {
        setState(() => _error = errorMessage(error, 'No se pudo cambiar.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = widget.member;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(member.email, style: theme.textTheme.titleMedium),
          if (member.roleName case final role?)
            Text(
              'Ahora: $role',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 16),
          RoleField(
            value: _roleId,
            enabled: !_busy,
            onChanged: (id) => setState(() => _roleId = id),
          ),
          const SizedBox(height: 8),
          Text(
            'Rige desde su próxima acción en el panel.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (_error case final error?) ...[
            FormError(error),
            const SizedBox(height: 16),
          ],
          FormActions(submitLabel: 'Guardar', onSubmit: _submit, busy: _busy),
        ],
      ),
    );
  }
}
