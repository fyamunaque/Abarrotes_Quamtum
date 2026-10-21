import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/admin/products/admin_products_providers.dart';
import 'package:neils/admin/promotions/promotion.dart';
import 'package:neils/admin/promotions/promotions_providers.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/money.dart';
import 'package:neils/features/admin/promotions/promotion_form.dart';
import 'package:neils/features/admin/shared/admin_table.dart';
import 'package:neils/features/admin/shared/status_badge.dart';
import 'package:neils/features/admin/shared/vip_badge.dart';

import '../fakes.dart';
import '../support.dart';
import 'panel_support.dart';

const _rice = Product(
  id: 'arroz',
  name: 'Arroz extra 5 kg',
  sku: 'ARR-5K',
  priceCents: 2490,
  stock: 40,
  category: groceries,
);
const _milk = Product(
  id: 'leche',
  name: 'Leche evaporada 400 g',
  sku: 'LEC-400',
  priceCents: 420,
  stock: 48,
  category: dairy,
);

Promotion _promotion(
  String id,
  String product,
  int price,
  int promo,
  String start,
  String end,
  PromotionStatus status, {
  bool active = true,
  PromotionAudience audience = PromotionAudience.everyone,
  String? title,
}) => Promotion(
  id: id,
  productId: product.split(' ').first.toLowerCase(),
  productName: product,
  sku: 'SKU-$id',
  priceCents: price,
  promoPriceCents: promo,
  startDate: start,
  endDate: end,
  active: active,
  status: status,
  audience: audience,
  title: title,
);

