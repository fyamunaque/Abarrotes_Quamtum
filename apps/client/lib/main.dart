import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'cart/cart_storage.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // En la web, URLs limpias (/catalogo) en lugar de /#/catalogo.
  usePathUrlStrategy();
  // Las fuentes van empaquetadas en assets/google_fonts: sin descargas.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(_fontLicenses);

  // Sin config para esta plataforma, la app arranca sin poder ingresar (ver
  // authRepositoryProvider).
  WidgetsFlutterBinding.ensureInitialized();
  final firebase = DefaultFirebaseOptions.currentPlatform;
  if (firebase != null) {
    await Firebase.initializeApp(options: firebase);
  }
  // El carrito guardado se lee al abrir: así ya está en la primera pantalla.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        cartStorageProvider.overrideWithValue(PrefsCartStorage(prefs)),
      ],
      child: const NeilsApp(),
    ),
  );
}

/// Licencias OFL de Baloo 2 e Inter, para la pantalla de licencias.
Stream<LicenseEntry> _fontLicenses() async* {
  for (final (font, file) in [
    ('Baloo 2', 'OFL-Baloo2.txt'),
    ('Inter', 'OFL-Inter.txt'),
  ]) {
    final license = await rootBundle.loadString('assets/google_fonts/$file');
    yield LicenseEntryWithLineBreaks([font], license);
  }
}
