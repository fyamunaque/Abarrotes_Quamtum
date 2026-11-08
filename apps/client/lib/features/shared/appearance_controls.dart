import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../appearance/appearance.dart';
import '../../appearance/appearance_providers.dart';

/// El ícono y el nombre de cada apariencia.
extension on ThemePreference {
  IconData get icon => switch (this) {
    ThemePreference.system => Icons.smartphone_outlined,
    ThemePreference.light => Icons.light_mode_outlined,
    ThemePreference.dark => Icons.dark_mode_outlined,
  };

  String get label => switch (this) {
    ThemePreference.system => 'Sistema',
    ThemePreference.light => 'Claro',
    ThemePreference.dark => 'Oscuro',
  };
}

/// Sistema, Claro u Oscuro en tres botones iguales, el ícono arriba y el
/// nombre abajo (el menú lateral del teléfono). No es un `SegmentedButton`:
/// así entra en 320 px con el texto al 130 %, achicando el nombre si hace
/// falta, y cada botón conserva sus 48 dp.
class AppearanceSelector extends ConsumerWidget {
  const AppearanceSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appearanceProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Row(
              children: [
                for (final option in ThemePreference.values)
                  Expanded(
                    child: _Option(
                      option: option,
                      selected: option == current,
                      onTap: () =>
                          ref.read(appearanceProvider.notifier).set(option),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sistema sigue al modo de tu teléfono.',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ThemePreference option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerLowest,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(option.icon, size: 20, color: color),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      option.label,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La apariencia desde un botón con su menú (las barras de escritorio de la
/// tienda y del panel). El ícono muestra el modo elegido.
class AppearanceButton extends ConsumerWidget {
  const AppearanceButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appearanceProvider);
    return MenuAnchor(
      builder: (context, controller, _) => IconButton(
        tooltip: 'Apariencia',
        icon: Icon(current.icon),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        for (final option in ThemePreference.values)
          MenuItemButton(
            leadingIcon: Icon(option.icon),
            trailingIcon: option == current ? const Icon(Icons.check) : null,
            onPressed: () => ref.read(appearanceProvider.notifier).set(option),
            child: Text(option.label),
          ),
      ],
    );
  }
}
