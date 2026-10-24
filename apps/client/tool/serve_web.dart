// Sirve la tienda compilada en release (build/web) en http://localhost:5006,
// sin dejar abierto `flutter run`: en una máquina de 8 GB, así alcanza la
// memoria para el servidor, VS Code y el navegador.
//
// Si no hay compilación, o el código cambió desde la última (lib/, web/,
// assets/ o el pubspec), primero compila con `flutter build web --release`.
//
// Uso, desde apps/client: dart run tool/serve_web.dart [--port 5006]
// [--compilar] (compila aunque no haya cambios).
import 'dart:io';

Future<void> main(List<String> args) async {
  final port = switch (args.indexOf('--port')) {
    -1 => 5006,
    final i => int.parse(args[i + 1]),
  };
  final build = Directory('build/web');
  final compiled = File('build/web/main.dart.js');

  if (args.contains('--compilar') || await _outdated(compiled)) {
    stdout.writeln(
      compiled.existsSync()
          ? 'El código cambió desde la última compilación: compilando la '
                'tienda en release (1-2 minutos)...'
          : 'Compilando la tienda en release por primera vez (1-2 minutos)...',
    );
    final flutter = await Process.start(
      'flutter',
      ['build', 'web', '--release'],
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );
    final code = await flutter.exitCode;
    if (code != 0) {
      stderr.writeln('No se pudo compilar la tienda (código $code).');
      exit(code);
    }
  } else {
    stdout.writeln('La tienda compilada está al día: no hace falta compilar.');
  }

  final servers = [
    await _bind(InternetAddress.loopbackIPv4, port),
    // Algunos navegadores van primero a ::1 para "localhost".
    ?await _tryBind(InternetAddress.loopbackIPv6, port),
  ];
  for (final server in servers) {
    server.listen((request) => _serve(build, request));
  }
  stdout.writeln('La tienda está en http://localhost:$port');
  stdout.writeln('Para cerrarla: Ctrl+C (o la papelera de esta terminal).');
}

/// Si hay que compilar: no hay compilación, o algún archivo de lo que entra
/// en ella es más nuevo.
Future<bool> _outdated(File compiled) async {
  if (!compiled.existsSync()) return true;
  final builtAt = compiled.lastModifiedSync();
  final sources = <FileSystemEntity>[
    Directory('lib'),
    Directory('web'),
    Directory('assets'),
    File('pubspec.yaml'),
    File('pubspec.lock'),
  ];
  for (final source in sources) {
    if (source is File) {
      if (source.existsSync() && source.lastModifiedSync().isAfter(builtAt)) {
        return true;
      }
    } else if (source is Directory && source.existsSync()) {
      await for (final entity in source.list(recursive: true)) {
        if (entity is File && entity.lastModifiedSync().isAfter(builtAt)) {
          return true;
        }
      }
    }
  }
  return false;
}

Future<HttpServer> _bind(InternetAddress address, int port) async {
  try {
    return await HttpServer.bind(address, port);
  } on SocketException {
    stderr.writeln(
      'El puerto $port ya está en uso: hay otra tienda corriendo (otra '
      'terminal o una sesión de Claude Code). Ciérrala y vuelve a intentar.',
    );
    exit(1);
  }
}

Future<HttpServer?> _tryBind(InternetAddress address, int port) async {
  try {
    return await HttpServer.bind(address, port);
  } on SocketException {
    return null;
  }
}

/// El archivo pedido, o index.html para las rutas de la app (/catalogo,
/// /admin...), que resuelve go_router. Nada fuera de build/web.
Future<void> _serve(Directory build, HttpRequest request) async {
  final response = request.response;
  try {
    final root = build.absolute.uri;
    final path = Uri.decodeComponent(request.uri.path).replaceFirst('/', '');
    final target = root.resolve(path);
    var file = File.fromUri(target);
    if (!target.path.startsWith(root.path) || !file.existsSync()) {
      file = File.fromUri(root.resolve('index.html'));
    }
    final name = file.path.toLowerCase();
    final dot = name.lastIndexOf('.');
    response.headers
      ..contentType = _types[dot == -1 ? '' : name.substring(dot)]
      // Siempre lo último compilado.
      ..set(HttpHeaders.cacheControlHeader, 'no-cache');
    await response.addStream(file.openRead());
  } catch (error) {
    response.statusCode = HttpStatus.internalServerError;
    response.write('$error');
  } finally {
    await response.close();
  }
}

final _types = {
  '.html': ContentType.html,
  '.js': ContentType('text', 'javascript', charset: 'utf-8'),
  '.mjs': ContentType('text', 'javascript', charset: 'utf-8'),
  '.json': ContentType.json,
  '.css': ContentType('text', 'css', charset: 'utf-8'),
  '.wasm': ContentType('application', 'wasm'),
  '.png': ContentType('image', 'png'),
  '.jpg': ContentType('image', 'jpeg'),
  '.svg': ContentType('image', 'svg+xml'),
  '.ico': ContentType('image', 'x-icon'),
  '.ttf': ContentType('font', 'ttf'),
  '.otf': ContentType('font', 'otf'),
  '.woff2': ContentType('font', 'woff2'),
  '.bin': ContentType.binary,
};
