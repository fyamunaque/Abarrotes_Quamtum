import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/session/staff_permission.dart';

/// Las fuentes salen de assets/google_fonts, como en la app: sin red.
///
/// En el motor de pruebas de Windows (flutter_tester de Flutter 3.47), cargar
/// Baloo2-SemiBold y Baloo2-Bold en el mismo proceso lo cierra sin ningún
/// error; cada una por separado carga bien. Los tests no necesitan los glifos
/// reales, así que cuando google_fonts pide la SemiBold se le entregan los
/// bytes de la ExtraBold. El resto de los assets llega sin cambios.
void useBundledFonts() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) {
      final key = utf8.decode(
        message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ),
      );
      final asset = key.endsWith('/Baloo2-SemiBold.ttf')
          ? ByteData.sublistView(
              utf8.encode(key.replaceFirst('SemiBold', 'ExtraBold')),
            )
          : message;
      return messenger.delegate.send('flutter/assets', asset);
    });
  });
}

/// Una ventana de escritorio (1280 × 900): la barra completa, sin el menú de
/// la cuenta. El tamaño por defecto de los tests (800 × 600) ya es compacto.
void useWideScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Una cuenta de [role], con los permisos que le corresponden como los
/// deriva el servidor: admin los tiene todos; staff, todos menos
/// `staff.manage`.
SignedIn signedInAs(UserRole role) => SignedIn(
  SessionUser(
    id: 'u-${role.name}',
    name: 'Ana ${role.name}',
    email: '${role.name}@tienda.pe',
    role: role,
    permissions: switch (role) {
      UserRole.admin => StaffPermission.values.toSet(),
      UserRole.staff => {
        for (final permission in StaffPermission.values)
          if (permission != StaffPermission.staffManage) permission,
      },
      UserRole.customer => const {},
    },
  ),
);

/// Sesión controlable desde el test (en la app la maneja Firebase Auth).
class TestSession extends SessionNotifier {
  TestSession(this.initial);

  final Session initial;

  @override
  Session build() => initial;

  void set(Session session) => state = session;

  /// Si se llamó a [signOut] (que aquí no toca Firebase).
  bool signedOut = false;

  /// Cuántas veces se pidió refrescar el perfil (aquí no hace nada).
  int refreshes = 0;

  @override
  Future<void> refreshProfile() async => refreshes++;

  @override
  Future<void> signOut() async {
    signedOut = true;
    state = const SignedOut();
  }
}
