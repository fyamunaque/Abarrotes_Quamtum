import 'package:flutter/material.dart';

/// Dos campos lado a lado cuando hay lugar (en el diálogo), uno debajo del
/// otro en el teléfono.
class FieldPair extends StatelessWidget {
  const FieldPair(this.first, this.second, {super.key});

  final Widget first;
  final Widget second;

  static const _sideBySideFrom = 420.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _sideBySideFrom) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 16), second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 16),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

/// El error de un formulario (lo que respondió el servidor), anunciado al
/// lector de pantalla cuando aparece.
class FormError extends StatelessWidget {
  const FormError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// Los botones de un formulario del panel. En el diálogo, [destructive] a la
/// izquierda (dar de baja, eliminar) y a la derecha "Cancelar" y la acción
/// principal. En el teléfono, uno debajo del otro: la principal a todo el
/// ancho y la destructiva al final, separada.
class FormActions extends StatelessWidget {
  const FormActions({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    required this.busy,
    this.destructive,
  });

  final String submitLabel;
  final VoidCallback onSubmit;

  /// Mientras se guarda: los botones se apagan y el principal muestra el
  /// progreso.
  final bool busy;

  final Widget? destructive;

  static const _inlineFrom = 400.0;

  @override
  Widget build(BuildContext context) {
    final submit = FilledButton(
      onPressed: busy ? null : onSubmit,
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(submitLabel),
    );
    final cancel = TextButton(
      onPressed: busy ? null : () => Navigator.of(context).pop(),
      child: const Text('Cancelar'),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _inlineFrom) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              submit,
              const SizedBox(height: 8),
              cancel,
              if (destructive case final destructive?) ...[
                const SizedBox(height: 24),
                destructive,
              ],
            ],
          );
        }
        return Row(
          children: [
            if (destructive case final destructive?) ...[
              destructive,
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                // Si no entran en una línea, uno debajo del otro.
                child: OverflowBar(
                  spacing: 8,
                  overflowSpacing: 8,
                  overflowAlignment: OverflowBarAlignment.end,
                  children: [cancel, submit],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Un botón para una acción que no se deshace fácil, en el color de error.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
