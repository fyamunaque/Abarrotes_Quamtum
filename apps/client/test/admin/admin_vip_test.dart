import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/admin/vip/vip_customer.dart';
import 'package:neils/admin/vip/vip_providers.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/features/admin/shared/admin_table.dart';
import 'package:neils/features/admin/shared/status_badge.dart';
import 'package:neils/features/admin/vip/vip_add_form.dart';
import 'package:neils/session/session.dart';

import '../fakes.dart';
import '../support.dart';
import 'panel_support.dart';

VipCustomer _vip(String id, String email, {bool hasAccount = true}) =>
    VipCustomer(
      id: id,
      email: email,
      active: true,
      createdAt: DateTime.utc(2026, 10, 1, 15),
      hasAccount: hasAccount,
      addedByName: 'Frank',
    );

void main() {
  useBundledFonts();

  late FakeVipRepository repository;

  setUp(() {
    repository = FakeVipRepository(
      [
        _vip('v1', 'ana@gmail.com'),
        _vip('v2', 'luis@hotmail.com', hasAccount: false),
        _vip('v3', 'maria@tienda.pe'),
      ],
      registered: {'carla@gmail.com'},
    );
  });

  Future<void> pumpVip(
    WidgetTester tester, {
    UserRole role = UserRole.admin,
    double width = 1280,
  }) => pumpPanel(
    tester,
    at: '/admin/clientes-vip',
    role: role,
    width: width,
    overrides: [vipRepositoryProvider.overrideWithValue(repository)],
  );

  Finder inTable(String text) => find.descendant(
    of: find.byType(AdminTable<VipCustomer>),
    matching: find.text(text),
  );

  Finder inForm(String text) =>
      find.descendant(of: find.byType(VipAddForm), matching: find.text(text));

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Finder removeButtons() => find.widgetWithText(TextButton, 'Quitar');

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  List<String> statuses(WidgetTester tester) => tester
      .widgetList<StatusBadge>(find.byType(StatusBadge))
      .map((badge) => badge.label)
      .toList();

  List<String> emails(WidgetTester tester) => [
    for (final vip in repository.customers)
      if (inTable(vip.email).evaluate().isNotEmpty) vip.email,
  ]..sort();

  testWidgets('la tabla: correo, si ya tiene cuenta y la fecha de alta', (
    tester,
  ) async {
    await pumpVip(tester);

    expect(emails(tester), [
      'ana@gmail.com',
      'luis@hotmail.com',
      'maria@tienda.pe',
    ]);
    expect(statuses(tester), ['Registrado', 'Aún sin cuenta', 'Registrado']);
    final date = MaterialLocalizations.of(
      tester.element(find.byType(AdminTable<VipCustomer>)),
    ).formatShortDate(DateTime.utc(2026, 10, 1, 15).toLocal());
    expect(inTable(date), findsNWidgets(3));
    expect(find.text('1–3 de 3'), findsOneWidget);
    // Admin: agrega y quita.
    expect(find.text('Agregar clientes'), findsOneWidget);
    expect(removeButtons(), findsNWidgets(3));
  });

  testWidgets('staff ve la lista en modo lectura', (tester) async {
    await pumpVip(tester, role: UserRole.staff);

    expect(statuses(tester), hasLength(3));
    expect(find.text('Agregar clientes'), findsNothing);
    expect(removeButtons(), findsNothing);
    expect(
      find.textContaining('Solo un admin puede agregar o quitar'),
      findsOneWidget,
    );
  });

  testWidgets('agregar un correo: valida el formato y muestra el resumen', (
    tester,
  ) async {
    await pumpVip(tester);
    await tapAndSettle(tester, find.text('Agregar clientes'));

    await tapAndSettle(tester, inForm('Agregar'));
    expect(find.text('Escribe un correo.'), findsOneWidget);
    await tester.enterText(field('Correo'), 'carla@gmail');
    await tapAndSettle(tester, inForm('Agregar'));
    expect(
      find.text('Escribe un correo como nombre@gmail.com.'),
      findsOneWidget,
    );
    expect(repository.sent, isEmpty);

    await tester.enterText(field('Correo'), ' Carla@Gmail.com ');
    await tapAndSettle(tester, inForm('Agregar'));

    expect(repository.sent.single, ['Carla@Gmail.com']);
    expect(find.text('Listo: el correo es VIP.'), findsOneWidget);
    expect(inForm('Agregados (1)'), findsOneWidget);
    expect(inForm('carla@gmail.com'), findsOneWidget);
    await tapAndSettle(tester, find.text('Listo'));

    expect(find.byType(VipAddForm), findsNothing);
    expect(find.text('Agregaste 1 cliente VIP.'), findsOneWidget);
    expect(inTable('carla@gmail.com'), findsOneWidget);
    expect(statuses(tester), hasLength(4));
  });

  testWidgets('pegar varios: el resumen trae los duplicados y los inválidos', (
    tester,
  ) async {
    await pumpVip(tester);
    await tapAndSettle(tester, find.text('Agregar clientes'));
    await tapAndSettle(tester, find.text('Varios'));

    await tester.enterText(
      field('Correos'),
      'pedro@gmail.com, ANA@gmail.com\nno-es-correo;\npedro@gmail.com',
    );
    await tester.pump();
    expect(find.textContaining('4 correos.'), findsOneWidget);
    await tapAndSettle(tester, inForm('Agregar'));

    expect(repository.sent.single, [
      'pedro@gmail.com',
      'ANA@gmail.com',
      'no-es-correo',
      'pedro@gmail.com',
    ]);
    expect(find.text('Se agregaron 1 de 4.'), findsOneWidget);
    expect(inForm('Agregados (1)'), findsOneWidget);
    expect(inForm('Ya estaban (2)'), findsOneWidget);
    expect(inForm('ana@gmail.com'), findsOneWidget);
    expect(inForm('No son correos válidos (1)'), findsOneWidget);
    expect(inForm('no-es-correo'), findsOneWidget);

    // "Agregar más" vuelve al formulario vacío, en el mismo modo; la tabla
    // ya se actualizó.
    await tapAndSettle(tester, find.text('Agregar más'));
    final pasted = tester.widget<TextFormField>(field('Correos'));
    expect(pasted.controller!.text, isEmpty);
    expect(inTable('pedro@gmail.com'), findsOneWidget);
  });

  testWidgets('si el servidor lo rechaza, el formulario muestra el error', (
    tester,
  ) async {
    repository.addFailure = const ApiFailure(
      'Tu rol no tiene permiso para esta acción',
      status: 403,
    );
    await pumpVip(tester);
    await tapAndSettle(tester, find.text('Agregar clientes'));
    await tester.enterText(field('Correo'), 'carla@gmail.com');
    await tapAndSettle(tester, inForm('Agregar'));

    expect(
      find.text('Tu rol no tiene permiso para esta acción'),
      findsOneWidget,
    );
    expect(find.byType(VipAddForm), findsOneWidget);
  });

  testWidgets('quitar pide confirmación', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpVip(tester);
    expect(find.bySemanticsLabel('Quitar a luis@hotmail.com'), findsOneWidget);

    await tapAndSettle(tester, removeButtons().at(1));
    expect(
      find.text('¿Quitar a luis@hotmail.com de los clientes VIP?'),
      findsOneWidget,
    );
    await tapAndSettle(tester, find.text('Volver'));
    expect(repository.removed, isEmpty);

    await tapAndSettle(tester, removeButtons().at(1));
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Quitar'),
      ),
    );

    expect(repository.removed, ['v2']);
    expect(inTable('luis@hotmail.com'), findsNothing);
    expect(
      find.text('Quitaste a luis@hotmail.com de los clientes VIP.'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('buscar por correo y pasar de página', (tester) async {
    repository = FakeVipRepository([...repository.customers], pageSize: 2);
    await pumpVip(tester, role: UserRole.staff);

    expect(statuses(tester), hasLength(2));
    expect(find.text('1–2 de 3'), findsOneWidget);
    await tapAndSettle(tester, find.byTooltip('Página siguiente'));
    expect(inTable('maria@tienda.pe'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar por correo'),
      'TIENDA',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(statuses(tester), hasLength(1));
    expect(inTable('maria@tienda.pe'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar por correo'),
      'zzz',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(
      find.text('Ningún correo coincide con la búsqueda.'),
      findsOneWidget,
    );
  });

  testWidgets('en el teléfono, sin desbordes', (tester) async {
    await pumpVip(tester, width: 320);
    expect(tester.takeException(), isNull);
    expect(removeButtons(), findsNWidgets(3));

    await tapAndSettle(tester, find.text('Agregar clientes'));
    expect(find.byType(Dialog), findsNothing);
    await tapAndSettle(tester, find.text('Varios'));
    expect(tester.takeException(), isNull);
  });
}
