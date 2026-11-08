import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_version.dart';
import '../../router/routes.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import 'brand.dart';

/// Qué sección de la tienda es [location]: la de la barra y el menú.
enum StoreSection { home, catalog, promotions, myOrders, myAccount }

StoreSection? storeSectionOf(Uri location) => switch (location.path) {
  '/' => StoreSection.home,
  '/catalogo' when location.queryParameters['promos'] == '1' =>
    StoreSection.promotions,
  '/catalogo' => StoreSection.catalog,
  final path when path.startsWith('/producto/') => StoreSection.catalog,
  '/mis-pedidos' => StoreSection.myOrders,
  '/mi-cuenta' => StoreSection.myAccount,
  _ => null,
};

/// La ruta actual, si la pantalla está bajo el router (en algunos tests no).
Uri? currentStoreLocation(BuildContext context) =>
    GoRouter.maybeOf(context)?.routerDelegate.currentConfiguration.uri;

/// El menú de la tienda en el teléfono (el botón de la izquierda de la
/// barra): el logo y el saludo, las secciones, y la cuenta: Mis pedidos, Mi
/// cuenta, el panel (para el personal) e Ingresar o Salir.
class StoreMenu extends ConsumerWidget {
  const StoreMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final user = switch (session) {
      SignedIn(:final user) => user,
      _ => null,
    };
    final current = switch (currentStoreLocation(context)) {
      final location? => storeSectionOf(location),
      null => null,
    };
    final text = Theme.of(context).textTheme;

    Widget item(
      IconData icon,
      String label,
      String route, [
      StoreSection? section,
    ]) => ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: section != null && section == current,
      onTap: () {
        Navigator.of(context).pop();
        context.go(route);
      },
    );

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: const NeilsLogo(height: 56),
              ),
            ),
            if (user != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Text(
                  '¡Hola, ${user.name.trim().split(RegExp(r'\s+')).first}!',
                  style: text.titleMedium,
                ),
              ),
            const Divider(),
            item(Icons.home_outlined, 'Inicio', Routes.home, StoreSection.home),
            item(
              Icons.storefront_outlined,
              'Catálogo',
              Routes.catalog,
              StoreSection.catalog,
            ),
            item(
              Icons.local_offer_outlined,
              'Promociones',
              Routes.promotions,
              StoreSection.promotions,
            ),
            if (user != null) ...[
              item(
                Icons.receipt_long_outlined,
                'Mis pedidos',
                Routes.myOrders,
                StoreSection.myOrders,
              ),
              item(
                Icons.person_outline,
                'Mi cuenta',
                Routes.myAccount,
                StoreSection.myAccount,
              ),
              if (user.role.isStaff)
                item(
                  Icons.space_dashboard_outlined,
                  'Panel de la tienda',
                  Routes.admin,
                ),
            ],
            const Divider(),
            if (user != null)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Salir'),
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(sessionProvider.notifier).signOut();
                },
              )
            else if (session is SignedOut)
              item(Icons.login, 'Ingresar', Routes.login),
            if (appVersionLabel case final version?)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(version, style: text.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}
