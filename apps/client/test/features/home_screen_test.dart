import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/features/home/home_screen.dart';
import 'package:neils/features/shared/swoosh.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';
import 'package:neils/theme/neils_theme.dart';

import '../support.dart';

void main() {
  useBundledFonts();

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => TestSession(const SignedOut())),
        ],
        child: MaterialApp(theme: neilsTheme(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el swoosh subraya la segunda línea del titular', (tester) async {
    await pumpHome(tester);

    expect(find.byType(AnimatedSwoosh), findsOneWidget);
    final line = tester.getRect(find.text('a la puerta de tu casa'));
    final swoosh = tester.getRect(find.byType(AnimatedSwoosh));
    expect(swoosh.width, closeTo(line.width, 1));
    expect(swoosh.center.dy, greaterThan(line.center.dy));
  });

  testWidgets('el titular se lee como un solo encabezado', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    expect(
      tester.getSemantics(find.text('Tus abarrotes,')),
      matchesSemantics(
        label: 'Tus abarrotes,\na la puerta de tu casa',
        isHeader: true,
      ),
    );
    semantics.dispose();
  });
}
