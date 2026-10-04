import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/session.dart';
import '../../session/session_provider.dart';

/// El primer nombre de la cuenta, para la barra. El nombre completo y el
/// correo van en el tooltip.
class UserName extends StatelessWidget {
  const UserName(this.user, {super.key, this.showRole = false});

  final SessionUser user;

  /// En el panel se muestra también el rol (admin o staff).
  final bool showRole;

  @override
  Widget build(BuildContext context) {
    final firstName = user.name.trim().split(RegExp(r'\s+')).first;
    return Tooltip(
      message: '${user.name}\n${user.email}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Center(
            widthFactor: 1,
            child: Text(
              showRole ? '$firstName · ${user.role.name}' : firstName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cierra la sesión. En /admin el guard lleva después al ingreso; en las
/// pantallas públicas se queda donde está.
class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => ref.read(sessionProvider.notifier).signOut(),
      child: const Text('Salir'),
    );
  }
}
