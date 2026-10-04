import 'package:flutter/material.dart';

/// Un estado como punto de color + texto (el color nunca va solo: el
/// ámbar de "pendiente" no se distingue bien del fondo, y el verde de
/// "confirmado" se parece al azul de "en camino").
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(label)),
      ],
    );
  }
}
