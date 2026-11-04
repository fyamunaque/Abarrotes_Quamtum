import 'package:flutter/material.dart';

import '../../auth/auth_repository.dart';
import 'auth_form.dart';

/// "¿Olvidaste tu contraseña?": pide el correo (empieza con [email], el que
/// ya se escribió en Ingresar) y manda el enlace con [onSend]. Al salir bien
/// dice lo mismo haya o no una cuenta con ese correo.
Future<void> showPasswordResetDialog(
  BuildContext context, {
  required String email,
  required Future<void> Function(String email) onSend,
}) => showDialog<void>(
  context: context,
  builder: (_) => _PasswordResetDialog(email: email, onSend: onSend),
);

class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog({required this.email, required this.onSend});

  final String email;
  final Future<void> Function(String email) onSend;

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSend(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo enviar el correo. Vuelve a intentar.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_sent) {
      return AlertDialog(
        title: const Text('Revisa tu correo'),
        content: const SizedBox(
          width: 400,
          child: Text(
            'Si hay una cuenta con ese correo, te enviamos un enlace para '
            'crear una contraseña nueva. Revisa también el spam.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      );
    }
    return AlertDialog(
      title: const Text('Recuperar la contraseña'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Escribe el correo de tu cuenta y te enviamos un enlace para '
                'crear una contraseña nueva.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofocus: true,
                textInputAction: TextInputAction.send,
                autofillHints: const [AutofillHints.email],
                validator: validateEmail,
                onFieldSubmitted: (_) => _send(),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _busy ? null : _send,
          child: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar enlace'),
        ),
      ],
    );
  }
}
