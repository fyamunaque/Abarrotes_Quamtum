import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/stats/stats_providers.dart';
import 'home/home_cards.dart';
import 'shared/admin_page.dart';

/// Inicio del panel: las ventas y los pedidos de un vistazo, las ventas de
/// los últimos 30 días, lo que hay que reponer o vence pronto, y lo que más
/// se vende. Cada bloque carga por su lado.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminPage(
      title: 'Inicio',
      actions: [
        TextButton.icon(
          onPressed: () => ref
            ..invalidate(overviewProvider)
            ..invalidate(salesProvider)
            ..invalidate(lowStockProvider)
            ..invalidate(expiringProvider)
            ..invalidate(topProductsProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
        ),
      ],
      children: const [
        KpiSection(),
        SizedBox(height: 12),
        SalesCard(),
        SizedBox(height: 12),
        ResponsiveGrid(
          minWidth: 300,
          maxColumns: 3,
          children: [LowStockCard(), ExpiringCard(), TopProductsCard()],
        ),
      ],
    );
  }
}
