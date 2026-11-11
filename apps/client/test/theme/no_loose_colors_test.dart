import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// "Colores y tipografía solo desde lib/theme/" (CLAUDE.md).
void main() {
  /// Las líneas de lib/ fuera de lib/theme que cumplen [pattern], salvo los
  /// archivos de [except].
  List<String> linesOutsideTheme(
    RegExp pattern, {
    Set<String> except = const {},
  }) {
    final found = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      final path = file.path.replaceAll(r'\', '/');
      if (file is! File ||
          !path.endsWith('.dart') ||
          path.startsWith('lib/theme/') ||
          except.contains(path)) {
        continue;
      }
      for (final (i, line) in file.readAsLinesSync().indexed) {
        if (pattern.hasMatch(line)) found.add('$path:${i + 1}: ${line.trim()}');
      }
    }
    return found;
  }

  // Ni de Material (`Colors.white`) ni escritos a mano (`Color(0x…)`).
  // `Colors.transparent` no es un color.
  test('no hay colores sueltos fuera de lib/theme', () {
    final found = linesOutsideTheme(
      RegExp(
        r'(^|[^A-Za-z])Colors\.(?!transparent\b)[a-zA-Z0-9]+'
        r'|Color\(0x|Color\.fromARGB|Color\.fromRGBO',
      ),
    );
    expect(found, isEmpty, reason: found.join('\n'));
  });

  // Las constantes de la marca y de los estados son para armar las paletas
  // en lib/theme; las pantallas leen la paleta del tema (claro u oscuro).
  test('los colores de la marca solo desde la paleta del tema', () {
    final found = linesOutsideTheme(
      RegExp(
        r'NeilsColors\.|OrderStatusColors\.|StateColors\.'
        r'|PlaceholderColors\.|neilsCardShadow',
      ),
    );
    expect(found, isEmpty, reason: found.join('\n'));
  });
}
