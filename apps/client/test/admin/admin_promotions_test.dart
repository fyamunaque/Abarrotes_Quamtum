import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/admin/products/admin_products_providers.dart';
import 'package:neils/admin/promotions/promotion.dart';
import 'package:neils/admin/promotions/promotions_providers.dart';
import 'package:neils/admin/vip/vip_customer.dart';
import 'package:neils/admin/vip/vip_providers.dart';
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
      'type': 'specialPrice',
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

  group('tipos', () {
    Future<void> newFor(WidgetTester tester, String product) async {
      await pumpPromotions(tester);
      await tapAndSettle(tester, find.text('Nueva promoción'));
      await tester.enterText(field('Producto'), product);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tapAndSettle(
        tester,
        find.widgetWithText(ListTile, 'Arroz extra 5 kg'),
      );
    }

    Future<void> chooseType(WidgetTester tester, String label) async {
      await tapAndSettle(
        tester,
        find.byType(DropdownButtonFormField<PromotionType>),
      );
      await tapAndSettle(tester, find.text(label).last);
    }

    testWidgets('el tipo muestra solo sus campos', (tester) async {
      await newFor(tester, 'arroz');
      expect(field('Precio de la promoción'), findsOneWidget);

      await chooseType(tester, 'NxM');
      expect(field('Precio de la promoción'), findsNothing);
      await tester.enterText(field('Lleva'), '3');
      await tester.enterText(field('Paga'), '2');
      await tester.pump();
      expect(
        find.text('Lleva 3, paga 2: una de cada 3 gratis'),
        findsOneWidget,
      );

      await chooseType(tester, '% de descuento');
      await tester.enterText(field('% menos'), '20');
      await tester.pump();
      expect(
        find.text(
          'Precio normal ${formatSoles(2490)} · queda en '
          '${formatSoles(1992)}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('unidad extra y regalo', (tester) async {
      await newFor(tester, 'arroz');

      await chooseType(tester, 'Unidad extra');
      await tester.enterText(field('Cada'), '2');
      await tester.enterText(field('% menos'), '50');
      await tester.pump();
      expect(find.text('La 2.ª unidad al 50 %'), findsOneWidget);

      await chooseType(tester, 'Regalo');
      await tester.enterText(field('Cada'), '2');
      await tester.enterText(field('Producto de regalo'), 'leche');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tapAndSettle(
        tester,
        find.widgetWithText(ListTile, 'Leche evaporada 400 g'),
      );
      await tester.enterText(field('Cuántos de regalo'), '1');
      await tester.pump();
      expect(find.text('Cada 2 lleva 1 de regalo'), findsOneWidget);
      await pickRange(tester, DateTime(2026, 10, 20), DateTime(2026, 10, 25));
      await tapAndSettle(tester, find.text('Crear promoción'));

      final (_, input) = repository.sent.single;
      expect(input.toJson(), {
        'productId': 'arroz',
        'type': 'gift',
        'buyQuantity': 2,
        'giftProductId': 'leche',
        'giftQuantity': 1,
        'startDate': '2026-10-20',
        'endDate': '2026-10-25',
        'active': true,
        'audience': 'everyone',
        'title': null,
      });
      expect(inTable('Regalo: Leche evaporada 400 g'), findsOneWidget);
    });

    testWidgets('valida como el servidor', (tester) async {
      await newFor(tester, 'arroz');

      await chooseType(tester, 'NxM');
      await tester.enterText(field('Lleva'), '2');
      await tester.enterText(field('Paga'), '2');
      await tapAndSettle(tester, find.text('Crear promoción'));
      expect(
        find.text('Tiene que ser menor que lo que lleva.'),
        findsOneWidget,
      );

      await chooseType(tester, '% de descuento');
      await tester.enterText(field('% menos'), '95');
      await tapAndSettle(tester, find.text('Crear promoción'));
      expect(find.text('Entre 1 y 90.'), findsOneWidget);

      await chooseType(tester, 'Regalo');
      await tester.enterText(field('Cada'), '2');
      await tester.enterText(field('Cuántos de regalo'), '1');
      await tapAndSettle(tester, find.text('Crear promoción'));
      expect(find.text('Elige el producto de regalo.'), findsOneWidget);
      expect(repository.sent, isEmpty);
    });

    testWidgets('la tabla muestra el tipo', (tester) async {
      repository.promotions.addAll([
        Promotion(
          id: 'p5',
          productId: 'arroz',
          productName: 'Arroz extra 5 kg',
          sku: 'ARR-T1',
          priceCents: 2490,
          startDate: '2026-10-01',
          endDate: '2026-10-15',
          active: true,
          status: PromotionStatus.active,
          type: PromotionType.percentOff,
          percent: 15,
        ),
        Promotion(
          id: 'p6',
          productId: 'arroz',
          productName: 'Arroz extra 5 kg',
          sku: 'ARR-T2',
          priceCents: 2490,
          startDate: '2026-10-01',
          endDate: '2026-10-15',
          active: true,
          status: PromotionStatus.active,
          type: PromotionType.buyXPayY,
          buyQuantity: 2,
          payQuantity: 1,
        ),
      ]);
      await pumpPromotions(tester);

      expect(inTable('15 % menos'), findsOneWidget);
      expect(inTable('2x1'), findsOneWidget);
    });

    testWidgets('en el teléfono, cada tipo entra', (tester) async {
      await pumpPromotions(tester, width: 320);
      await tapAndSettle(tester, find.text('Nueva promoción'));
      for (final type in ['NxM', 'Unidad extra', 'Regalo', '% de descuento']) {
        await chooseType(tester, type);
        expect(tester.takeException(), isNull, reason: type);
      }
    });
  });

  testWidgets('el cruce pregunta: "Volver" no la crea y "Crear igual" sí', (
    tester,
  ) async {
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
    expect(find.text('Se cruza con otras promociones'), findsOneWidget);
    expect(
      find.text(
        'Precio especial ${formatSoles(1990)} · Todos · '
        '1 – 15 oct 2026',
      ),
      findsOneWidget,
    );
    expect(find.text('Se acumulan: el cliente recibe todas.'), findsOneWidget);
    await tapAndSettle(tester, find.text('Volver'));
    expect(repository.sent, isEmpty);
    expect(find.byType(PromotionForm), findsOneWidget);

    await tapAndSettle(tester, find.text('Crear promoción'));
    await tapAndSettle(tester, find.text('Crear igual'));

    expect(repository.confirmed, [true]);
    expect(repository.sent, hasLength(1));
    expect(find.byType(PromotionForm), findsNothing);
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
      // Se cruza con la de todos del arroz: se acumulan.
      await tapAndSettle(tester, find.text('Crear igual'));

      final (_, input) = repository.sent.single;
      expect(input.toJson(), {
        'productId': 'arroz',
        'type': 'specialPrice',
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

  testWidgets('el aviso de cruce lista cada una con su audiencia', (
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
        'Precio especial ${formatSoles(1790)} · Solo clientes VIP · '
        '1 – 15 oct 2026',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Precio especial ${formatSoles(1990)} · Todos'),
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

  group('clientes elegidos', () {
    final vips = [
      for (final name in ['ana', 'luis', 'rosa'])
        VipCustomer(
          id: 'vip-$name',
          email: '$name@tienda.pe',
          active: true,
          createdAt: DateTime.utc(2026, 10, 1),
          hasAccount: true,
        ),
    ];

    Future<void> pumpWithVips(WidgetTester tester, {double width = 1280}) =>
        pumpPanel(
          tester,
          at: '/admin/promociones',
          width: width,
          overrides: [
            promotionsRepositoryProvider.overrideWithValue(repository),
            adminProductsRepositoryProvider.overrideWithValue(
              FakeAdminProductsRepository([_rice, _milk]),
            ),
            vipRepositoryProvider.overrideWithValue(FakeVipRepository(vips)),
          ],
        );

    Finder searchField() =>
        find.widgetWithText(TextField, 'Buscar cliente VIP');

    Future<void> choose(
      WidgetTester tester,
      String search,
      String email,
    ) async {
      await tester.enterText(searchField(), search);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text(email).last);
    }

    testWidgets('se buscan, se eligen y se quitan; hace falta uno', (
      tester,
    ) async {
      await pumpWithVips(tester);
      await tapAndSettle(tester, find.text('Nueva promoción'));
      await tester.enterText(field('Producto'), 'arroz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tapAndSettle(
        tester,
        find.widgetWithText(ListTile, 'Arroz extra 5 kg'),
      );
      await tester.enterText(field('Precio de la promoción'), '18');
      await pickRange(tester, DateTime(2026, 10, 20), DateTime(2026, 10, 25));
      await tapAndSettle(tester, find.text('Clientes elegidos'));

      await tapAndSettle(tester, find.text('Crear promoción'));
      expect(find.text('Elige al menos un cliente VIP.'), findsOneWidget);
      expect(repository.sent, isEmpty);

      await choose(tester, 'ana', 'ana@tienda.pe');
      await choose(tester, 'lu', 'luis@tienda.pe');
      expect(find.widgetWithText(InputChip, 'ana@tienda.pe'), findsOneWidget);
      expect(find.text('Elegidos (2)'), findsOneWidget);
      expect(find.text('Elige al menos un cliente VIP.'), findsNothing);
      // Uno ya elegido no se ofrece otra vez: solo queda Rosa.
      await tester.enterText(searchField(), 'tienda');
      await tester.pumpAndSettle();
      expect(find.text('rosa@tienda.pe'), findsOneWidget);
      expect(find.text('ana@tienda.pe'), findsOneWidget);
      await tester.enterText(searchField(), '');
      await tester.pumpAndSettle();

      await tapAndSettle(tester, find.byTooltip('Quitar a ana@tienda.pe'));
      expect(find.widgetWithText(InputChip, 'ana@tienda.pe'), findsNothing);
      await tapAndSettle(tester, find.text('Crear promoción'));

      final (_, input) = repository.sent.single;
      expect(input.audience, PromotionAudience.selected);
      expect(input.toJson()['recipientIds'], ['vip-luis']);
      expect(inTable('Elegidos (1)'), findsOneWidget);
      expect(find.byType(VipBadge), findsOneWidget);
    });

    testWidgets('editar una trae a sus elegidos', (tester) async {
      repository.promotions.add(
        const Promotion(
          id: 'p4',
          productId: 'arroz',
          productName: 'Arroz extra 5 kg',
          sku: 'ARR-ELEG',
          priceCents: 2490,
          promoPriceCents: 1690,
          startDate: '2026-10-01',
          endDate: '2026-10-15',
          active: true,
          status: PromotionStatus.active,
          audience: PromotionAudience.selected,
          recipients: [(id: 'vip-rosa', email: 'rosa@tienda.pe')],
        ),
      );
      await pumpWithVips(tester);

      expect(inTable('Elegidos (1)'), findsOneWidget);
      await tapAndSettle(tester, inTable('ARR-ELEG'));
      expect(
        tester
            .widget<SegmentedButton<PromotionAudience>>(
              find.byType(SegmentedButton<PromotionAudience>),
            )
            .selected,
        {PromotionAudience.selected},
      );
      expect(find.widgetWithText(InputChip, 'rosa@tienda.pe'), findsOneWidget);
    });

    testWidgets('en el teléfono, la audiencia y el buscador entran', (
      tester,
    ) async {
      await pumpWithVips(tester, width: 320);
      await tapAndSettle(tester, find.text('Arroz extra 5 kg'));
      await tapAndSettle(tester, find.text('Clientes elegidos'));

      expect(tester.takeException(), isNull);
      expect(find.text('Buscar cliente VIP'), findsOneWidget);
    });
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
