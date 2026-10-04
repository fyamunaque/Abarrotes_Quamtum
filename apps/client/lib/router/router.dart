import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_home_screen.dart';
import '../features/admin/admin_shell.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/catalog/catalog_screen.dart';
import '../features/home/home_screen.dart';
import '../features/shared/not_found_screen.dart';
import '../session/session_provider.dart';
import 'route_guard.dart';
import 'routes.dart';

/// El router de la app. No se reconstruye cuando cambia la sesión: la escucha
/// y vuelve a evaluar el guard sobre la ruta actual (refreshListenable).
final routerProvider = Provider<GoRouter>((ref) {
  final sessionChanges = ValueNotifier(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => sessionChanges.value = next);

  final router = GoRouter(
    initialLocation: Routes.home,
    refreshListenable: sessionChanges,
    redirect: (_, state) => redirectFor(ref.read(sessionProvider), state.uri),
    routes: [
      GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: Routes.login,
        builder: (_, state) =>
            LoginScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: Routes.catalog, builder: (_, _) => const CatalogScreen()),
      // Grupo /admin: un layout común; las secciones se agregan como subrutas
      // (p. ej. /admin/pedidos).
      ShellRoute(
        builder: (_, _, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: Routes.admin,
            builder: (_, _) => const AdminHomeScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, _) => const NotFoundScreen(),
  );

  ref.onDispose(() {
    router.dispose();
    sessionChanges.dispose();
  });
  return router;
});
