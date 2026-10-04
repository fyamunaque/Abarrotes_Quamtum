import 'dart:io';

import 'package:abarrotes_server/src/dev/dev_seed.dart';
import 'package:abarrotes_server/src/generated/serverpod.dart';

/// Carga el catálogo y los pedidos de ejemplo en la base de development:
///
/// ```powershell
/// dart run bin/seed_dev.dart
/// ```
///
/// Se niega en cualquier otro modo. El catálogo se completa (agrega lo que
/// falta, sin tocar lo que ya hay) y los pedidos se saltan si ya hay pedidos.
Future<void> main(List<String> args) async {
  final pod = Serverpod(args);
  if (pod.runMode != ServerpodRunMode.development) {
    stderr.writeln(
      'El seed solo corre en development (el modo es ${pod.runMode}).',
    );
    exitCode = 1;
    return;
  }

  final (products, orders) = await pod.withSession(
    (session) async => (
      await seedDevData(session),
      await seedDevOrders(session),
    ),
    enableLogging: false,
  );
  stdout
    ..writeln(
      products == 0
          ? 'Catálogo: ya estaba completo, no se agregó nada.'
          : 'Catálogo: se agregaron $products productos de ejemplo.',
    )
    ..writeln(
      orders == 0
          ? 'Pedidos: la base ya tiene pedidos, no se agregó nada.'
          : 'Pedidos: $orders pedidos de ejemplo en los últimos 30 días.',
    );
  await pod.shutdown(exitProcess: false);
}
