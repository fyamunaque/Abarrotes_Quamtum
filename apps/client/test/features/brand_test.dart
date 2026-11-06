import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/features/shared/brand.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget logo) =>
      tester.pumpWidget(MaterialApp(home: Center(child: logo)));

  testWidgets('NeilsLogo usa el logo rojo y se anuncia con el nombre', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, const NeilsLogo());

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/neils_logo.png',
    );
    expect(find.bySemanticsLabel("Neil's Food Services"), findsOneWidget);
    // El logo nuevo no lleva las esquinas redondeadas del de antes.
    expect(find.byType(ClipRRect), findsNothing);
    semantics.dispose();
  });

  testWidgets('NeilsLogo.white usa el logo blanco', (tester) async {
    await pump(tester, const NeilsLogo.white(height: 56));

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/neils_logo_white.png',
    );
    expect(image.height, 56);
  });
}
