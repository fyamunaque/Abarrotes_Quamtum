import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import 'account.dart';
import 'appearance_controls.dart';
import 'cart_bar.dart';
import 'cart_button.dart';
import 'page_title.dart';
import 'store_menu.dart';
import 'store_search_field.dart';
import 'verify_email_notice.dart';
import '../../theme/palette.dart';

/// El logo de Neil's completo (el tenedor, NEIL'S y FOOD SERVICE'S), en el
/// rojo de la marca y sin fondo. [NeilsLogo.white] es el mismo en blanco,
/// para los fondos rojos. Los dos salen de `brand/logo.jpg` con
/// `tool/brand_assets_test.dart`.
class NeilsLogo extends StatelessWidget {
  const NeilsLogo({super.key, this.height = 40})
    : _asset = 'assets/images/neils_logo.png';

  const NeilsLogo.white({super.key, this.height = 40})
    : _asset = 'assets/images/neils_logo_white.png';

  final double height;
  final String _asset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      height: height,
      semanticLabel: "Neil's Food Services",
    );
  }
}

/// Estructura de las pantallas públicas, y el contenido centrado con un ancho
/// cómodo en la web. La barra:
/// - desde [AccountActions.wideFrom]: el logo, las secciones (Inicio,
///   Catálogo, Promociones, con la actual en rojo y subrayada), el buscador
///   (desde [searchFrom], salvo en el catálogo, que tiene el suyo), la cuenta (ingresar, o Mis pedidos, el nombre y
///   salir) y el carrito;
/// - más angosta: el menú ([StoreMenu]) a la izquierda, el logo al centro y
///   el carrito.
///
/// Con una cuenta que no confirmó su correo, arriba del contenido va el
/// aviso para verificarlo ([VerifyEmailNotice]).
///
/// [bottomBar] queda fija abajo, fuera del scroll (p. ej.
/// el total y "Confirmar pedido" del carrito en el teléfono). Sin ella, en el
/// teléfono va la barra roja del carrito ([StoreCartBar]) mientras el
/// carrito tenga algo, salvo con [showCartBar] en false (el ingreso, el
/// registro, Mi cuenta y el carrito mismo).
class PublicScaffold extends ConsumerWidget {
  const PublicScaffold({
    super.key,
    required this.child,
    this.title,
    this.maxWidth = 960,
    this.onRefresh,
    this.bottomBar,
    this.showVerifyEmail = true,
    this.showCartBar = true,
    this.phoneBar = true,
  });

  /// Desde este ancho, el buscador va en la barra.
  static const searchFrom = 1100.0;

  /// El buscador de la barra, salvo en el catálogo, que tiene el suyo.
  static bool _showSearch(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < searchFrom) return false;
    final section = switch (currentStoreLocation(context)) {
      final location? => storeSectionOf(location),
      null => null,
    };
    return section != StoreSection.catalog &&
        section != StoreSection.promotions;
  }

  final Widget child;

  /// Con esto, deslizar hacia abajo desde arriba lo llama (pull-to-refresh).
  final Future<void> Function()? onRefresh;

  /// Para la pestaña del navegador (ver [PageTitle]). Sin título, la marca.
  final String? title;

  final double maxWidth;
  final Widget? bottomBar;

  /// Sin esto, no va el aviso para confirmar el correo: para el carrito, que
  /// lo muestra donde se confirma el pedido.
  final bool showVerifyEmail;

  final bool showCartBar;

  /// Sin esto, en el teléfono no va la barra de arriba y el contenido llega
  /// a los bordes (sin el margen de 16): la pantalla dibuja la suya (el
  /// detalle de un producto, con "Volver" y el carrito sobre la foto). El
  /// menú sigue abriéndose deslizando desde el borde.
  final bool phoneBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final compact = MediaQuery.sizeOf(context).width < AccountActions.wideFrom;
    return PageTitle(
      title: title,
      child: Scaffold(
        appBar: compact && !phoneBar
            ? null
            : compact
            ? AppBar(
                toolbarHeight: 64,
                centerTitle: true,
                leading: Builder(
                  builder: (context) => IconButton(
                    tooltip: 'Menú',
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                title: const _HomeLink(height: 32),
                actions: const [CartButton(), SizedBox(width: 4)],
              )
            : AppBar(
                toolbarHeight: 72,
                title: Row(
                  children: [
                    const _HomeLink(height: 40),
                    const SizedBox(width: 24),
                    const _SectionLink(
                      'Inicio',
                      Routes.home,
                      StoreSection.home,
                    ),
                    const _SectionLink(
                      'Catálogo',
                      Routes.catalog,
                      StoreSection.catalog,
                    ),
                    const _SectionLink(
                      'Promociones',
                      Routes.promotions,
                      StoreSection.promotions,
                    ),
                    if (_showSearch(context)) ...[
                      const SizedBox(width: 16),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: const StoreSearchField(),
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  ...switch (session) {
                    // Mientras se sabe si hay una cuenta abierta, nada: así
                    // no aparece "Ingresar" un instante.
                    SessionLoading() => const <Widget>[],
                    SignedOut() => [
                      TextButton(
                        onPressed: () => context.go(Routes.login),
                        child: const Text('Ingresar'),
                      ),
                    ],
                    // Hasta searchFrom, con las secciones no entra entera: va
                    // en su menú.
                    SignedIn(:final user) => [
                      AccountActions(user, inlineFrom: searchFrom),
                    ],
                  },
                  const AppearanceButton(),
                  const CartButton(),
                  const SizedBox(width: 8),
                ],
              ),
        drawer: compact ? const StoreMenu() : null,
        bottomNavigationBar:
            bottomBar ?? (showCartBar && compact ? const StoreCartBar() : null),
        body: SafeArea(
          child: _refreshable(
            SingleChildScrollView(
              // Para poder deslizar aunque el contenido entre en la pantalla.
              physics: onRefresh == null
                  ? null
                  : const AlwaysScrollableScrollPhysics(),
              padding: compact && !phoneBar
                  ? EdgeInsets.zero
                  : const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: switch (session) {
                    SignedIn(:final user)
                        when showVerifyEmail && !user.emailVerified =>
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          VerifyEmailNotice(user, key: ValueKey(user.id)),
                          const SizedBox(height: 16),
                          child,
                        ],
                      ),
                    _ => child,
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _refreshable(Widget scroll) => switch (onRefresh) {
    final onRefresh? => RefreshIndicator(onRefresh: onRefresh, child: scroll),
    null => scroll,
  };
}

/// El logo, que lleva a la portada.
class _HomeLink extends StatelessWidget {
  const _HomeLink({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go(Routes.home),
      child: NeilsLogo(height: height),
    );
  }
}

/// Una sección de la barra en escritorio: la actual, en rojo y subrayada.
class _SectionLink extends StatelessWidget {
  const _SectionLink(this.label, this.route, this.section);

  final String label;
  final String route;
  final StoreSection section;

  @override
  Widget build(BuildContext context) {
    final active = switch (currentStoreLocation(context)) {
      final location? => storeSectionOf(location) == section,
      null => false,
    };
    final style = Theme.of(context).textTheme.labelLarge;
    return Semantics(
      selected: active,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active
                      ? context.palette.brandText
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                label,
                style: style?.copyWith(
                  color: active
                      ? context.palette.brandText
                      : context.palette.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
