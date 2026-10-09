import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import 'brand.dart';

/// Ruta inexistente.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PublicScaffold(
      title: 'Página no encontrada',
      child: Column(
        children: [
          Text('No encontramos esta página', style: text.headlineMedium),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go(Routes.home),
            child: const Text('Ir al inicio'),
          ),
        ],
      ),
    );
  }
}
