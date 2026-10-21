import 'package:flutter/material.dart';

/// Los chips de un filtro con una sola opción elegida (p. ej. el estado). En
/// el teléfono van en una fila que se desliza de lado, así no ocupan varias
/// filas antes de la tabla; en pantallas anchas (desde [wrapMinWidth] px)
/// bajan a otra fila si no entran: con el mouse no se desliza de lado.
class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  /// Cada opción con su texto, en orden.
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  static const wrapMinWidth = 600.0;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final (value, label) in options)
        ChoiceChip(
          label: Text(label),
          selected: value == selected,
          onSelected: (_) => onSelected(value),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= wrapMinWidth
          ? Wrap(spacing: 8, runSpacing: 8, children: chips)
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final chip in chips)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: chip,
                    ),
                ],
              ),
            ),
    );
  }
}
