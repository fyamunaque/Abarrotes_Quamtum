import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/admin/inventory/inventory_providers.dart';
import 'package:neils/admin/inventory/movement.dart';
import 'package:neils/admin/products/admin_products_providers.dart';
import 'package:neils/catalog/product.dart';
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
const _oil = Product(
  id: 'aceite',
  name: 'Aceite vegetal 1 L',
  sku: 'ACE-1L',
  priceCents: 1090,
  stock: 3,
  category: groceries,
);

final _sale = Movement(
  id: 'mov-0',
  type: MovementType.outgoing,
  quantity: 2,
  reason: 'Pedido 8f2c',
  createdAt: DateTime.utc(2026, 10, 3, 18),
  productId: 'aceite',
  productName: 'Aceite vegetal 1 L',
  sku: 'ACE-1L',
  userName: 'Rosa Díaz',
);

void main() {
  useBundledFonts();

  late FakeInventoryRepository inventory;

  setUp(() {
    inventory = FakeInventoryRepository([_rice, _oil], movements: [_sale]);
  });

  Future<void> pumpInventory(WidgetTester tester, {double width = 1280}) =>
      pumpPanel(
        tester,
        at: '/admin/inventario',
        width: width,
        overrides: [
          inventoryRepositoryProvider.overrideWithValue(inventory),
          adminProductsRepositoryProvider.overrideWithValue(
            FakeAdminProductsRepository([_rice, _oil]),
          ),
        ],
      );

  Finder inTable(String text) => find.descendant(
    of: find.byType(AdminTable<Movement>),
    matching: find.text(text),
  );

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Finder typeSegment(String label) => find.descendant(
    of: find.byType(SegmentedButton<MovementType>),
    matching: find.text(label),
  );

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pickProduct(
    WidgetTester tester,
    String query,
    String name,
  ) async {
    await tester.enterText(field('Producto'), query);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.widgetWithText(ListTile, name));
  }

  testWidgets('el historial: fecha, producto, tipo, cantidad, motivo y quién', (
    tester,
  ) async {
    await pumpInventory(tester);

    for (final header in ['Fecha', 'Tipo', 'Cantidad', 'Motivo', 'Quién']) {
      expect(inTable(header), findsOneWidget, reason: header);
    }
    expect(inTable('Aceite vegetal 1 L'), findsOneWidget);
    expect(inTable('Salida'), findsOneWidget);
    expect(inTable('−2'), findsOneWidget);
    expect(inTable('Pedido 8f2c'), findsOneWidget);
    expect(inTable('Rosa Díaz'), findsOneWidget);
  });

  testWidgets('registrar una entrada: buscar el producto y ver el stock', (
    tester,
  ) async {
    await pumpInventory(tester);
    await tapAndSettle(tester, find.text('Registrar movimiento'));

    await tapAndSettle(tester, find.text('Registrar'));
    expect(find.text('Elige un producto de la lista.'), findsOneWidget);
    expect(find.text('Escribe la cantidad.'), findsOneWidget);

    await pickProduct(tester, 'arr', 'Arroz extra 5 kg');
    expect(find.text('ARR-5K · stock 40'), findsOneWidget);
    await tester.enterText(field('Cantidad'), '12');
    await tester.pump();
    expect(find.text('Stock: 40 → 52'), findsOneWidget);

    await tapAndSettle(tester, find.text('Registrar'));

    final input = inventory.recorded.single;
    expect(input.toJson(), {
      'productId': 'arroz',
      'type': 'incoming',
      'quantity': 12,
    });
    expect(find.byType(Dialog), findsNothing);
    expect(
      find.text('Movimiento registrado: Arroz extra 5 kg, +12.'),
      findsOneWidget,
    );
    // Aparece primero en el historial.
    expect(inTable('+12'), findsOneWidget);
    expect(inTable('Entrada'), findsOneWidget);
  });

  testWidgets('un ajuste lleva signo y pide motivo', (tester) async {
    await pumpInventory(tester);
    await tapAndSettle(tester, find.text('Registrar movimiento'));
    await pickProduct(tester, 'ARR', 'Arroz extra 5 kg');

    await tapAndSettle(tester, typeSegment('Ajuste'));
    await tester.enterText(field('Corrección'), '0');
    await tapAndSettle(tester, find.text('Registrar'));
    expect(find.text('No puede ser 0.'), findsOneWidget);
    expect(find.text('Escribe el motivo del ajuste.'), findsOneWidget);

    await tester.enterText(field('Corrección'), '-3');
    await tester.enterText(field('Motivo'), '  Conteo del lunes ');
    await tester.pump();
    expect(find.text('Stock: 40 → 37'), findsOneWidget);
    await tapAndSettle(tester, find.text('Registrar'));

    expect(inventory.recorded.single.toJson(), {
      'productId': 'arroz',
      'type': 'adjustment',
      'quantity': -3,
      'reason': 'Conteo del lunes',
    });
    expect(inTable('−3'), findsOneWidget);
    expect(inTable('Conteo del lunes'), findsOneWidget);
  });

  testWidgets('una entrada o salida no lleva signo', (tester) async {
    await pumpInventory(tester);
    await tapAndSettle(tester, find.text('Registrar movimiento'));

    await tester.enterText(field('Cantidad'), '-5');
    await tester.pump();
    // El signo no se puede escribir.
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('si no alcanza el stock, lo avisa y el servidor lo rechaza', (
    tester,
  ) async {
    await pumpInventory(tester);
    await tapAndSettle(tester, find.text('Registrar movimiento'));
    await pickProduct(tester, 'aceite', 'Aceite vegetal 1 L');
    await tapAndSettle(tester, typeSegment('Salida'));
    await tester.enterText(field('Cantidad'), '5');
    await tester.pump();
    expect(find.text('No alcanza: hay 3 en stock.'), findsOneWidget);

    await tapAndSettle(tester, find.text('Registrar'));

    expect(
      find.text('Stock insuficiente: Aceite vegetal 1 L tiene 3 unidades'),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsOneWidget);
    expect(inventory.recorded, isEmpty);
  });

  testWidgets('cambiar el texto del producto lo deselecciona', (tester) async {
    await pumpInventory(tester);
    await tapAndSettle(tester, find.text('Registrar movimiento'));
    await pickProduct(tester, 'arr', 'Arroz extra 5 kg');

    await tester.enterText(field('Producto'), 'Arroz extra');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.enterText(field('Cantidad'), '1');
    await tapAndSettle(tester, find.text('Registrar'));

    expect(find.text('Elige un producto de la lista.'), findsOneWidget);
    expect(inventory.recorded, isEmpty);
  });

  testWidgets('en el teléfono, sin desbordes', (tester) async {
    await pumpInventory(tester, width: 320);
    expect(tester.takeException(), isNull);
    await tapAndSettle(tester, find.text('Registrar movimiento'));
    expect(find.byType(Dialog), findsNothing);
    await tapAndSettle(tester, typeSegment('Ajuste'));
    expect(tester.takeException(), isNull);
  });
}
