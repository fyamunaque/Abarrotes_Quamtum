import 'dart:io';

import 'package:abarrotes_server/src/dev/dev_seed.dart';
import 'package:abarrotes_server/src/generated/serverpod.dart';

/// Carga el catálogo de ejemplo en la base de development:
///
/// ```powershell
/// dart run bin/seed_dev.dart
/// ```
///
/// Se niega en cualquier otro modo, y no hace nada si ya hay productos.
Future<void> main(List<String> args) async {
  final pod = Serverpod(args);
  if (pod.runMode != ServerpodRunMode.development) {
    stderr.writeln(
      'El seed solo corre en development (el modo es ${pod.runMode}).',
    );
    exitCode = 1;
    return;
  }

  final created = await pod.withSession(
    (session) => seedDevData(session),
    enableLogging: false,
  );
  stdout.writeln(
    created == 0
        ? 'La base ya tiene productos: no se agregó nada.'
        : 'Listo: $created productos de ejemplo en 5 categorías.',
  );
  await pod.shutdown(exitProcess: false);
}
