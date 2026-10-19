import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../store/store_providers.dart';
import '../../store/store_settings.dart';
import 'info_line.dart';

/// Dónde y cuándo se recoge un pedido: la dirección de la tienda (con su
/// referencia), el teléfono, el horario y, con [withInstructions], qué hacer
/// al llegar. Mientras cargan los datos, un indicador; si fallan, el aviso
/// con "Reintentar".
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
          InfoLine(
            icon: Icons.place_outlined,
            text: store.address.isEmpty
                ? 'La tienda todavía no publicó su dirección.'
                : store.address,
            detail: store.reference,
          ),
          if (store.phone case final phone?)
            InfoLine(icon: Icons.phone_outlined, text: phone),
          if (store.openingHours case final hours?)
            InfoLine(icon: Icons.schedule, text: hours),
          if (withInstructions)
            if (store.pickupInstructions case final instructions?)
              InfoLine(icon: Icons.info_outline, text: instructions),
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
