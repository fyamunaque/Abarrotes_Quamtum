import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../../session/session_provider.dart';
import '../shared/brand.dart';
import '../shared/swoosh.dart';

/// Inicio: presentación de la tienda y accesos al catálogo y al registro.
/// Deslizar hacia abajo vuelve a pedir el perfil.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return PublicScaffold(
      onRefresh: () => ref.read(sessionProvider.notifier).refreshProfile(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // El logo ya trae su fondo naranja: hace de portada.
          const Center(child: NeilsLogo(height: 200)),
          const SizedBox(height: 24),
          const _Headline(),
          const SizedBox(height: 12),
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

/// El titular, con el swoosh del logo dibujándose bajo la segunda línea: el
/// único momento animado de la portada.
class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium;
    // MergeSemantics por fuera: así el encabezado y las dos líneas quedan en
    // un solo nodo.
    return MergeSemantics(
      child: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tus abarrotes,', style: style),
            // El swoosh mide lo mismo que la línea que subraya.
            IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('a la puerta de tu casa', style: style),
                  // Sube un poco para pegarse a las letras, como en el logo.
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: const AnimatedSwoosh(),
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
