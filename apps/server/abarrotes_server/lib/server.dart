import 'src/generated/serverpod.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Serverpod ya trae configurados el Protocol y los Endpoints generados.
  final pod = Serverpod(args);

  await pod.start();
}
