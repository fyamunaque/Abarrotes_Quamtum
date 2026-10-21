import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Una pestaña de una sección del panel: su nombre, su ícono y su ruta.
typedef PanelTab = ({String label, IconData icon, String path});

/// Las pestañas de una sección (p. ej. Pedidos: todos y para recoger). Cada
/// una es una ruta; [current] es la de la pantalla abierta. En un teléfono
/// van sin ícono, así cada nombre entra en una línea.
class PanelTabs extends StatelessWidget {
  const PanelTabs({super.key, required this.tabs, required this.current});

  final List<PanelTab> tabs;
  final String current;

  /// Desde este ancho, cada pestaña lleva su ícono.
  static const iconsMinWidth = 440.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final icons = constraints.maxWidth >= iconsMinWidth;
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: SegmentedButton<String>(
            segments: [
              for (final tab in tabs)
                ButtonSegment(
                  value: tab.path,
                  label: Text(tab.label),
                  icon: icons ? Icon(tab.icon) : null,
                ),
            ],
            selected: {current},
            showSelectedIcon: false,
            onSelectionChanged: (selected) => context.go(selected.single),
          ),
        );
      },
    );
  }
}
