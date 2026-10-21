import 'package:flutter/material.dart';

import '../../../admin/vip/vip_customer.dart';
import '../../../theme/brand_colors.dart';
import '../../shared/error_message.dart';
import '../shared/admin_form.dart';

/// Agregar clientes VIP: un correo (que se valida antes de mandarlo) o varios
/// pegados de una vez. Al enviar no se cierra: muestra lo que respondió el
/// servidor (agregados, ya estaban, no válidos). "Listo" cierra con ese
/// resumen.
class VipAddForm extends StatefulWidget {
  const VipAddForm({super.key, required this.onSubmit});

  final Future<VipAddSummary> Function(List<String> emails) onSubmit;

  @override
  State<VipAddForm> createState() => _VipAddFormState();
}

enum _Mode { one, many }

class _VipAddFormState extends State<VipAddForm> {
  final _formKey = GlobalKey<FormState>();
  final _one = TextEditingController();
  final _many = TextEditingController();
  _Mode _mode = _Mode.one;
  bool _busy = false;
  String? _error;
  VipAddSummary? _summary;

  @override
  void dispose() {
    _one.dispose();
    _many.dispose();
    super.dispose();
  }

  List<String> get _pasted => splitEmails(_many.text);

  String? _validateOne(String? value) {
    final email = normalizeEmail(value ?? '');
    if (email.isEmpty) return 'Escribe un correo.';
    if (!isValidEmail(email)) return 'Escribe un correo como nombre@gmail.com.';
    return null;
  }

  String? _validateMany(String? _) {
    final count = _pasted.length;
    if (count == 0) return 'Pega al menos un correo.';
    if (count > maxEmailsPerAdd) {
      return 'Hasta $maxEmailsPerAdd por vez: hay $count.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    // Varios: se mandan todos; el servidor dice cuáles no son válidos.
    final emails = _mode == _Mode.one ? [_one.text.trim()] : _pasted;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final summary = await widget.onSubmit(emails);
      if (mounted) setState(() => _summary = summary);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = errorMessage(
            error,
            'No se pudieron agregar los correos.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addMore() => setState(() {
    _summary = null;
    _one.clear();
    _many.clear();
  });

  @override
  Widget build(BuildContext context) {
    if (_summary case final summary?) {
      return _SummaryView(
        summary: summary,
        onAddMore: _addMore,
        onDone: () => Navigator.of(context).pop(summary),
      );
    }
    final count = _pasted.length;
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<_Mode>(
            segments: const [
              ButtonSegment(
                value: _Mode.one,
                label: Text('Un correo'),
                icon: Icon(Icons.person_outline),
              ),
              ButtonSegment(
                value: _Mode.many,
                label: Text('Varios'),
                icon: Icon(Icons.group_add_outlined),
              ),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: _busy
                ? null
                : (selected) => setState(() {
                    _mode = selected.single;
                    _error = null;
                  }),
          ),
          const SizedBox(height: 16),
          if (_mode == _Mode.one)
            TextFormField(
              key: const ValueKey('one'),
              controller: _one,
              enabled: !_busy,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Correo',
                hintText: 'nombre@gmail.com',
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              validator: _validateOne,
              onFieldSubmitted: (_) => _submit(),
            )
          else
            TextFormField(
              key: const ValueKey('many'),
              controller: _many,
              enabled: !_busy,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Correos',
                hintText: 'ana@gmail.com, luis@hotmail.com\nmaria@gmail.com',
                helperText: count == 0
                    ? 'Sepáralos con comas o ponlos en líneas distintas.'
                    : '$count ${count == 1 ? 'correo' : 'correos'}. '
                          'Los que no sean válidos se te avisan.',
                helperMaxLines: 2,
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.multiline,
              autocorrect: false,
              minLines: 5,
              maxLines: 10,
              onChanged: (_) => setState(() {}),
              validator: _validateMany,
            ),
          const SizedBox(height: 8),
          Text(
            'Ven las promociones VIP cuando ingresan con ese correo y lo '
            'tienen verificado.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (_error case final error?) ...[
            FormError(error),
            const SizedBox(height: 16),
          ],
          FormActions(submitLabel: 'Agregar', onSubmit: _submit, busy: _busy),
        ],
      ),
    );
  }
}

/// Lo que respondió el servidor, en tres grupos (solo los que tienen algo).
class _SummaryView extends StatelessWidget {
  const _SummaryView({
    required this.summary,
    required this.onAddMore,
    required this.onDone,
  });

  final VipAddSummary summary;
  final VoidCallback onAddMore;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final added = summary.added.length;
    final sent = added + summary.duplicates.length + summary.invalid.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            added == 0
                ? 'No se agregó ningún correo.'
                : added == sent
                ? 'Listo: ${_people(added)} ${added == 1 ? 'es' : 'son'} VIP.'
                : 'Se agregaron $added de $sent.',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 16),
        if (summary.added.isNotEmpty)
          _SummaryGroup(
            icon: Icons.check_circle_outline,
            color: OrderStatusColors.confirmed,
            title: 'Agregados (${summary.added.length})',
            emails: summary.added,
          ),
        if (summary.duplicates.isNotEmpty)
          _SummaryGroup(
            icon: Icons.info_outline,
            color: theme.colorScheme.onSurfaceVariant,
            title: 'Ya estaban (${summary.duplicates.length})',
            note: 'Ya eran VIP o se repetían en la lista.',
            emails: summary.duplicates,
          ),
        if (summary.invalid.isNotEmpty)
          _SummaryGroup(
            icon: Icons.error_outline,
            color: theme.colorScheme.error,
            title: 'No son correos válidos (${summary.invalid.length})',
            note: 'Revísalos y vuelve a agregarlos.',
            emails: summary.invalid,
          ),
        const SizedBox(height: 8),
        OverflowBar(
          alignment: MainAxisAlignment.end,
          spacing: 8,
          overflowSpacing: 8,
          overflowAlignment: OverflowBarAlignment.end,
          children: [
            TextButton(onPressed: onAddMore, child: const Text('Agregar más')),
            FilledButton(onPressed: onDone, child: const Text('Listo')),
          ],
        ),
      ],
    );
  }

  static String _people(int count) =>
      count == 1 ? 'el correo' : 'los $count correos';
}

class _SummaryGroup extends StatelessWidget {
  const _SummaryGroup({
    required this.icon,
    required this.color,
    required this.title,
    required this.emails,
    this.note,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? note;
  final List<String> emails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelLarge),
                if (note case final note?) Text(note, style: muted),
                const SizedBox(height: 4),
                for (final email in emails)
                  Text(
                    email.isEmpty ? '(vacío)' : email,
                    style: theme.textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
