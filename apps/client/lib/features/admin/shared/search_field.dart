import 'package:flutter/material.dart';

/// El buscador de una sección del panel: la lupa, [label] y, con texto, la
/// "x" para borrarlo. Mide [width] y queda a la izquierda; en un teléfono
/// (menos de [narrowBelow] px), ocupa todo el ancho.
class PanelSearchField extends StatelessWidget {
  const PanelSearchField({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
    required this.onClear,
    this.width = 320,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final double width;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  static const narrowBelow = 560.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: constraints.maxWidth < narrowBelow
              ? constraints.maxWidth
              : width,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ListenableBuilder(
                listenable: controller,
                builder: (_, _) => controller.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Borrar la búsqueda',
                        icon: const Icon(Icons.close),
                        onPressed: onClear,
                      ),
              ),
            ),
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
