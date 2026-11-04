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
        _StockAndTopProducts(),
      ],
    );
  }
}

/// Stock bajo y Por vencer, una sobre otra, con Más vendidos al lado: así
/// ninguna tarjeta queda con un hueco por tener el alto de la más larga.
/// En un teléfono, una debajo de otra.
class _StockAndTopProducts extends StatelessWidget {
  const _StockAndTopProducts();

  /// El ancho mínimo de cada columna.
  static const _minColumnWidth = 300.0;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _minColumnWidth * 2 + _gap) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LowStockCard(),
              SizedBox(height: _gap),
              ExpiringCard(),
              SizedBox(height: _gap),
              TopProductsCard(),
            ],
          );
        }
        // Las dos columnas del mismo alto: la más corta estira su última
        // tarjeta.
        return const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LowStockCard(),
                    SizedBox(height: _gap),
                    Expanded(child: ExpiringCard()),
                  ],
                ),
              ),
              SizedBox(width: _gap),
              Expanded(child: TopProductsCard()),
            ],
          ),
        );
      },
    );
  }
}