void main() {
  useBundledFonts();

  late FakePromotionsRepository repository;

  setUp(() {
    repository = FakePromotionsRepository(
      [
        _promotion(
          'p1',
          'Arroz extra 5 kg',
          2490,
          1990,
          '2026-10-01',
          '2026-10-15',
          PromotionStatus.active,
        ),
        _promotion(
          'p2',
          'Aceite vegetal 1 L',
          1090,
          890,
          '2026-10-10',
          '2026-10-20',
          PromotionStatus.scheduled,
        ),
        _promotion(
          'p3',
          'Leche evaporada 400 g',
          420,
          380,
          '2026-09-01',
          '2026-09-15',
          PromotionStatus.expired,
        ),
      ],
      products: [_rice, _milk],
    );
  });

  Future<void> pumpPromotions(WidgetTester tester, {double width = 1280}) =>
      pumpPanel(
        tester,
        at: '/admin/promociones',
        width: width,
        overrides: [
          promotionsRepositoryProvider.overrideWithValue(repository),
          adminProductsRepositoryProvider.overrideWithValue(
            FakeAdminProductsRepository([_rice, _milk]),
          ),
        ],
      );

  Finder inTable(String text) => find.descendant(
    of: find.byType(AdminTable<Promotion>),
    matching: find.text(text),
  );

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Finder inForm(String text) => find.descendant(
    of: find.byType(PromotionForm),
    matching: find.text(text),
  );

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  List<String> statuses(WidgetTester tester) => tester
      .widgetList<StatusBadge>(find.byType(StatusBadge))
      .map((badge) => badge.label)
      .toList();

  /// Elige la vigencia escribiéndola en el modo de texto del calendario.
  Future<void> pickRange(
    WidgetTester tester,
    DateTime start,
    DateTime end,
  ) async {
    final l10n = MaterialLocalizations.of(
      tester.element(find.byType(PromotionForm)),
    );
    await tapAndSettle(tester, find.byIcon(Icons.date_range_outlined));
    await tapAndSettle(tester, find.byIcon(Icons.edit_outlined));
    final fields = find.descendant(
      of: find.byType(Dialog).last,
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), l10n.formatCompactDate(start));
    await tester.enterText(fields.at(1), l10n.formatCompactDate(end));
    await tapAndSettle(tester, find.text(l10n.okButtonLabel));
  }

  testWidgets('la tabla: precio → promoción, descuento, vigencia y estado', (
    tester,
  ) async {
    await pumpPromotions(tester);

    expect(
      inTable('${formatSoles(2490)} → ${formatSoles(1990)}'),
      findsOneWidget,
    );
    expect(inTable('20 % menos'), findsOneWidget);
    expect(inTable('1 – 15 oct 2026'), findsOneWidget);
    // El inicio más reciente primero.
    expect(statuses(tester), ['Programada', 'Activa', 'Vencida']);
  });

  testWidgets('filtrar por estado', (tester) async {
    await pumpPromotions(tester);

    await tapAndSettle(tester, find.widgetWithText(ChoiceChip, 'Programadas'));
    expect(statuses(tester), ['Programada']);

    await tapAndSettle(tester, find.widgetWithText(ChoiceChip, 'Apagadas'));
    expect(find.text('No hay promociones apagadas.'), findsOneWidget);
  });

  testWidgets('crear: producto, precio menor que el normal y fechas', (
    tester,
  ) async {
    await pumpPromotions(tester);
    await tapAndSettle(tester, find.text('Nueva promoción'));

    await tapAndSettle(tester, find.text('Crear promoción'));
    for (final error in [
      'Elige un producto de la lista.',
      'Escribe el precio de la promoción.',
      'Elige desde y hasta qué día.',
    ]) {
      expect(find.text(error), findsOneWidget, reason: error);
    }

    await tester.enterText(field('Producto'), 'leche');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tapAndSettle(
      tester,
      find.widgetWithText(ListTile, 'Leche evaporada 400 g'),
    );

    await tester.enterText(field('Precio de la promoción'), '4.20');
    await tapAndSettle(tester, find.text('Crear promoción'));
    expect(
      find.text(
        'Tiene que ser menor que el precio normal (${formatSoles(420)}).',
      ),
      findsOneWidget,
    );

    await tester.enterText(field('Precio de la promoción'), '3,5');
    await tester.pump();
    expect(
      find.text('Precio normal ${formatSoles(420)} · 17 % menos'),
      findsOneWidget,
    );
    await pickRange(tester, DateTime(2026, 10, 7), DateTime(2026, 10, 14));
    expect(inForm('7 – 14 oct 2026'), findsOneWidget);
    await tapAndSettle(tester, find.text('Crear promoción'));

    final (id, input) = repository.sent.single;
    expect(id, isNull);
    expect(input.toJson(), {
      'productId': 'leche',
      'promoPrice': 3.5,
      'startDate': '2026-10-07',
      'endDate': '2026-10-14',
      'active': true,
      'audience': 'everyone',
      'title': null,
    });
    expect(find.byType(Dialog), findsNothing);
    expect(
      find.text('Creaste la promoción de Leche evaporada 400 g.'),
      findsOneWidget,
    );
    expect(statuses(tester), contains('Programada'));
    expect(statuses(tester), hasLength(4));
  });

  testWidgets('una promoción que se cruza con otra no se crea', (tester) async {
    await pumpPromotions(tester);
    await tapAndSettle(tester, find.text('Nueva promoción'));
    await tester.enterText(field('Producto'), 'arroz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tapAndSettle(
      tester,
      find.widgetWithText(ListTile, 'Arroz extra 5 kg'),
    );
    await tester.enterText(field('Precio de la promoción'), '21');
    await pickRange(tester, DateTime(2026, 10, 10), DateTime(2026, 10, 12));

    await tapAndSettle(tester, find.text('Crear promoción'));

    expect(
      find.text(
        'Arroz extra 5 kg ya tiene una promoción del 2026-10-01 al '
        '2026-10-15 que se cruza con esas fechas',
      ),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsWidgets);
    expect(repository.sent, isEmpty);
  });

  testWidgets(
    'una promoción solo para VIP, con título: puede cruzarse con la de todos '
    'y lleva la insignia',
    (tester) async {
      await pumpPromotions(tester);
      expect(find.byType(VipBadge), findsNothing);
      await tapAndSettle(tester, find.text('Nueva promoción'));

      // Por defecto, para todos.
      expect(
        find.text('La ven todos, también quien no tiene cuenta.'),
        findsOneWidget,
      );
      await tester.enterText(field('Producto'), 'arroz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tapAndSettle(
        tester,
        find.widgetWithText(ListTile, 'Arroz extra 5 kg'),
      );
      await tester.enterText(
        field('Título de la oferta (opcional)'),
        '  Semana VIP  ',
      );
      await tester.enterText(field('Precio de la promoción'), '18');
      // Las mismas fechas que la promoción para todos del arroz.
      await pickRange(tester, DateTime(2026, 10, 10), DateTime(2026, 10, 12));
      await tapAndSettle(tester, find.text('Solo clientes VIP'));
      expect(
        find.textContaining('Solo la ven los clientes VIP'),
        findsOneWidget,
      );
      await tapAndSettle(tester, find.text('Crear promoción'));

      final (_, input) = repository.sent.single;
      expect(input.toJson(), {
        'productId': 'arroz',
        'promoPrice': 18.0,
        'startDate': '2026-10-10',
        'endDate': '2026-10-12',
        'active': true,
        'audience': 'vip',
        'title': 'Semana VIP',
      });
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(VipBadge), findsOneWidget);
      expect(inTable('Semana VIP · ARR-5K'), findsOneWidget);
    },
  );

  testWidgets('dos promociones VIP del mismo producto no se cruzan', (
    tester,
  ) async {
    repository.promotions.add(
      _promotion(
        'p4',
        'Arroz extra 5 kg',
        2490,
        1790,
        '2026-10-01',
        '2026-10-15',
        PromotionStatus.active,
        audience: PromotionAudience.vip,
        title: 'Clientes VIP',
      ),
    );
    await pumpPromotions(tester);
    expect(find.byType(VipBadge), findsOneWidget);

    // Editar la VIP: el formulario la trae con su audiencia y su título.
    await tapAndSettle(tester, inTable('Clientes VIP · SKU-p4'));
    expect(find.text('Clientes VIP'), findsWidgets);
    final selector = tester.widget<SegmentedButton<PromotionAudience>>(
      find.byType(SegmentedButton<PromotionAudience>),
    );
    expect(selector.selected, {PromotionAudience.vip});
    await tapAndSettle(tester, find.byType(CloseButton));

    await tapAndSettle(tester, find.text('Nueva promoción'));
    await tester.enterText(field('Producto'), 'arroz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tapAndSettle(
      tester,
      find.widgetWithText(ListTile, 'Arroz extra 5 kg'),
    );
    await tester.enterText(field('Precio de la promoción'), '18');
    await pickRange(tester, DateTime(2026, 10, 10), DateTime(2026, 10, 12));
    await tapAndSettle(tester, find.text('Solo clientes VIP'));
    await tapAndSettle(tester, find.text('Crear promoción'));

    expect(
      find.text(
        'Arroz extra 5 kg ya tiene una promoción VIP del 2026-10-01 al '
        '2026-10-15 que se cruza con esas fechas',
      ),
      findsOneWidget,
    );
    expect(repository.sent, isEmpty);
  });

  testWidgets('editar: apagarla la saca de las activas', (tester) async {
    await pumpPromotions(tester);
    await tapAndSettle(tester, find.widgetWithText(ChoiceChip, 'Activas'));
    await tapAndSettle(tester, inTable('Arroz extra 5 kg'));

    expect(find.text('Editar promoción'), findsOneWidget);
    // El producto no cambia al editar.
    expect(find.text('Arroz extra 5 kg · SKU-p1'), findsOneWidget);
    expect(field('Producto'), findsNothing);
    expect(find.text('19.90'), findsOneWidget);
    expect(inForm('1 – 15 oct 2026'), findsOneWidget);

    await tapAndSettle(tester, find.text('Encendida'));
    expect(find.text('Apagada: no rige aunque esté en fecha.'), findsOneWidget);
    await tapAndSettle(tester, find.text('Guardar cambios'));

    final (id, input) = repository.sent.single;
    expect(id, 'p1');
    expect(input.toJson(), {
      'promoPrice': 19.9,
      'startDate': '2026-10-01',
      'endDate': '2026-10-15',
      'active': false,
      'audience': 'everyone',
      'title': null,
    });
    expect(find.text('No hay promociones activas.'), findsOneWidget);
    expect(
      find.text('Guardaste la promoción de Arroz extra 5 kg.'),
      findsOneWidget,
    );
  });

  testWidgets('eliminar pide confirmación', (tester) async {
    await pumpPromotions(tester);
    await tapAndSettle(tester, inTable('Aceite vegetal 1 L'));

    await tapAndSettle(tester, find.text('Eliminar'));
    expect(
      find.text('¿Eliminar la promoción de Aceite vegetal 1 L?'),
      findsOneWidget,
    );
    await tapAndSettle(tester, find.text('Volver'));
    expect(repository.deleted, isEmpty);

    await tapAndSettle(tester, find.text('Eliminar'));
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
    );

    expect(repository.deleted, ['p2']);
    expect(find.byType(Dialog), findsNothing);
    expect(inTable('Aceite vegetal 1 L'), findsNothing);
    expect(
      find.text('Eliminaste la promoción de Aceite vegetal 1 L.'),
      findsOneWidget,
    );
  });

  testWidgets('en el teléfono, sin desbordes', (tester) async {
    await pumpPromotions(tester, width: 320);
    expect(tester.takeException(), isNull);
    await tapAndSettle(tester, find.text('Arroz extra 5 kg'));
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
    // El selector de audiencia entra en 320 px.
    await tapAndSettle(tester, find.text('Solo clientes VIP'));
    expect(tester.takeException(), isNull);
  });
}
