import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// "Colores y tipografía solo desde lib/theme/" (CLAUDE.md): fuera de esa
/// carpeta no hay colores sueltos, ni de Material (`Colors.white`) ni
/// escritos a mano (`Color(0x…)`). `Colors.transparent` no es un color.
void main() {
  test('no hay colores sueltos fuera de lib/theme', () {
    final loose = RegExp(
      r'(^|[^A-Za-z])Colors\.(?!transparent\b)[a-zA-Z0-9]+'
      r'|Color\(0x|Color\.fromARGB|Color\.fromRGBO',
    );
    final found = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      final path = file.path.replaceAll(r'\', '/');
      if (file is! File ||
          !path.endsWith('.dart') ||
          path.startsWith('lib/theme/')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (final (i, line) in lines.indexed) {
        if (loose.hasMatch(line)) found.add('$path:${i + 1}: ${line.trim()}');
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });
}
