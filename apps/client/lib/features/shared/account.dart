import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';

/// La cuenta en la barra. En pantallas anchas: el enlace al panel (admin y
/// staff, fuera del panel), el primer nombre y "Salir". En un teléfono eso no
/// entra junto al resto de la barra, así que va en un menú.
class AccountActions extends StatelessWidget {
  const AccountActions(this.user, {super.key, this.inPanel = false});

  final SessionUser user;

  /// Dentro del panel: muestra el rol y no el enlace al panel.
  final bool inPanel;

  /// Desde este ancho, la cuenta va en la barra; por debajo, en el menú.
  static const wideFrom = 600.0;

  @override
  Widget build(BuildContext context) {
    final panelLink = !inPanel && user.role.isStaff;
    if (MediaQuery.sizeOf(context).width < wideFrom) {
      return _AccountMenu(user, panelLink: panelLink);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (panelLink)
          TextButton(
            onPressed: () => context.go(Routes.admin),
            child: const Text('Panel'),
          ),
        _UserName(user, showRole: inPanel),
        const _SignOutButton(),
      ],
    );
  }
}

/// El primer nombre de la cuenta. El nombre completo y el correo van en el
/// tooltip.
class _UserName extends StatelessWidget {
  const _UserName(this.user, {required this.showRole});

  final SessionUser user;
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
class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => ref.read(sessionProvider.notifier).signOut(),
      child: const Text('Salir'),
    );
  }
}

enum _AccountAction { panel, signOut }

/// La cuenta en un teléfono: un ícono que abre el nombre, el correo y las
/// acciones.
class _AccountMenu extends ConsumerWidget {
  const _AccountMenu(this.user, {required this.panelLink});

  final SessionUser user;
  final bool panelLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_AccountAction>(
      tooltip: 'Tu cuenta',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (action) => switch (action) {
        _AccountAction.panel => context.go(Routes.admin),
        _AccountAction.signOut => ref.read(sessionProvider.notifier).signOut(),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(user.name),
            subtitle: Text(user.email),
          ),
        ),
        const PopupMenuDivider(),
        if (panelLink)
          const PopupMenuItem(
            value: _AccountAction.panel,
            child: Text('Panel'),
          ),
        const PopupMenuItem(
          value: _AccountAction.signOut,
          child: Text('Salir'),
        ),
      ],
    );
  }
}
