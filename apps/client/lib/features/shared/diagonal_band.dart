import 'package:flutter/material.dart';

import '../../theme/palette.dart';

/// La franja de la marca: una foto o un bloque de color cortado en diagonal
/// por la izquierda (el borde va del 18 % del ancho arriba al 0 % abajo),
/// como en las maquetas del cliente.
///
/// Con [image] (la ruta de un asset), la foto cubre todo. Sin ella, el bloque
/// [color] con [child] al centro (en la portada, el logo en blanco).
class DiagonalBand extends StatelessWidget {
  const DiagonalBand({super.key, this.image, this.color, this.child});

  final String? image;

  /// Sin él, el rojo de la marca del tema.
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const DiagonalClipper(),
      child: switch (image) {
        final image? => Image.asset(
          image,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          // Una foto decorativa: el lector de pantalla no la anuncia.
          excludeFromSemantics: true,
        ),
        null => ColoredBox(
          color: color ?? context.palette.brandFill,
          child: SizedBox.expand(
            child: Padding(
              // El contenido queda a la derecha del corte.
              padding: const EdgeInsetsDirectional.only(start: 24),
              child: Center(child: child),
            ),
          ),
        ),
      },
    );
  }
}

/// El corte de [DiagonalBand]: el borde izquierdo va del 18 % del ancho arriba
/// al 0 % abajo.
class DiagonalClipper extends CustomClipper<Path> {
  const DiagonalClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * 0.18, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(DiagonalClipper oldClipper) => false;
}
