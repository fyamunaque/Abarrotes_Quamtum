import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/features/shared/swoosh.dart';
import 'package:neils/theme/motion.dart';

void main() {
  group('SwooshPainter.outline', () {
    const size = Size(300, 18);

    test('sin avance no dibuja nada', () {
      expect(SwooshPainter.outline(size, 0).getBounds().isEmpty, isTrue);
    });

    test('dibuja solo el tramo que avanzó el pincel', () {
      final half = SwooshPainter.outline(size, 0.5).getBounds();
      expect(half.left, closeTo(0, 1));
      expect(half.right, lessThan(size.width * 0.55));
    });

    test('completo, ocupa el ancho y no se sale del alto', () {
      final full = SwooshPainter.outline(size, 1).getBounds();
      expect(full.left, closeTo(0, 1));
      expect(full.right, closeTo(size.width, 1));
      expect(full.top, greaterThanOrEqualTo(0));
      expect(full.bottom, lessThanOrEqualTo(size.height));
    });

    test('nace fino a la izquierda y engorda hacia la derecha', () {
      double thicknessAt(double x) {
        final path = SwooshPainter.outline(size, 1);
        final ys = [
          for (var y = 0.0; y <= size.height; y += 0.25)
            if (path.contains(Offset(x, y))) y,
        ];
        return ys.isEmpty ? 0 : ys.last - ys.first;
      }

      expect(thicknessAt(15), lessThan(thicknessAt(230)));
      expect(thicknessAt(230), greaterThan(size.height * 0.4));
    });
  });

  group('AnimatedSwoosh', () {
    Future<void> pump(WidgetTester tester, {bool reduceMotion = false}) =>
        tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: const Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: SizedBox(width: 300, child: AnimatedSwoosh()),
              ),
            ),
          ),
        );

    double progress(WidgetTester tester) {
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(AnimatedSwoosh),
          matching: find.byType(CustomPaint),
        ),
      );
      return (paint.painter! as SwooshPainter).progress.value;
    }

    testWidgets('se dibuja una vez, en menos de un segundo', (tester) async {
      expect(NeilsMotion.swoosh, lessThan(const Duration(seconds: 1)));
      await pump(tester);
      expect(progress(tester), 0);

      await tester.pump(NeilsMotion.swoosh ~/ 2);
      expect(progress(tester), inExclusiveRange(0, 1));

      await tester.pump(NeilsMotion.swoosh ~/ 2);
      expect(progress(tester), 1);
      // Flutter da por terminada la animación en el frame siguiente.
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.hasRunningAnimations, isFalse);

      // Reconstruir la pantalla no lo vuelve a dibujar.
      await pump(tester);
      expect(progress(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('con "reducir animaciones" aparece completo', (tester) async {
      await pump(tester, reduceMotion: true);

      expect(progress(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('si se activa a mitad del trazo, termina de golpe', (
      tester,
    ) async {
      await pump(tester);
      await tester.pump(NeilsMotion.swoosh ~/ 4);
      expect(progress(tester), lessThan(1));

      await pump(tester, reduceMotion: true);

      expect(progress(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('los lectores de pantalla lo saltan', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);

      expect(
        find.descendant(
          of: find.byType(AnimatedSwoosh),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}
