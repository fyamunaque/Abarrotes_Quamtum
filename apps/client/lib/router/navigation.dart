import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../catalog/product.dart';
import '../theme/motion.dart';
import 'routes.dart';

/// Abrir el detalle de un producto desde una lista (las filas, las tarjetas,
/// las ofertas). Con [product] (el de la lista), el detalle lo muestra de
/// entrada mientras trae el actualizado: así su foto está desde el primer
/// cuadro y viaja desde la lista.
extension OpenProduct on BuildContext {
  void openProduct(String id, {Product? product}) =>
      go(Routes.product(id), extra: product);
}

/// La página del detalle de un producto: entra con un fundido de
/// [NeilsMotion.page] mientras la foto viaja desde la lista (su [Hero]).
/// Con "reducir animaciones", sin transición. Las demás pantallas cambian sin
/// transición.
Page<void> productPage(
  BuildContext context, {
  required LocalKey key,
  required Widget child,
}) => CustomTransitionPage<void>(
  key: key,
  child: child,
  transitionDuration: NeilsMotion.reduced(context)
      ? Duration.zero
      : NeilsMotion.page,
  reverseTransitionDuration: Duration.zero,
  transitionsBuilder: (_, animation, _, child) => FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: NeilsMotion.ease),
    child: child,
  ),
);
