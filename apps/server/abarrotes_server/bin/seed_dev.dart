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
/// falta, sin tocar lo que ya hay) y los pedidos se saltan si el cliente de
/// ejemplo ya tiene.
///
/// Con `--reiniciar`, los pedidos de ejemplo se vuelven a generar con fechas
/// hasta hoy, y los vencimientos de ejemplo se fechan desde hoy: así una demo
/// arranca como recién cargada. Los pedidos de otras cuentas no se tocan.
Future<void> main(List<String> args) async {
  const resetFlag = '--reiniciar';
  final reset = args.contains(resetFlag);
  final pod = Serverpod([
    for (final arg in args)
      if (arg != resetFlag) arg,
  ]);
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
      reset ? await resetDevOrders(session) : await seedDevOrders(session),
    ),
    enableLogging: false,
  );
  stdout
    ..writeln(
      products == 0
          ? 'Catálogo: ya estaba completo, no se agregó nada.'
          : 'Catálogo: se agregaron $products productos de ejemplo.',
    )
    ..writeln(switch ((orders, reset)) {
      (0, _) =>
        'Pedidos: el cliente de ejemplo ya tiene pedidos, no se '
            'agregó nada. Para generarlos de nuevo: --reiniciar.',
      (_, true) =>
        'Pedidos: $orders pedidos de ejemplo generados de nuevo, '
            'hasta hoy.',
      _ => 'Pedidos: $orders pedidos de ejemplo en los últimos 30 días.',
    });
  await pod.shutdown(exitProcess: false);
}
