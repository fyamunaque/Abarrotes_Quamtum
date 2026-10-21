import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import 'error_message.dart';

/// "Verifica tu correo para completar tu cuenta", para una cuenta que todavía
/// no confirmó su correo: mandar el correo otra vez y, al volver, "Ya lo
/// verifiqué" (que vuelve a pedir el perfil). Es un aviso genérico: no dice
/// qué cambia al verificar.
class VerifyEmailNotice extends ConsumerStatefulWidget {
  const VerifyEmailNotice(this.user, {super.key});

  final SessionUser user;

  @override
  ConsumerState<VerifyEmailNotice> createState() => _VerifyEmailNoticeState();
}

class _VerifyEmailNoticeState extends ConsumerState<VerifyEmailNotice> {
  bool _busy = false;

  /// Lo último que pasó, para la persona (enviado, todavía sin verificar o un
  /// error).
  String? _status;

  Future<void> _send() => _run(() async {
    await ref.read(authRepositoryProvider).sendEmailVerification();
    return 'Te enviamos un correo a ${widget.user.email}. Ábrelo, confirma y '
        'vuelve aquí.';
  });

  Future<void> _check() => _run(() async {
    await ref.read(sessionProvider.notifier).refreshProfile();
    // Si ya está confirmado, el aviso desaparece solo (la sesión cambió).
    return 'Todavía no vemos tu correo confirmado. Revisa tu bandeja de '
        'entrada y la de spam.';
  });

  Future<void> _run(Future<String> Function() action) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final status = await action();
      if (mounted) setState(() => _status = status);
    } catch (error) {
      if (mounted) {
        setState(
          () => _status = errorMessage(
            error,
            'No se pudo completar. Vuelve a intentar.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.mark_email_unread_outlined, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verifica tu correo para completar tu cuenta.',
                    style: theme.textTheme.titleSmall,
                  ),
                  if (_status case final status?)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(status, style: theme.textTheme.bodySmall),
                      ),
                    ),
                  Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: _busy ? null : _send,
                        child: const Text('Enviar el correo'),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _check,
                        child: const Text('Ya lo verifiqué'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
