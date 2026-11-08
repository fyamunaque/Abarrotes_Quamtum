import 'package:flutter/material.dart';

/// Elegir una cantidad entre 1 y [max] con − y +. [dense] achica el círculo
/// de los botones (40 px), para las filas de productos; el área que se toca
/// sigue siendo de 48.
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

  /// Compacto: el círculo de 40, con el área táctil de 48 alrededor.
  static final _denseStyle = IconButton.styleFrom(
    minimumSize: const Size.square(40),
    fixedSize: const Size.square(40),
    padding: EdgeInsets.zero,
    tapTargetSize: MaterialTapTargetSize.padded,
  );

  @override
  Widget build(BuildContext context) {
    final style = dense ? _denseStyle : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          style: style,
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
          style: style,
          tooltip: 'Agregar uno',
          icon: const Icon(Icons.add),
          onPressed: quantity < max ? () => onChanged(quantity + 1) : null,
        ),
      ],
    );
  }
}
