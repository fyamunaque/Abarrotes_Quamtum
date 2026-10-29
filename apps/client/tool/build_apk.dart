// Genera el APK de la app con su número de versión, para el teléfono por cable
// USB (ver "Tu teléfono Android por cable USB" en docs/DEMO.md).
//
// 1. Sube la versión de pubspec.yaml: 1.0.1+2 → 1.0.2+3. Con --minor, 1.1.0+3;
//    con --major, 2.0.0+3; con --misma, la deja como está. El número de
//    compilación (+3) siempre sube, salvo con --misma: Android solo instala
//    encima de una versión con un número menor o igual.
// 2. Compila en release para teléfonos (ARM de 32 y 64 bits; no para el
//    emulador), con la versión (se ve en la app) y el servidor en
//    http://localhost:8082, que el teléfono alcanza por el cable con
//    `adb reverse`. Otro servidor: --api=https://...
// 3. Apaga el daemon de Gradle, que si no queda ocupando un par de GB.
// 4. Deja una copia en build/apk/neils-1.0.2.apk.
// 5. Con --instalar, la instala en el teléfono conectado.
//
// Con --wifi, para instalarlo como cualquier app (copiando el APK al teléfono)
// en un teléfono en la misma Wi-Fi: el servidor va en la IP de esta
// computadora (http://192.168.x.x:8082; --wifi=IP para elegir otra) y compila
// en modo profile, que es como release pero con HTTP hacia la red (ver
// android/app/src/profile/res/xml/network_security_config.xml). Queda en
// build/apk/neils-1.0.2-wifi.apk. Si la computadora cambia de red, cambia la
// IP: hay que generarlo de nuevo.
//
// Con --solo-instalar no compila: instala el APK de la versión que ya está
// (p. ej. si la instalación falló porque el teléfono no lo permitía).
//
// Uso, desde apps/client: dart run tool/build_apk.dart [--minor | --major |
// --misma] [--instalar | --wifi[=IP]] [--api=URL], o dart run
// tool/build_apk.dart --solo-instalar
import 'dart:io';

import 'pubspec_version.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--solo-instalar')) {
    final version = readVersion();
    final apk = _apkOf(version);
    if (!apk.existsSync()) {
      _fail(
        'No hay un APK de la versión ${versionName(version)}: genéralo '
        'primero (sin --solo-instalar).',
      );
    }
    await _install(apk);
    return;
  }

  String? option(String name) => args
      .where((arg) => arg.startsWith('$name='))
      .map((arg) => arg.substring(name.length + 1))
      .firstOrNull;
  final wifi = args.contains('--wifi') || option('--wifi') != null;
  final api =
      option('--api') ??
      (wifi
          ? 'http://${option('--wifi') ?? await _localIp()}:8082'
          : 'http://localhost:8082');
  final mode = wifi ? 'profile' : 'release';
  final pubspec = File('pubspec.yaml');
  final before = pubspec.readAsStringSync();
  final current = readVersion(pubspec);
  final next = switch (args) {
    _ when args.contains('--misma') => current,
    _ when args.contains('--major') => (
      major: current.major + 1,
      minor: 0,
      patch: 0,
      build: current.build + 1,
    ),
    _ when args.contains('--minor') => (
      major: current.major,
      minor: current.minor + 1,
      patch: 0,
      build: current.build + 1,
    ),
    _ => (
      major: current.major,
      minor: current.minor,
      patch: current.patch + 1,
      build: current.build + 1,
    ),
  };
  writeVersion(next, pubspec);
  stdout.writeln(
    'Versión ${fullVersion(current)} → ${fullVersion(next)}. Compilando el '
    'APK en $mode (unos minutos)...',
  );

  final code = await _run('flutter', [
    'build',
    'apk',
    '--$mode',
    '--target-platform',
    'android-arm,android-arm64',
    '--dart-define=API_URL=$api',
    '--dart-define=APP_VERSION=${fullVersion(next)}',
  ]);
  await _stopGradle();
  if (code != 0) {
    // Sin APK, la versión no se gastó.
    pubspec.writeAsStringSync(before);
    stderr.writeln(
      'No se pudo compilar (código $code). pubspec.yaml quedó como estaba.',
    );
    exit(code);
  }

  final apk = _apkOf(next, wifi: wifi);
  apk.parent.createSync(recursive: true);
  File('build/app/outputs/flutter-apk/app-$mode.apk').copySync(apk.path);
  final megabytes = (apk.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
  stdout
    ..writeln()
    ..writeln('APK de la versión ${versionName(next)} (${next.build}):')
    ..writeln('  ${apk.absolute.path} ($megabytes MB)')
    ..writeln('  Contra el servidor $api.');
  if (wifi) {
    stdout.writeln(
      '  Cópialo al teléfono e instálalo desde el gestor de archivos. El '
      'teléfono tiene que estar en la misma Wi-Fi, con el servidor '
      'corriendo en esta computadora.',
    );
  }
  if (next != current) {
    stdout.writeln(
      '  pubspec.yaml quedó en ${fullVersion(next)}: commitéalo para que la '
      'versión quede registrada.',
    );
  }

  if (args.contains('--instalar')) await _install(apk);
}

