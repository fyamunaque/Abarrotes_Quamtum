import 'package:flutter/material.dart';

/// Elegir una cantidad entre 1 y [max] con − y +. [dense] achica los botones
/// (40 px), para las filas de productos.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.max,
    required this.onChanged,
    this.dense = false,
  });

  final int quantity;
  final int max;
  final ValueChanged<int> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          visualDensity: dense ? VisualDensity.compact : null,
          tooltip: 'Quitar uno',
          icon: const Icon(Icons.remove),
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: dense ? 32 : 40),
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            semanticsLabel: 'Cantidad: $quantity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton.outlined(
          visualDensity: dense ? VisualDensity.compact : null,
          tooltip: 'Agregar uno',
          icon: const Icon(Icons.add),
          onPressed: quantity < max ? () => onChanged(quantity + 1) : null,
        ),
      ],
    );
  }
}
