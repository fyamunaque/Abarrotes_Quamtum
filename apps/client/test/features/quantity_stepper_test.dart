import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/features/shared/quantity_stepper.dart';
import 'package:neils/theme/neils_theme.dart';

import '../support.dart';

void main() {
  useBundledFonts();

  Future<void> pumpStepper(WidgetTester tester, {required bool dense}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: neilsTheme(),
          home: Scaffold(
            body: Center(
              child: QuantityStepper(
                quantity: 2,
                max: 5,
                dense: dense,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

  for (final dense in [false, true]) {
    testWidgets(
      '− y + se tocan con el dedo (48 dp)${dense ? ', también compactos' : ''}',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpStepper(tester, dense: dense);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        semantics.dispose();
      },
    );
  }

  testWidgets('compactos se ven más chicos que los normales', (tester) async {
    await pumpStepper(tester, dense: false);
    final normal = tester.getSize(find.byType(QuantityStepper)).width;
    await pumpStepper(tester, dense: true);
    final dense = tester.getSize(find.byType(QuantityStepper)).width;

    expect(dense, lessThan(normal));
  });
}
