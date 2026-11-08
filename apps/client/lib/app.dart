import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'appearance/appearance_providers.dart';
import 'features/shared/refresh_on_resume.dart';
import 'router/router.dart';
import 'theme/neils_theme.dart';

/// La app de Neil's Food Services, para Android y web.
class NeilsApp extends ConsumerWidget {
  const NeilsApp({super.key});

  static final _theme = neilsTheme();
  static final _darkTheme = neilsTheme(Brightness.dark);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: "Neil's Food Services",
      debugShowCheckedModeBanner: false,
      theme: _theme,
      darkTheme: _darkTheme,
      // Sistema, Claro u Oscuro: lo elegido en el menú, guardado en el
      // dispositivo. Al cambiar, MaterialApp anima el paso de un tema al otro.
      themeMode: ref.watch(appearanceProvider).themeMode,
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Al volver a la app, el perfil al día (p. ej. si ahora es VIP).
      builder: (_, child) => RefreshOnResume(child: child!),
    );
  }
}
