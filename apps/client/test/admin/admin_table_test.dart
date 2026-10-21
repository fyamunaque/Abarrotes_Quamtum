import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/common/page_list.dart';
import 'package:neils/features/admin/shared/admin_table.dart';
import 'package:neils/theme/neils_theme.dart';

import '../support.dart';

void main() {
  useBundledFonts();

  const rows = [('Arroz', 40), ('Aceite', 3), ('Leche', 48)];

  late List<String> tapped;
  late List<String> removed;
  late List<String> restocked;
  late List<int> pages;
  late int retries;

  setUp(() {
    tapped = [];
    removed = [];
    restocked = [];
    pages = [];
    retries = 0;
  });

  Future<void> pumpTable(
    WidgetTester tester,
    AsyncValue<PageList<(String, int)>> value, {
    double width = 1280,
    bool withAction = false,
    bool withRestock = false,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: neilsTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AdminTable<(String, int)>(
              value: value,
              columns: [
                AdminColumn('Producto', (row) => Text(row.$1), flex: 3),
                AdminColumn('Stock', (row) => Text('${row.$2}'), numeric: true),
              ],
              rowKey: (row) => row.$1,
              rowLabel: (row) => '${row.$1}, stock ${row.$2}',
              onRowTap: (row) => tapped.add(row.$1),
              rowActions: [
                // Solo las filas con poco stock.
                if (withRestock)
                  AdminRowAction(
                    label: 'Reponer',
                    icon: Icons.add,
                    semanticLabel: (row) => 'Reponer ${row.$1}',
                    onPressed: (row) => restocked.add(row.$1),
                    showFor: (row) => row.$2 < 10,
                  ),
                if (withAction)
                  AdminRowAction(
                    label: 'Quitar',
                    icon: Icons.person_remove_outlined,
                    semanticLabel: (row) => 'Quitar ${row.$1}',
                    onPressed: (row) => removed.add(row.$1),
                    destructive: true,
                  ),
              ],
              onPage: pages.add,
              onRetry: () => retries++,
              emptyText: 'No hay productos.',
            ),
          ),
        ),
      ),
    );
  }

  AsyncValue<PageList<(String, int)>> data({int total = 3, int page = 1}) =>
      AsyncData(PageList(rows, total: total, page: page, pageSize: 3));

  testWidgets('en ancho es una tabla, con los números a la derecha', (
    tester,
  ) async {
    await pumpTable(tester, data());

    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Producto'), findsOneWidget);
    expect(find.text('Stock'), findsOneWidget);
    final title = tester.getRect(find.text('Arroz'));
    final stock = tester.getRect(find.text('40'));
    expect(stock.center.dy, closeTo(title.center.dy, 1));
    expect(stock.right, greaterThan(title.right + 200));
    expect(find.text('1–3 de 3'), findsOneWidget);
    expect(find.byTooltip('Página siguiente'), findsNothing);
  });

  testWidgets('en un teléfono, cada fila es una tarjeta con "título: valor"', (
    tester,
  ) async {
    await pumpTable(tester, data(), width: 375);

    expect(find.byType(Card), findsNWidgets(3));
    expect(find.text('Producto'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar una fila la abre; el lector la lee entera', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpTable(tester, data());

    await tester.tap(find.text('Aceite'));
    expect(tapped, ['Aceite']);
    expect(find.bySemanticsLabel('Aceite, stock 3'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('una acción por fila, aparte de tocar la fila', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpTable(tester, data(), withAction: true);

    final quitar = find.widgetWithText(TextButton, 'Quitar');
    expect(quitar, findsNWidgets(3));
    // Al final de su fila, a la derecha de todas las columnas.
    final aceite = tester.getRect(find.text('Aceite'));
    final button = tester.getRect(quitar.at(1));
    expect(button.center.dy, closeTo(aceite.center.dy, 2));
    expect(button.left, greaterThan(tester.getRect(find.text('3')).right));

    await tester.tap(quitar.at(1));
    expect(removed, ['Aceite']);
    expect(tapped, isEmpty);
    // El lector anuncia la fila y el botón por separado.
    expect(find.bySemanticsLabel('Aceite, stock 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Quitar Aceite'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('en un teléfono, la acción va abajo de cada tarjeta', (
    tester,
  ) async {
    await pumpTable(tester, data(), width: 320, withAction: true);

    expect(tester.takeException(), isNull);
    final quitar = find.widgetWithText(TextButton, 'Quitar');
    expect(quitar, findsNWidgets(3));
    expect(
      tester.getRect(quitar.first).top,
      greaterThan(tester.getRect(find.text('40')).bottom),
    );
    await tester.tap(quitar.last);
    expect(removed, ['Leche']);
  });

  testWidgets('varias acciones: cada fila solo las suyas, alineadas', (
    tester,
  ) async {
    await pumpTable(tester, data(), withAction: true, withRestock: true);

    final reponer = find.widgetWithText(TextButton, 'Reponer');
    final quitar = find.widgetWithText(TextButton, 'Quitar');
    expect(reponer, findsOneWidget);
    expect(quitar, findsNWidgets(3));
    // "Quitar" queda en la misma columna, tenga la fila "Reponer" o no.
    expect(
      tester.getRect(quitar.at(0)).center.dx,
      closeTo(tester.getRect(quitar.at(1)).center.dx, 1),
    );
    expect(
      tester.getRect(reponer).right,
      lessThanOrEqualTo(tester.getRect(quitar.at(1)).left),
    );

    await tester.tap(reponer);
    expect(restocked, ['Aceite']);

    // En el teléfono, abajo de la tarjeta, solo las que tiene cada una.
    await pumpTable(
      tester,
      data(),
      width: 320,
      withAction: true,
      withRestock: true,
    );
    expect(tester.takeException(), isNull);
    expect(reponer, findsOneWidget);
    expect(quitar, findsNWidgets(3));
  });

  testWidgets('pasa de página con las flechas', (tester) async {
    await pumpTable(tester, data(total: 8, page: 2));

    expect(find.text('4–6 de 8'), findsOneWidget);
    await tester.tap(find.byTooltip('Página anterior'));
    await tester.tap(find.byTooltip('Página siguiente'));
    expect(pages, [1, 3]);
  });

  testWidgets('en la última página no hay "siguiente"', (tester) async {
    await pumpTable(tester, data(total: 8, page: 3));

    final next = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('vacía, cargando y con error', (tester) async {
    await pumpTable(tester, const AsyncData(PageList([], total: 0)));
    expect(find.text('No hay productos.'), findsOneWidget);

    await pumpTable(tester, const AsyncLoading());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await pumpTable(
      tester,
      AsyncError(const ApiFailure('Sin conexión'), StackTrace.empty),
    );
    expect(find.text('Sin conexión'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retries, 1);
  });
}
