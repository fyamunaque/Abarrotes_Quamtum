import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';

void main() {
  // En la web, URLs limpias (/catalogo) en lugar de /#/catalogo.
  usePathUrlStrategy();
  // Las fuentes van empaquetadas en assets/google_fonts: sin descargas.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(_fontLicenses);
  runApp(const ProviderScope(child: NeilsApp()));
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
