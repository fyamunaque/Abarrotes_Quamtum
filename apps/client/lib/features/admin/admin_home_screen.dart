import 'package:flutter/material.dart';

/// Inicio del panel. Las secciones (pedidos, productos, inventario,
/// estadísticas) llegan como subrutas de /admin.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Bienvenido al panel', style: text.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Aquí vas a manejar pedidos, productos, inventario y estadísticas.',
          style: text.bodyLarge,
        ),
      ],
    );
  }
}
