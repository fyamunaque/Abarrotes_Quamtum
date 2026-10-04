import 'package:flutter/material.dart';

import '../shared/brand.dart';

/// Catálogo de productos. Todavía sin datos: se conecta a `GET /products` del
/// servidor en un próximo paso.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PublicScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Catálogo', style: text.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Muy pronto vas a ver aquí los productos de la tienda.',
            style: text.bodyLarge,
          ),
        ],
      ),
    );
  }
}
