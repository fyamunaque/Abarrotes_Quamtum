import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/admin/promotions/promotion.dart';
import 'package:neils/admin/stats/stats.dart';
import 'package:neils/admin/stats/stats_providers.dart';
import 'package:neils/appearance/appearance.dart';
import 'package:neils/appearance/appearance_providers.dart';
import 'package:neils/appearance/appearance_repository.dart';
import 'package:neils/features/admin/home/kpi_card.dart';
import 'package:neils/features/admin/promotions/admin_promotions_screen.dart';
import 'package:neils/features/admin/shared/vip_badge.dart';
import 'package:neils/theme/neils_theme.dart';
import 'package:neils/theme/palette.dart';

import '../admin/panel_support.dart';
import '../fakes.dart';
import '../support.dart';

/// El panel en el modo oscuro: lee la paleta oscura, no las constantes de
/// la marca (que son las del claro).
void main() {
  useBundledFonts();

  const dark = NeilsPalette.dark;

  Future<void> pumpDark(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: neilsTheme(Brightness.dark),
      home: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('el inicio del panel en oscuro, sin errores', (tester) async {
    const summary = SalesSummary(
      totalCents: 4550,
      orders: 2,
      averageTicketCents: 2275,
    );
    await pumpPanel(
      tester,
      at: '/admin',
      overrides: [
        appearanceRepositoryProvider.overrideWithValue(
          MemoryAppearanceRepository(ThemePreference.dark),
        ),
        statsRepositoryProvider.overrideWithValue(
          FakeStatsRepository(
            overviewData: const StatsOverview(
              today: summary,
              week: summary,
              month: summary,
              ordersByStatus: {},
              ordersByFulfillment: {},
            ),
          ),
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    final card = find.byType(KpiCard).first;
    expect(Theme.of(tester.element(card)).brightness, Brightness.dark);
    final icon = tester.widget<Icon>(
      find.descendant(of: card, matching: find.byType(Icon)).first,
    );
    expect(icon.color, dark.brandText);
  });

  testWidgets('la píldora VIP en oscuro: rojo hondo con el texto claro', (
    tester,
  ) async {
    await pumpDark(tester, const VipBadge());

    final pill = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(VipBadge),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((pill.decoration as BoxDecoration).color, dark.brandTint);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.workspace_premium)).color,
      neilsDarkColorScheme.onPrimaryContainer,
    );
    expect(tester.widget<Text>(find.text('VIP')).style?.color, dark.ink);
  });

  testWidgets('los estados de las promociones en oscuro', (tester) async {
    late BuildContext context;
    await pumpDark(
      tester,
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );

    expect(
      promotionStatusColor(context, PromotionStatus.active),
      dark.positive,
    );
    expect(
      promotionStatusColor(context, PromotionStatus.scheduled),
      dark.statusOnTheWay,
    );
  });
}
