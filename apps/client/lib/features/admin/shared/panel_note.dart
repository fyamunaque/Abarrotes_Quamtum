import 'package:flutter/material.dart';

/// Un texto de ayuda bajo el título de una sección, con el ícono de
/// información: qué significa algo, o por qué no hay un botón (lo que el rol
/// no puede hacer).
class PanelNote extends StatelessWidget {
  const PanelNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 20, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
