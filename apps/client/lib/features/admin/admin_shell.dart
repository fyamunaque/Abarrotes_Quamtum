import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import '../shared/brand.dart';

/// Layout común de /admin. Solo se llega aquí con una sesión de admin o
/// staff (ver route_guard.dart).
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
            Text('Panel de la tienda'),
          ],
        ),
        actions: [
          if (session case SignedIn(:final user))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: Text('${user.name} · ${user.role.name}')),
            ),
          TextButton(
            onPressed: () => context.go(Routes.home),
            child: const Text('Ir a la tienda'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: child),
    );
  }
}
