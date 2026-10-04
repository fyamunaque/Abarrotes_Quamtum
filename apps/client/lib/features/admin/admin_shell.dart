import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import '../shared/account.dart';
import '../shared/brand.dart';

/// Layout común de /admin. Solo se llega aquí con una sesión de admin o
/// staff, o mientras la sesión carga (ver route_guard.dart): en ese caso
/// muestra un indicador hasta que el guard decide.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: const Row(
          children: [
            NeilsLogo(),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'Panel de la tienda',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go(Routes.home),
            child: const Text('Ir a la tienda'),
          ),
          if (session case SignedIn(:final user)) ...[
            UserName(user, showRole: true),
            const SignOutButton(),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: switch (session) {
          SignedIn() => child,
          _ => const Center(
            child: CircularProgressIndicator(semanticsLabel: 'Cargando'),
          ),
        },
      ),
    );
  }
}
