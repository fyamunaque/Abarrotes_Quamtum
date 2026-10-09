import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:neils/app.dart';
import 'package:neils/router/router.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';

import '../support.dart';

/// El panel en [at] con una sesión de [role] (staff, si no se dice) y los
/// repositorios de [overrides], en una ventana de [width] px. Devuelve el
/// contenedor de providers y el router.
Future<(ProviderContainer, GoRouter)> pumpPanel(
  WidgetTester tester, {
  required String at,
  List<Override> overrides = const [],
  double width = 1280,
  UserRole role = UserRole.staff,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => TestSession(signedInAs(role))),
        ...overrides,
      ],
      child: const NeilsApp(),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(NeilsApp)),
  );
  final router = container.read(routerProvider)..go(at);
  await tester.pumpAndSettle();
  return (container, router);
}
