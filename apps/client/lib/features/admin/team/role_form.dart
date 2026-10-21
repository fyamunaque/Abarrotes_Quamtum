import 'package:flutter/material.dart';

import '../../../admin/staff/staff.dart';
import '../../../common/api_client.dart';
import '../../../session/staff_permission.dart';
import '../../shared/error_message.dart';
import '../shared/admin_form.dart';
import '../shared/admin_page.dart';

/// Lo que guarda el editor de roles.
typedef RoleInput = ({
  String name,
  Set<StaffPermission> permissions,
  bool active,
});

/// Crear o editar un rol: el nombre y un checklist de permisos agrupado por
/// área, con lo que permite cada uno. El rol del sistema se ve bloqueado:
/// tiene todos los permisos y no se edita ni se borra.
///
/// Cierra con un texto para el aviso de la pantalla ("Creaste el rol…"). Si
/// el servidor rechaza algo (un nombre repetido, borrar un rol con personal
/// asignado), el motivo queda en el formulario.
class RoleForm extends StatefulWidget {
  const RoleForm({super.key, this.role, required this.onSubmit, this.onDelete});

  /// Null para un rol nuevo.
  final StaffRole? role;
  final Future<StaffRole> Function(RoleInput input) onSubmit;
  final Future<void> Function()? onDelete;

  static const maxNameLength = 60;

  @override
  State<RoleForm> createState() => _RoleFormState();
}

class _RoleFormState extends State<RoleForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.role?.name);
  late final Set<StaffPermission> _permissions = {...?widget.role?.permissions};
  late bool _active = widget.role?.active ?? true;
  bool _busy = false;
  String? _error;
  String? _permissionsError;

  bool get _locked => widget.role?.isSystem ?? false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Marcar uno marca también el que necesita; desmarcar uno desmarca los
  /// que lo necesitan.
  void _toggle(StaffPermission permission, bool on) => setState(() {
    _permissionsError = null;
    if (on) {
      _permissions.add(permission);
      if (permission.requires case final required?) {
        _permissions.add(required);
      }
    } else {
      _permissions
        ..remove(permission)
        ..removeWhere((other) => other.requires == permission);
    }
  });

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Escribe un nombre.';
    if (name.length > RoleForm.maxNameLength) {
      return 'Hasta ${RoleForm.maxNameLength} caracteres.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_busy) return;
    final validName = _formKey.currentState!.validate();
    setState(
      () => _permissionsError = _permissions.isEmpty
          ? 'Elige al menos un permiso.'
          : null,
    );
    if (!validName || _permissionsError != null) return;
    final name = _name.text.trim();
    await _run(() async {
      await widget.onSubmit((
        name: name,
        permissions: {..._permissions},
        active: _active,
      ));
      return widget.role == null
          ? 'Creaste el rol $name.'
          : 'Guardaste el rol $name.';
    }, fallback: 'No se pudo guardar el rol.');
  }

  Future<void> _delete() async {
    final role = widget.role!;
    final confirmed = await confirmAction(
      context,
      title: '¿Borrar el rol ${role.name}?',
      message: 'No se puede deshacer.',
      confirmLabel: 'Borrar',
    );
    if (!confirmed) return;
    await _run(() async {
      await widget.onDelete!();
      return 'Borraste el rol ${role.name}.';
    }, fallback: 'No se pudo borrar el rol.');
  }

  /// Corre [action] mostrando el progreso y cierra con su aviso. Si falla,
  /// deja el formulario abierto con el motivo.
  Future<void> _run(
    Future<String> Function() action, {
    required String fallback,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await action();
      if (mounted) Navigator.of(context).pop(message);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error, fallback));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final role = widget.role;
    final editable = !_locked && !_busy;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_locked) ...[
            _LockedNote(name: role!.name),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _name,
            enabled: editable,
            autofocus: role == null,
            decoration: const InputDecoration(
              labelText: 'Nombre del rol',
              hintText: 'Repartidor',
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLength: _locked ? null : RoleForm.maxNameLength,
            validator: _validateName,
          ),
          if (role != null && !_locked)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Rol activo'),
              subtitle: Text(
                _active
                    ? 'Da sus permisos a quienes lo tienen.'
                    : 'No da permisos y no se puede asignar.',
              ),
              value: _active,
              onChanged: editable ? (on) => setState(() => _active = on) : null,
            ),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text('Permisos', style: theme.textTheme.titleMedium),
          ),
          Text(
            _locked
                ? 'Todos, también los que se agreguen.'
                : '${_permissions.length} de ${StaffPermission.values.length}'
                      ' elegidos.',
            style: muted,
          ),
          if (_permissionsError case final error?) ...[
            const SizedBox(height: 4),
            FormError(error),
          ],
          for (final area in PermissionArea.values) ...[
            const SizedBox(height: 12),
            Text(
              area.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            for (final permission in StaffPermission.values)
              if (permission.area == area)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(permission.label),
                  subtitle: Text(switch (permission.requires) {
                    final required? =>
                      '${permission.description} Incluye '
                          '"${required.label}".',
                    null => permission.description,
                  }),
                  value: _locked || _permissions.contains(permission),
                  onChanged: editable
                      ? (on) => _toggle(permission, on ?? false)
                      : null,
                ),
          ],
          const SizedBox(height: 16),
          if (_error case final error?) ...[
            FormError(error),
            const SizedBox(height: 16),
          ],
          if (_locked)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            )
          else
            FormActions(
              submitLabel: role == null ? 'Crear rol' : 'Guardar cambios',
              onSubmit: _submit,
              busy: _busy,
              destructive: widget.onDelete == null
                  ? null
                  : DestructiveButton(
                      label: 'Borrar rol',
                      onPressed: _busy ? null : _delete,
                    ),
            ),
        ],
      ),
    );
  }
}

/// Por qué el rol del sistema no se puede tocar.
class _LockedNote extends StatelessWidget {
  const _LockedNote({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$name es el rol del sistema: tiene todos los permisos, '
                'también los que se agreguen, y no se edita ni se borra. Así '
                'la tienda siempre tiene quien la administre.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
