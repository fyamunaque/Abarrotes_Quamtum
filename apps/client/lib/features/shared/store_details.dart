import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store/store_providers.dart';
import '../../store/store_settings.dart';

/// Dónde y cuándo se recoge un pedido: la dirección de la tienda (con su
/// referencia), el horario y, con [withInstructions], qué hacer al llegar.
/// Mientras cargan los datos, un indicador; si fallan, el aviso con
/// "Reintentar".
class StoreDetails extends ConsumerWidget {
  const StoreDetails({super.key, this.withInstructions = true});

  final bool withInstructions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return switch (ref.watch(storeSettingsProvider)) {
      AsyncValue(value: final store?) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Line(
            icon: Icons.place_outlined,
            text: store.address.isEmpty
                ? 'La tienda todavía no publicó su dirección.'
                : store.address,
            detail: store.reference,
          ),
          if (store.openingHours case final hours?)
            _Line(icon: Icons.schedule, text: hours),
          if (withInstructions)
            if (store.pickupInstructions case final instructions?)
              _Line(icon: Icons.info_outline, text: instructions),
        ],
      ),
      AsyncError() => Row(
        children: [
          Expanded(
            child: Text(
              'No se pudieron cargar los datos de la tienda.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(storeSettingsProvider),
            child: const Text('Reintentar'),
          ),
        ],
      ),
      _ => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
    };
  }
}

/// El nombre de la tienda, o "la tienda" mientras cargan los datos.
String storeNameOf(AsyncValue<StoreSettings> store) =>
    store.value?.name ?? 'la tienda';

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.detail});

  final IconData icon;
  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: theme.textTheme.bodyMedium),
                if (detail case final detail?)
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
