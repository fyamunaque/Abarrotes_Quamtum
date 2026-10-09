import 'package:flutter/material.dart';

import '../../catalog/product.dart';
import '../../orders/order_status.dart';
import '../catalog/product_card.dart';
import '../catalog/product_grid.dart';
import '../orders/order_tracker.dart';
import '../shared/brand.dart';

/// Vitrina: los componentes con datos de ejemplo, para verlos y revisarlos
/// antes de que tengan pantallas con datos reales. Solo existe en debug (ver
/// router.dart).
class ShowcaseScreen extends StatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  var _status = OrderStatus.pendingConfirmation;

  static const _products = [
    Product(id: 'arroz', name: 'Arroz extra 5 kg', priceCents: 2490, stock: 12),
    Product(
      id: 'aceite',
      name: 'Aceite vegetal 1 L',
      priceCents: 1090,
      promoPriceCents: 890,
      stock: 30,
    ),
    Product(
      id: 'leche',
      name: 'Leche evaporada entera, paquete de 6 latas de 400 g',
      priceCents: 2350,
      stock: 8,
    ),
    Product(id: 'azucar', name: 'Azúcar rubia 1 kg', priceCents: 450, stock: 0),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PublicScaffold(
      title: 'Vitrina',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vitrina', style: text.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Componentes con datos de ejemplo. Esta página solo existe en '
            'los builds de debug.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 32),
          Text('Tarjetas de producto', style: text.titleLarge),
          const SizedBox(height: 12),
          ProductGrid(
            children: [
              for (final product in _products)
                ProductCard(
                  product: product,
                  onAdd: () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text('Agregaste ${product.name}')),
                    ),
                ),
            ],
          ),
          const SizedBox(height: 40),
          Text('Seguimiento de pedido', style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Elige un estado para ver cómo se llena la línea.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          OrderTracker(status: _status),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in OrderStatus.values)
                ChoiceChip(
                  label: Text(status.label),
                  selected: status == _status,
                  onSelected: (_) => setState(() => _status = status),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
