import 'package:flutter/widgets.dart';

import '../../theme/brand_colors.dart';

/// El título de la pantalla en la pestaña del navegador (y en el selector de
/// apps de Android): "Carrito · Neil's Food Services". Sin [title], solo la
/// marca. Si hay dos, manda el de más adentro, que se dibuja después.
class PageTitle extends StatelessWidget {
  const PageTitle({super.key, this.title, required this.child});

  final String? title;
  final Widget child;

  static const brand = "Neil's Food Services";

  /// El título completo, como queda en la pestaña.
  static String full(String? title) =>
      title == null || title.isEmpty ? brand : '$title · $brand';

  @override
  Widget build(BuildContext context) {
    return Title(title: full(title), color: NeilsColors.primary, child: child);
  }
}
