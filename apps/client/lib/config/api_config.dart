import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../common/api_client.dart';

/// Dirección de las rutas REST del servidor (apps/server, puerto 8082).
///
/// Se elige al compilar: `--dart-define=API_URL=https://api.tienda.pe`. Si no
/// se pasa, la del servidor local: `localhost` desde la web y `10.0.2.2` desde
/// el emulador de Android (así ve el emulador a la máquina donde corre). En un
/// teléfono real hay que pasar la IP de la máquina en la red local.
final Uri apiBaseUrl = () {
  const fromBuild = String.fromEnvironment('API_URL');
  if (fromBuild.isNotEmpty) return Uri.parse(fromBuild);
  return Uri.parse(kIsWeb ? 'http://localhost:8082' : 'http://10.0.2.2:8082');
}();

/// El cliente HTTP de las rutas REST, compartido por los repositorios.
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return ApiClient(client, baseUrl: apiBaseUrl);
});
