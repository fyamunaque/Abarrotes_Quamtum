import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/shared/refresh_on_resume.dart';
import 'router/router.dart';
import 'theme/neils_theme.dart';

/// La app de Neil's Food Services, para Android y web.
class NeilsApp extends ConsumerWidget {
  const NeilsApp({super.key});

  static final _theme = neilsTheme();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: "Neil's Food Services",
      debugShowCheckedModeBanner: false,
      theme: _theme,
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Al volver a la app, el perfil al día (p. ej. si ahora es VIP).
      builder: (_, child) => RefreshOnResume(child: child!),
    );
  }
}
