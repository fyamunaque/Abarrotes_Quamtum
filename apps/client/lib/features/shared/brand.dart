import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import 'account.dart';
import 'cart_button.dart';
import 'page_title.dart';
import 'verify_email_notice.dart';

/// El logo de Neil's (naranja con letras crema).
class NeilsLogo extends StatelessWidget {
  const NeilsLogo({super.key, this.height = 40});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height * 0.15),
      child: Image.asset(
        'assets/images/neils_logo.png',
        height: height,
        semanticLabel: "Neil's Food Services",
      ),
    );
  }
}

/// Estructura de las pantallas públicas: barra con el logo, el catálogo, el
/// carrito y la cuenta (ingresar, o el nombre y salir), y el contenido
/// centrado con un ancho cómodo en la web.
///
/// Por debajo de [AccountActions.wideFrom] la barra se compacta: el catálogo
/// pasa a ser un ícono y la cuenta va en un menú.
///
/// Con una cuenta que no confirmó su correo, arriba del contenido va el
/// aviso para verificarlo ([VerifyEmailNotice]).
class PublicScaffold extends ConsumerWidget {
  const PublicScaffold({
    super.key,
    required this.child,
    this.title,
    this.maxWidth = 960,
    this.onRefresh,
  });

  final Widget child;

  /// Con esto, deslizar hacia abajo desde arriba lo llama (pull-to-refresh).
  final Future<void> Function()? onRefresh;

  /// Para la pestaña del navegador (ver [PageTitle]). Sin título, la marca.
  final String? title;

  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final compact = MediaQuery.sizeOf(context).width < AccountActions.wideFrom;
    return PageTitle(
      title: title,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          title: InkWell(
            onTap: () => context.go(Routes.home),
            child: const NeilsLogo(),
          ),
          actions: [
            if (compact)
              IconButton(
                tooltip: 'Catálogo',
                icon: const Icon(Icons.storefront_outlined),
                onPressed: () => context.go(Routes.catalog),
              )
            else
              TextButton(
                onPressed: () => context.go(Routes.catalog),
                child: const Text('Catálogo'),
              ),
            const CartButton(),
            ...switch (session) {
              // Mientras se sabe si hay una cuenta abierta, nada: así no
              // aparece "Ingresar" un instante.
              SessionLoading() => const <Widget>[],
              SignedOut() => [
                TextButton(
                  onPressed: () => context.go(Routes.login),
                  child: const Text('Ingresar'),
                ),
              ],
              SignedIn(:final user) => [AccountActions(user)],
            },
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: _refreshable(
            SingleChildScrollView(
              // Para poder deslizar aunque el contenido entre en la pantalla.
              physics: onRefresh == null
                  ? null
                  : const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: switch (session) {
                    SignedIn(:final user) when !user.emailVerified => Column(
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
