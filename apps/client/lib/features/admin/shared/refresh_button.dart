import 'package:flutter/material.dart';

/// "Actualizar" de una tabla del panel: vuelve a pedir la página que se está
/// viendo. Mientras tanto muestra un indicador; si falla, lo avisa y la
/// tabla queda como estaba.
class RefreshButton extends StatefulWidget {
  const RefreshButton({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  State<RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<RefreshButton> {
  bool _busy = false;

  Future<void> _refresh() async {
    setState(() => _busy = true);
    try {
      await widget.onRefresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('No se pudo actualizar.')),
          );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _busy ? null : _refresh,
      icon: _busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh),
      label: const Text('Actualizar'),
    );
  }
}
