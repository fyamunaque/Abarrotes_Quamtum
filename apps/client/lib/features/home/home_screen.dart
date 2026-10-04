import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../../theme/brand_colors.dart';
import '../shared/brand.dart';

/// Inicio: presentación de la tienda y accesos al catálogo y al registro.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PublicScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NeilsColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: NeilsLogo(height: 120)),
          ),
          const SizedBox(height: 24),
          Text(
            'Tus abarrotes, a la puerta de tu casa',
            style: text.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Arroz, aceite, lácteos y todo lo de la semana, con los precios '
            'y promociones de la tienda.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () => context.go(Routes.catalog),
                child: const Text('Ver el catálogo'),
              ),
              OutlinedButton(
                onPressed: () => context.go(Routes.register),
                child: const Text('Crear una cuenta'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
