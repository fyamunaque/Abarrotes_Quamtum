import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_home_screen.dart';
import '../features/admin/admin_shell.dart';
import '../features/admin/orders/admin_orders_screen.dart';
import '../features/admin/shared/admin_page.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/catalog/catalog_screen.dart';
import '../features/catalog/product_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/orders/my_orders_screen.dart';
import '../features/shared/not_found_screen.dart';
import '../features/showcase/showcase_screen.dart';
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
      GoRoute(
        path: Routes.catalog,
        builder: (_, state) =>
            CatalogScreen(categoryId: state.uri.queryParameters['categoria']),
      ),
      GoRoute(
        path: '/producto/:id',
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(path: Routes.cart, builder: (_, _) => const CartScreen()),
      GoRoute(
        path: Routes.myOrders,
        builder: (_, state) =>
            MyOrdersScreen(newOrderId: state.uri.queryParameters['nuevo']),
      ),
      // Solo en debug: en los builds de release esta ruta no existe.
      if (kDebugMode)
        GoRoute(
          path: Routes.showcase,
          builder: (_, _) => const ShowcaseScreen(),
        ),
      // Grupo /admin: un layout común con la navegación entre secciones.
      ShellRoute(
        builder: (_, state, child) =>
            AdminShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: Routes.admin,
            builder: (_, _) => const AdminHomeScreen(),
          ),
          for (final section in AdminSection.values.skip(1))
            GoRoute(
              path: section.path,
              builder: (_, _) => switch (section) {
                AdminSection.orders => const AdminOrdersScreen(),
                _ => AdminPlaceholder(section.label),
              },
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