/// Pasa el puerto del servidor por el cable e instala [apk] en el teléfono.
Future<void> _install(File apk) async {
  final adb = _adb();
  final devices = await Process.run(adb, ['devices'], runInShell: true);
  final lines = (devices.stdout as String)
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.contains('\t'))
      .toList();
  if (lines.any((line) => line.endsWith('\tunauthorized'))) {
    _fail(
      'El teléfono no autorizó la depuración: desbloquéalo y acepta '
      '"¿Permitir depuración por USB?". Después: --solo-instalar.',
    );
  }
  if (!lines.any((line) => line.endsWith('\tdevice'))) {
    _fail(
      'No hay un teléfono con la depuración USB activada. En el teléfono: '
      'Opciones de desarrollador → Depuración por USB (en un Xiaomi, también '
      '"Instalar vía USB"). Después: --solo-instalar.',
    );
  }
  stdout.writeln('\nInstalando en el teléfono...');
  final reverse = await Process.run(adb, [
    'reverse',
    'tcp:8082',
    'tcp:8082',
  ], runInShell: true);
  if (reverse.exitCode != 0) {
    _fail('No se pudo pasar el puerto 8082 por el cable (adb reverse).');
  }
  final install = await Process.run(adb, [
    'install',
    '-r',
    apk.path,
  ], runInShell: true);
  final output = '${install.stdout}${install.stderr}';
  if (install.exitCode != 0 || !output.contains('Success')) {
    _fail(switch (output) {
      _ when output.contains('INSTALL_FAILED_USER_RESTRICTED') =>
        'El teléfono no dejó instalar: en un Xiaomi hay que activar '
            '"Instalar vía USB" en Opciones de desarrollador y, al instalar, '
            'tocar "Instalar" en el aviso del teléfono. Después: '
            '--solo-instalar.',
      _ when output.contains('INSTALL_FAILED_UPDATE_INCOMPATIBLE') =>
        'El teléfono tiene la app firmada en otra computadora: desinstálala '
            'del teléfono y vuelve a correr con --misma --instalar.',
      _ => 'No se pudo instalar:\n$output',
    });
  }
  stdout.writeln(
    'Instalada. Abre "Neil\'s" en el teléfono; el servidor tiene que estar '
    'corriendo en esta computadora.',
  );
}

/// build/apk/neils-1.0.2.apk, o neils-1.0.2-wifi.apk.
File _apkOf(AppVersion version, {bool wifi = false}) => File(
  [
    'build',
    'apk',
    'neils-${versionName(version)}${wifi ? '-wifi' : ''}.apk',
  ].join(Platform.pathSeparator),
);

/// La IP de esta computadora en la red local (192.168.x.x, 10.x.x.x o
/// 172.16-31.x.x), la que ve un teléfono en la misma Wi-Fi.
Future<String> _localIp() async {
  final private = RegExp(r'^(192\.168\.|10\.|172\.(1[6-9]|2\d|3[01])\.)');
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
  );
  // Primero la Wi-Fi: las de máquinas virtuales también son privadas.
  interfaces.sort(
    (a, b) => (b.name.toLowerCase().contains('wi') ? 1 : 0).compareTo(
      a.name.toLowerCase().contains('wi') ? 1 : 0,
    ),
  );
  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      if (private.hasMatch(address.address)) return address.address;
    }
  }
  _fail(
    'No encontré la IP de esta computadora en la red local: pásala con '
    '--wifi=192.168.x.x (en PowerShell, ipconfig).',
  );
}

/// Apaga el daemon que deja la compilación de Gradle. Con el JDK de Android
/// Studio: el java del PATH puede ser uno viejo que Gradle no acepta.
Future<void> _stopGradle() async {
  final javaHome = Platform.environment['JAVA_HOME'] ?? _androidStudioJdk();
  try {
    await Process.run(
      // Con la ruta completa: en Windows, cmd puede no buscar en la carpeta
      // actual (NoDefaultCurrentDirectoryInExePath).
      File(Platform.isWindows ? 'android/gradlew.bat' : 'android/gradlew')
          .absolute
          .path,
      ['--stop'],
      workingDirectory: 'android',
      runInShell: true,
      environment: {'JAVA_HOME': ?javaHome},
    );
  } on ProcessException {
    // Sin gradlew no hay daemon que apagar.
  }
}

String? _androidStudioJdk() => [
  r'C:\Program Files\Android\Android Studio\jbr',
  '/Applications/Android Studio.app/Contents/jbr/Contents/Home',
].where((dir) => Directory(dir).existsSync()).firstOrNull;

/// adb del SDK de Android (el que instala Android Studio), o el del PATH.
String _adb() {
  final env = Platform.environment;
  for (final sdk in [
    env['ANDROID_HOME'],
    env['ANDROID_SDK_ROOT'],
    if (env['LOCALAPPDATA'] case final local?) '$local\\Android\\Sdk',
  ]) {
    if (sdk == null) continue;
    final adb = File(
      '$sdk/platform-tools/adb${Platform.isWindows ? '.exe' : ''}',
    );
    if (adb.existsSync()) return adb.path;
  }
  return 'adb';
}

Future<int> _run(String executable, List<String> args) async {
  final process = await Process.start(
    executable,
    args,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
