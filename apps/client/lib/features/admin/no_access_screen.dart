import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/route_guard.dart';
import '../../router/routes.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import 'admin_shell.dart';

/// "No tienes acceso a esta sección": adonde lleva el guard una sección del
/// panel cuyo permiso no tiene la cuenta (por un enlace guardado, o porque
/// le cambiaron el rol mientras la tenía abierta). Ofrece ir a su sección
/// principal.
class AdminNoAccessScreen extends ConsumerWidget {
  const AdminNoAccessScreen({super.key, this.section});

  /// La ruta que se pidió (`?seccion=`), para nombrar la sección.
  final String? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user,
      _ => null,
    };
    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final requested = switch (section) {
      final path? => AdminSection.of(path),
      null => null,
    };
    final role = switch (user.staffRoleName) {
      final name? => 'Tu rol ($name)',
      null => 'Tu rol',
    };
    final home = panelHomeFor(user);
    final homeSection = AdminSection.of(home);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  'No tienes acceso a esta sección',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                requested == null
                    ? '$role no incluye esta parte del panel.'
                    : '$role no incluye ${requested.label}.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Si la necesitas para tu trabajo, pídele a quien administra '
                'la tienda que la agregue a tu rol.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (homeSection != null)
                FilledButton(
                  onPressed: () => context.go(home),
                  child: Text('Ir a ${homeSection.label}'),
                )
              else ...[
                Text(
                  'Tu rol todavía no tiene ninguna sección del panel.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.go(Routes.home),
                  child: const Text('Ir a la tienda'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
