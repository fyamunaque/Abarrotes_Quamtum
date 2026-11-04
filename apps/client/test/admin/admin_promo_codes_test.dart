import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/admin/products/admin_products_providers.dart';
import 'package:neils/admin/promo_codes/promo_code.dart';
import 'package:neils/admin/promo_codes/promo_codes_providers.dart';
import 'package:neils/admin/promotions/promotion.dart';
import 'package:neils/admin/promotions/promotions_providers.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/features/admin/promotions/promo_code_form.dart';
import 'package:neils/features/admin/promotions/promotion_form.dart';
import 'package:neils/features/admin/shared/admin_table.dart';

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

PromoCode _code(
  String id,
  String code, {
  PromoCodeStatus status = PromoCodeStatus.active,
  bool active = true,
  int? maxRedemptions,
  int redemptions = 0,
  int orders = 0,
}) => PromoCode(
  id: id,
  code: code,
  active: active,
  status: status,
  startDate: '2026-10-01',
  endDate: '2026-10-31',
  maxRedemptions: maxRedemptions,
  redemptions: redemptions,
  orders: orders,
);

void main() {
  useBundledFonts();

  late FakePromotionsRepository promotions;
  late FakePromoCodesRepository codes;

  setUp(() {
    promotions = FakePromotionsRepository(const [], products: [_rice]);
    codes = FakePromoCodesRepository([
      _code(
        'c1',
        'VERANO-10',
        maxRedemptions: 100,
        redemptions: 47,
        orders: 12,
      ),
      _code(
        'c2',
        'BIENVENIDA',
        status: PromoCodeStatus.paused,
        active: false,
        redemptions: 3,
      ),
    ], promotions: promotions);
  });

  Future<void> pumpCodes(WidgetTester tester, {double width = 1280}) =>
      pumpPanel(
        tester,
        at: '/admin/promociones/codigos',
        width: width,
        overrides: [
          promoCodesRepositoryProvider.overrideWithValue(codes),
          promotionsRepositoryProvider.overrideWithValue(promotions),
          adminProductsRepositoryProvider.overrideWithValue(
            FakeAdminProductsRepository([_rice]),
          ),
        ],
      );

  Finder inTable(String text) => find.descendant(
    of: find.byType(AdminTable<PromoCode>),
    matching: find.text(text),
  );

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Elige la vigencia escribiéndola en el modo de texto del calendario.
  Future<void> pickRange(
    WidgetTester tester,
    Type form,
    DateTime start,
    DateTime end,
  ) async {
    final l10n = MaterialLocalizations.of(tester.element(find.byType(form)));
    await tapAndSettle(tester, find.byIcon(Icons.date_range_outlined).last);
    await tapAndSettle(tester, find.byIcon(Icons.edit_outlined));
    final fields = find.descendant(
      of: find.byType(Dialog).last,
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), l10n.formatCompactDate(start));
    await tester.enterText(fields.at(1), l10n.formatCompactDate(end));
    await tapAndSettle(tester, find.text(l10n.okButtonLabel));
  }

  testWidgets('la pestaña Códigos, junto a Promociones', (tester) async {
    await pumpPanel(
      tester,
      at: '/admin/promociones',
      overrides: [
        promoCodesRepositoryProvider.overrideWithValue(codes),
        promotionsRepositoryProvider.overrideWithValue(promotions),
      ],
    );

    await tapAndSettle(tester, find.text('Códigos'));

    expect(inTable('VERANO-10'), findsOneWidget);
  });

  testWidgets('la tabla: código, estado, vigencia y activaciones', (
    tester,
  ) async {
    await pumpCodes(tester);

    expect(inTable('VERANO-10'), findsOneWidget);
    expect(inTable('Activado por 47 de 100'), findsOneWidget);
    expect(inTable('12'), findsOneWidget);
    expect(inTable('Activado por 3'), findsOneWidget);
    expect(inTable('Sin límite'), findsOneWidget);
    expect(inTable('Activo'), findsOneWidget);
    expect(inTable('Pausado'), findsOneWidget);
  });

  testWidgets('chips por estado y búsqueda', (tester) async {
    await pumpCodes(tester);

    await tapAndSettle(tester, find.text('Pausados'));
    expect(codes.requests.last, (PromoCodeStatus.paused, ''));
    expect(inTable('VERANO-10'), findsNothing);

    await tapAndSettle(tester, find.text('Todos'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar código'),
      'veran',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(codes.requests.last, (null, 'veran'));
    expect(inTable('BIENVENIDA'), findsNothing);
  });

  testWidgets('crear: el texto va en mayúsculas al escribir', (tester) async {
    await pumpCodes(tester);
    await tapAndSettle(tester, find.text('Nuevo código'));

    await tester.enterText(field('Código'), 'navidad 25');
    await tester.pump();
    // Sin espacios ni minúsculas.
    expect(find.text('NAVIDAD25'), findsOneWidget);
    await pickRange(
      tester,
      PromoCodeForm,
      DateTime(2026, 12, 1),
      DateTime(2026, 12, 25),
    );
    await tester.enterText(field('Límite de clientes'), '100');
    await tapAndSettle(tester, find.text('Crear código'));

    final (_, input) = codes.sent.single;
    expect(input.toJson(), {
      'code': 'NAVIDAD25',
      'startDate': '2026-12-01',
      'endDate': '2026-12-25',
      // Sin promociones todavía: se crea apagado.
      'active': false,
      'benefitDays': null,
      'maxRedemptions': 100,
      'usesPerCustomer': null,
      'minPurchase': null,
      'newCustomersOnly': false,
      'eligibility': 'everyone',
      'allowedEmails': <String>[],
    });
    expect(find.byType(PromoCodeForm), findsNothing);
    expect(
      find.text('Creaste el código NAVIDAD25. Ahora agrégale promociones.'),
      findsOneWidget,
    );
  });

  testWidgets('valida el texto, la vigencia y los números', (tester) async {
    await pumpCodes(tester);
    await tapAndSettle(tester, find.text('Nuevo código'));

    await tester.enterText(field('Código'), 'ab');
    await tester.enterText(field('Usos por cliente'), '0');
    await tapAndSettle(tester, find.text('Crear código'));

    expect(find.text('De 3 a 20 letras, números o guiones.'), findsOneWidget);
    expect(find.text('Elige desde y hasta qué día.'), findsOneWidget);
    expect(find.text('Tiene que ser 1 o más.'), findsOneWidget);
    expect(codes.sent, isEmpty);
  });

  testWidgets('condiciones: compra mínima y lista de correos', (tester) async {
    await pumpCodes(tester);
    await tapAndSettle(tester, find.text('Nuevo código'));
    await tester.enterText(field('Código'), 'clientes-top');
    await pickRange(
      tester,
      PromoCodeForm,
      DateTime(2026, 12, 1),
      DateTime(2026, 12, 25),
    );

    await tapAndSettle(tester, find.text('Compra mínima'));
    await tester.enterText(field('Monto mínimo'), '30');
    await tapAndSettle(tester, find.text('Solo clientes nuevos'));
    await tapAndSettle(tester, find.text('Lista de correos'));
    await tapAndSettle(tester, find.text('Crear código'));
    expect(find.text('Escribe al menos un correo.'), findsOneWidget);

    // Se pegan varios: cada uno queda en su chip, normalizado.
    await tester.enterText(
      find.widgetWithText(TextField, 'Correos'),
      'Ana@Tienda.pe, luis@tienda.pe\n',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'ana@tienda.pe'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'luis@tienda.pe'), findsOneWidget);
    await tapAndSettle(tester, find.text('Crear código'));

    final (_, input) = codes.sent.single;
    final json = input.toJson();
    expect(json['minPurchase'], 30.0);
    expect(json['newCustomersOnly'], isTrue);
    expect(json['eligibility'], 'listed');
    expect(json['allowedEmails'], ['ana@tienda.pe', 'luis@tienda.pe']);
  });

  testWidgets('agregar una promoción al código', (tester) async {
    await pumpCodes(tester);
    await tapAndSettle(tester, inTable('VERANO-10'));
    expect(find.text('Todavía no da ninguna promoción.'), findsOneWidget);

    await tapAndSettle(tester, find.text('Agregar promoción'));
    // La audiencia es la del código: no se elige.
    expect(find.byType(PromotionForm), findsOneWidget);
    expect(find.text('¿Quién la ve?'), findsNothing);
    await tester.enterText(field('Producto'), 'arroz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tapAndSettle(
      tester,
      find.widgetWithText(ListTile, 'Arroz extra 5 kg'),
    );
    await tester.enterText(field('Precio de la promoción'), '19.90');
    await pickRange(
      tester,
      PromotionForm,
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 31),
    );
    await tapAndSettle(tester, find.text('Crear promoción'));

    final (_, input) = promotions.sent.single;
    expect(input.toJson()['audience'], 'code');
    expect(input.toJson()['promoCodeId'], 'c1');
    // Vuelve al código, que ya la lista.
    expect(find.byType(PromotionForm), findsNothing);
    expect(find.byType(PromoCodeForm), findsOneWidget);
    expect(find.textContaining('Arroz extra 5 kg'), findsWidgets);
  });

  testWidgets('encenderlo sin promociones muestra el error del servidor', (
    tester,
  ) async {
    await pumpCodes(tester);
    await tapAndSettle(tester, inTable('BIENVENIDA'));

    await tapAndSettle(tester, find.text('Encendido'));
    await tapAndSettle(tester, find.text('Guardar cambios'));

    expect(
      find.text('Agrega al menos una promoción antes de encender el código'),
      findsOneWidget,
    );
    expect(find.byType(PromoCodeForm), findsOneWidget);
  });

  testWidgets('con canjes, el texto no se edita', (tester) async {
    await pumpCodes(tester);
    await tapAndSettle(tester, inTable('VERANO-10'));

    final code = tester.widget<TextField>(
      find.descendant(of: field('Código'), matching: find.byType(TextField)),
    );
    expect(code.enabled, isFalse);
    expect(find.text('Ya lo activaron: el texto no cambia.'), findsOneWidget);
  });

  testWidgets('borrar uno activado muestra el motivo', (tester) async {
    codes.deleteFailure = const ApiFailure(
      'El código ya se activó: apágalo en vez de borrarlo',
      status: 409,
    );
    await pumpCodes(tester);
    await tapAndSettle(tester, inTable('VERANO-10'));

    await tapAndSettle(tester, find.text('Eliminar'));
    await tapAndSettle(tester, find.text('Eliminar').last);

    expect(
      find.text('El código ya se activó: apágalo en vez de borrarlo'),
      findsOneWidget,
    );
  });

  testWidgets('en el teléfono, la tabla y el formulario entran', (
    tester,
  ) async {
    await pumpCodes(tester, width: 320);
    expect(tester.takeException(), isNull);

    await tapAndSettle(tester, find.text('Nuevo código'));
    await tapAndSettle(tester, find.text('Lista de correos'));
    expect(tester.takeException(), isNull);
  });

  test('PromoCodeStatus y PromoCodeEligibility: sus nombres', () {
    expect(
      [for (final s in PromoCodeStatus.values) s.label],
      ['Activo', 'Programado', 'Vencido', 'Pausado'],
    );
    expect(
      [for (final e in PromoCodeEligibility.values) e.label],
      ['Todos', 'Solo VIP', 'Lista de correos'],
    );
    expect(PromotionAudience.code.label, 'Código');
  });
}
