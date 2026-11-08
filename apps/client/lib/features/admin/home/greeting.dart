import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../session/session.dart';
import '../../../session/session_provider.dart';

/// Lima no cambia de hora en el año: siempre UTC−5.
const _limaOffset = Duration(hours: -5);

/// "Buenos días" antes de las 12 de Lima, "Buenas tardes" antes de las 19 y
/// "Buenas noches" después.
String greetingFor(DateTime utc) {
  final hour = utc.toUtc().add(_limaOffset).hour;
  if (hour < 12) return 'Buenos días';
  if (hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

/// El saludo del inicio del panel: "¡Buenos días, Ana!" y la fecha de hoy en
/// Lima ("Miércoles, 5 de noviembre de 2026").
class PanelGreeting extends ConsumerWidget {
  const PanelGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = switch (ref.watch(sessionProvider)) {
      SignedIn(:final user) => user.name.trim().split(RegExp(r'\s+')).first,
      _ => null,
    };
    final now = DateTime.now().toUtc();
    final lima = now.add(_limaOffset);
    final date = MaterialLocalizations.of(context)
        .formatFullDate(DateTime(lima.year, lima.month, lima.day));
    final greeting = greetingFor(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            name == null ? '¡$greeting!' : '¡$greeting, $name!',
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                date.isEmpty ? date : date[0].toUpperCase() + date.substring(1),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
