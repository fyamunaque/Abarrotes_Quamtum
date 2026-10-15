import 'package:flutter/material.dart';

import '../../shared/error_message.dart';
import '../shared/admin_form.dart';

/// Pide el código de recojo que muestra el cliente en caja y entrega el
/// pedido con [onSubmit]. Si el servidor lo rechaza (el código no coincide),
/// el motivo queda en el diálogo para volver a escribirlo. Devuelve true si
/// se entregó.
Future<bool> showPickupCodeDialog(
  BuildContext context, {
  required Future<void> Function(String code) onSubmit,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _PickupCodeDialog(onSubmit: onSubmit),
    ) ??
    false;

class _PickupCodeDialog extends StatefulWidget {
  const _PickupCodeDialog({required this.onSubmit});

  final Future<void> Function(String code) onSubmit;

  @override
  State<_PickupCodeDialog> createState() => _PickupCodeDialogState();
}

class _PickupCodeDialogState extends State<_PickupCodeDialog> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(code);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = errorMessage(error, 'No se pudo entregar el pedido.'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Entregar el pedido'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _code,
            autofocus: true,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Código de recojo',
              helperText: 'El que muestra el cliente.',
            ),
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            maxLength: 6,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _submit(),
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 8),
            FormError(error),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Volver'),
        ),
        ListenableBuilder(
          listenable: _code,
          builder: (_, _) => FilledButton(
            onPressed: _busy || _code.text.trim().isEmpty ? null : _submit,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Marcar recogido'),
          ),
        ),
      ],
    );
  }
}
