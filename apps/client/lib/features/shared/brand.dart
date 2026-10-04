import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';

/// El logo de Neil's (naranja con letras crema).
class NeilsLogo extends StatelessWidget {
  const NeilsLogo({super.key, this.height = 40});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height * 0.15),
      child: Image.asset(
        'assets/images/neils_logo.png',
        height: height,
        semanticLabel: "Neil's Food Services",
      ),
    );
  }
}

/// Estructura de las pantallas públicas: barra con el logo y accesos al
/// catálogo y al ingreso, y el contenido centrado con un ancho cómodo en la
/// web.
class PublicScaffold extends StatelessWidget {
  const PublicScaffold({super.key, required this.child, this.maxWidth = 960});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: InkWell(
          onTap: () => context.go(Routes.home),
          child: const NeilsLogo(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go(Routes.catalog),
            child: const Text('Catálogo'),
          ),
          TextButton(
            onPressed: () => context.go(Routes.login),
            child: const Text('Ingresar'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
