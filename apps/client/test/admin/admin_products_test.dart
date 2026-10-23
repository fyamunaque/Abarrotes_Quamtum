import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/admin/products/admin_products_providers.dart';
import 'package:neils/admin/products/photo_picker.dart';
import 'package:neils/catalog/catalog_providers.dart';
import 'package:neils/catalog/product.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/common/money.dart';
import 'package:neils/features/admin/shared/admin_table.dart';
import 'package:neils/features/admin/shared/status_badge.dart';
import 'package:neils/features/catalog/product_photo.dart';

import '../fakes.dart';
import '../support.dart';
import 'panel_support.dart';

final _rice = Product(
  id: 'arroz',
  name: 'Arroz extra 5 kg',
  sku: 'ARR-5K',
  priceCents: 2490,
  stock: 40,
  minStock: 10,
  category: groceries,
  expirationDate: DateTime.utc(2026, 10, 7),
);
const _oil = Product(
  id: 'aceite',
  name: 'Aceite vegetal 1 L',
  sku: 'ACE-1L',
  priceCents: 1090,
  promoPriceCents: 890,
  stock: 3,
  minStock: 5,
  category: groceries,
);
const _milk = Product(
  id: 'leche',
  name: 'Leche evaporada 400 g',
  sku: 'LEC-400',
  priceCents: 420,
  stock: 0,
  minStock: 6,
  category: dairy,
);
const _soda = Product(
  id: 'gaseosa',
  name: 'Gaseosa 1.5 L',
  sku: 'GAS-15',
  priceCents: 650,
  stock: 12,
  category: groceries,
  active: false,
);

void main() {
  useBundledFonts();

  late FakeAdminProductsRepository repository;
  late FakePhotoPicker picker;

  setUp(() {
    repository = FakeAdminProductsRepository([_rice, _oil, _milk, _soda]);
    picker = FakePhotoPicker();
  });

  Future<void> pumpProducts(WidgetTester tester, {double width = 1280}) =>
      pumpPanel(
        tester,
        at: '/admin/productos',
        width: width,
        overrides: [
          adminProductsRepositoryProvider.overrideWithValue(repository),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          photoPickerProvider.overrideWithValue(picker),
        ],
      );

  Finder inTable(String text) => find.descendant(
    of: find.byType(AdminTable<Product>),
    matching: find.text(text),
  );

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> chooseCategory(WidgetTester tester, String name) async {
    await tapAndSettle(tester, find.byType(DropdownButtonFormField<String>));
    await tapAndSettle(tester, find.text(name).last);
  }

  testWidgets('la tabla: precio con promoción, stock bajo y estado', (
    tester,
  ) async {
    await pumpProducts(tester);

    for (final header in ['Producto', 'Categoría', 'Precio', 'Stock']) {
      expect(inTable(header), findsOneWidget, reason: header);
    }
    // Por nombre.
    final names = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(AdminTable<Product>),
            matching: find.textContaining(RegExp(r'kg|L$|g$')),
          ),
        )
        .map((text) => text.data)
        .toList();
    expect(names.first, 'Aceite vegetal 1 L');

    expect(inTable('ARR-5K'), findsOneWidget);
    expect(inTable(formatSoles(890)), findsOneWidget);
    expect(inTable(formatSoles(1090)), findsOneWidget);
    expect(inTable('3 · bajo'), findsOneWidget);
    expect(inTable('Agotado'), findsOneWidget);
    expect(inTable('40'), findsOneWidget);
    expect(
      tester
          .widgetList<StatusBadge>(find.byType(StatusBadge))
          .map((badge) => badge.label),
      ['Activo', 'Activo', 'De baja', 'Activo'],
    );
  });

  testWidgets('buscar por nombre o SKU y filtrar por categoría', (
    tester,
  ) async {
    await pumpProducts(tester);

    await tester.enterText(find.byType(TextField).first, 'arroz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(inTable('Arroz extra 5 kg'), findsOneWidget);
    expect(inTable('Aceite vegetal 1 L'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'lec-4');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(inTable('Leche evaporada 400 g'), findsOneWidget);
    expect(inTable('Arroz extra 5 kg'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'nada así');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(
      find.text('Ningún producto coincide con la búsqueda.'),
      findsOneWidget,
    );

    await tapAndSettle(tester, find.byTooltip('Borrar la búsqueda'));
    expect(inTable('Arroz extra 5 kg'), findsOneWidget);

    await tapAndSettle(tester, find.byType(DropdownButtonFormField<String?>));
    await tapAndSettle(tester, find.text('Lácteos').last);
    expect(inTable('Leche evaporada 400 g'), findsOneWidget);
    expect(inTable('Arroz extra 5 kg'), findsNothing);
  });

  testWidgets('crear: valida y manda lo del formulario', (tester) async {
    await pumpProducts(tester);
    await tapAndSettle(tester, find.text('Nuevo producto'));

    await tapAndSettle(tester, find.text('Crear producto'));
    for (final error in [
      'Escribe el nombre.',
      'Escribe el SKU.',
      'Escribe el precio.',
      'Elige una categoría.',
    ]) {
      expect(find.text(error), findsOneWidget, reason: error);
    }

    await tester.enterText(field('Nombre'), '  Fideos spaghetti 500 g ');
    await tester.enterText(field('SKU'), 'FID-500');
    await tester.enterText(field('Precio'), '4,5');
    await chooseCategory(tester, 'Abarrotes');
    await tester.enterText(field('Stock inicial'), '30');
    await tester.enterText(field('Stock mínimo'), '8');
    await tester.enterText(
      field('O pega la URL de una imagen (opcional)'),
      'imagen',
    );
    await tapAndSettle(tester, find.text('Crear producto'));
    expect(
      find.text('Escribe una dirección que empiece con https://'),
      findsOneWidget,
    );

    await tester.enterText(field('O pega la URL de una imagen (opcional)'), '');
    await tapAndSettle(tester, find.text('Crear producto'));

    final (id, input) = repository.sent.single;
    expect(id, isNull);
    expect(input.toJson(create: true), {
      'name': 'Fideos spaghetti 500 g',
      'sku': 'FID-500',
      'price': 4.5,
      'categoryId': groceries.id,
      'minStock': 8,
      'active': true,
      'description': null,
      'imageUrl': null,
      'expirationDate': null,
      'currentStock': 30,
    });
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Creaste "Fideos spaghetti 500 g".'), findsOneWidget);
    expect(inTable('Fideos spaghetti 500 g'), findsOneWidget);
  });

  testWidgets('un SKU repetido se marca en su campo', (tester) async {
    await pumpProducts(tester);
    await tapAndSettle(tester, find.text('Nuevo producto'));

    await tester.enterText(field('Nombre'), 'Arroz superior 5 kg');
    await tester.enterText(field('SKU'), 'ARR-5K');
    await tester.enterText(field('Precio'), '26');
    await chooseCategory(tester, 'Abarrotes');
    await tapAndSettle(tester, find.text('Crear producto'));

    expect(find.byType(Dialog), findsOneWidget);
    expect(
      find.text('Ya existe un producto con el SKU ARR-5K'),
      findsOneWidget,
    );

    await tester.enterText(field('SKU'), 'ARR-SUP-5K');
    await tester.pump();
    expect(find.text('Ya existe un producto con el SKU ARR-5K'), findsNothing);
    await tapAndSettle(tester, find.text('Crear producto'));
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('editar: el formulario viene lleno y guarda los cambios', (
    tester,
  ) async {
    await pumpProducts(tester);
    await tapAndSettle(tester, inTable('Arroz extra 5 kg'));

    expect(find.text('Editar producto'), findsOneWidget);
    expect(find.text('24.90'), findsOneWidget);
    expect(find.text('7 oct 2026'), findsOneWidget);
    // El stock no se edita aquí.
    expect(field('Stock inicial'), findsNothing);
    expect(find.text('Stock actual'), findsOneWidget);

    await tester.enterText(field('Precio'), '23.50');
    await tapAndSettle(tester, find.byTooltip('Quitar la fecha'));
    await tapAndSettle(tester, find.text('Guardar cambios'));

    final (id, input) = repository.sent.single;
    expect(id, 'arroz');
    expect(input.priceCents, 2350);
    expect(input.expirationDate, isNull);
    expect(input.toJson(create: false), isNot(contains('currentStock')));
    expect(inTable(formatSoles(2350)), findsOneWidget);
    expect(find.text('Guardaste "Arroz extra 5 kg".'), findsOneWidget);
  });

  testWidgets('dar de baja pide confirmación', (tester) async {
    await pumpProducts(tester);
    await tapAndSettle(tester, inTable('Aceite vegetal 1 L'));

    await tapAndSettle(tester, find.text('Dar de baja'));
    expect(find.text('¿Dar de baja "Aceite vegetal 1 L"?'), findsOneWidget);
    await tapAndSettle(tester, find.text('Volver'));
    expect(repository.products[1].active, isTrue);

    await tapAndSettle(tester, find.text('Dar de baja'));
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Dar de baja'),
      ),
    );

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('"Aceite vegetal 1 L" quedó de baja.'), findsOneWidget);
    expect(
      tester.widget<StatusBadge>(find.byType(StatusBadge).first).label,
      'De baja',
    );
  });

  testWidgets('"Actualizar" trae lo que cambió en otro lado', (tester) async {
    await pumpProducts(tester);
    repository.products.add(
      const Product(
        id: 'fideos',
        name: 'Fideos spaghetti 500 g',
        sku: 'FID-500',
        priceCents: 380,
        stock: 60,
        category: groceries,
      ),
    );

    await tapAndSettle(tester, find.text('Actualizar'));

    expect(inTable('Fideos spaghetti 500 g'), findsOneWidget);
  });

  testWidgets('uno dado de baja no se vuelve a dar de baja', (tester) async {
    await pumpProducts(tester);
    await tapAndSettle(tester, inTable('Gaseosa 1.5 L'));
    expect(find.text('Dar de baja'), findsNothing);
    expect(find.text('No se ve en la tienda.'), findsOneWidget);
  });

  testWidgets('un error del servidor queda en el formulario', (tester) async {
    await pumpProducts(tester);
    await tapAndSettle(tester, inTable('Arroz extra 5 kg'));
    repository.failNext = const ApiFailure(
      'La categoría indicada no existe',
      status: 400,
    );

    await tapAndSettle(tester, find.text('Guardar cambios'));

    expect(find.text('La categoría indicada no existe'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('en el teléfono: tarjetas y el formulario a pantalla completa', (
    tester,
  ) async {
    await pumpProducts(tester, width: 375);
    expect(tester.takeException(), isNull);
    expect(find.byType(Card), findsWidgets);

    await tapAndSettle(tester, find.text('Nuevo producto'));
    expect(find.byType(Dialog), findsNothing);
    expect(find.widgetWithText(AppBar, 'Nuevo producto'), findsOneWidget);
    await tapAndSettle(tester, find.text('Crear producto'));
    expect(find.text('Escribe el nombre.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin desbordes a 320 px', (tester) async {
    await pumpProducts(tester, width: 320);
    expect(tester.takeException(), isNull);
    await tapAndSettle(tester, find.text('Arroz extra 5 kg'));
    expect(tester.takeException(), isNull);
  });

  group('la foto', () {
    const stored = '/images/products/aceite/0123456789abcdef.jpg';

    setUp(() {
      repository.products[1] = Product(
        id: _oil.id,
        name: _oil.name,
        sku: _oil.sku,
        priceCents: _oil.priceCents,
        promoPriceCents: _oil.promoPriceCents,
        stock: _oil.stock,
        minStock: _oil.minStock,
        category: _oil.category,
        imageUrl: stored,
      );
    });

    Future<void> fillNew(WidgetTester tester) async {
      await tapAndSettle(tester, find.text('Nuevo producto'));
      await tester.enterText(field('Nombre'), 'Fideos spaghetti 500 g');
      await tester.enterText(field('SKU'), 'FID-500');
      await tester.enterText(field('Precio'), '3.80');
      await chooseCategory(tester, 'Abarrotes');
    }

    testWidgets('elegir una foto, crear el producto y subirla', (tester) async {
      await pumpProducts(tester);
      await fillNew(tester);

      await tapAndSettle(tester, find.text('Subir foto'));
      expect(picker.sources, [PhotoSource.gallery]);
      expect(find.text('Se sube al guardar.'), findsOneWidget);
      expect(find.text('Cambiar foto'), findsOneWidget);
      await tapAndSettle(tester, find.text('Crear producto'));

      final (id, input) = repository.sent.single;
      expect(id, isNull);
      expect(input.imageUrl, isNull);
      final (uploadedTo, bytes, type) = repository.uploads.single;
      expect(uploadedTo, 'nuevo-5');
      expect(bytes, samplePhoto.bytes);
      expect(type, 'image/png');
      expect(find.byType(Dialog), findsNothing);
      expect(repository.products.last.imageUrl, startsWith('/images/'));
    });

    testWidgets(
      'al editar, la foto subida se mantiene sin mostrarse como URL',
      (tester) async {
        await pumpProducts(tester);
        await tapAndSettle(tester, inTable('Aceite vegetal 1 L'));

        expect(
          tester
              .widget<TextFormField>(
                field('O pega la URL de una imagen (opcional)'),
              )
              .controller!
              .text,
          '',
        );
        expect(find.text('Cambiar foto'), findsOneWidget);
        await tapAndSettle(tester, find.text('Guardar cambios'));

        expect(repository.sent.single.$2.imageUrl, stored);
        expect(repository.uploads, isEmpty);
      },
    );

    testWidgets('quitar la foto manda imageUrl en null', (tester) async {
      await pumpProducts(tester);
      await tapAndSettle(tester, inTable('Aceite vegetal 1 L'));

      await tapAndSettle(tester, find.text('Quitar foto'));
      expect(find.text('Subir foto'), findsOneWidget);
      await tapAndSettle(tester, find.text('Guardar cambios'));

      expect(repository.sent.single.$2.imageUrl, isNull);
    });

    testWidgets('cambiarla: guarda con la que tenía y sube la nueva', (
      tester,
    ) async {
      await pumpProducts(tester);
      await tapAndSettle(tester, inTable('Aceite vegetal 1 L'));

      await tapAndSettle(tester, find.text('Cambiar foto'));
      await tapAndSettle(tester, find.text('Guardar cambios'));

      // Si la subida fallara, el producto no pierde la foto anterior.
      expect(repository.sent.single.$2.imageUrl, stored);
      expect(repository.uploads.single.$1, 'aceite');
    });

    testWidgets('una URL escrita descarta la foto elegida', (tester) async {
      await pumpProducts(tester);
      await fillNew(tester);

      await tapAndSettle(tester, find.text('Subir foto'));
      await tester.enterText(
        field('O pega la URL de una imagen (opcional)'),
        'https://cdn.tienda.pe/fideos.jpg',
      );
      await tester.pump();
      expect(find.text('Se sube al guardar.'), findsNothing);
      await tapAndSettle(tester, find.text('Crear producto'));

      expect(
        repository.sent.single.$2.imageUrl,
        'https://cdn.tienda.pe/fideos.jpg',
      );
      expect(repository.uploads, isEmpty);
    });

    testWidgets(
      'si la foto no sube, el producto queda guardado y se reintenta solo ella',
      (tester) async {
        await pumpProducts(tester);
        await fillNew(tester);
        await tapAndSettle(tester, find.text('Subir foto'));
        repository.uploadFailure = const ApiFailure(
          'La foto pesa más de 8 MB',
          status: 413,
        );

        await tapAndSettle(tester, find.text('Crear producto'));

        expect(find.byType(Dialog), findsOneWidget);
        expect(
          find.text(
            'Se guardó el producto, pero no se pudo subir la foto: '
            'La foto pesa más de 8 MB',
          ),
          findsOneWidget,
        );
        expect(repository.sent, hasLength(1));
        // Lo demás ya se guardó: no se edita mientras falta la foto.
        expect(tester.widget<TextFormField>(field('Nombre')).enabled, isFalse);

        await tapAndSettle(tester, find.text('Reintentar la foto'));

        expect(repository.sent, hasLength(1));
        expect(repository.uploads, hasLength(1));
        expect(find.byType(Dialog), findsNothing);
      },
    );

    testWidgets('sin cámara (la web), sin "Tomar foto"', (tester) async {
      await pumpProducts(tester);
      await tapAndSettle(tester, find.text('Nuevo producto'));
      expect(find.text('Subir foto'), findsOneWidget);
      expect(find.text('Tomar foto'), findsNothing);
    });

    testWidgets('en el teléfono, "Tomar foto" usa la cámara', (tester) async {
      picker = FakePhotoPicker(canUseCamera: true);
      await pumpProducts(tester, width: 375);
      await tapAndSettle(tester, find.text('Nuevo producto'));

      await tapAndSettle(tester, find.text('Tomar foto'));

      expect(picker.sources, [PhotoSource.camera]);
      expect(find.text('Se sube al guardar.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la tabla muestra la foto en miniatura', (tester) async {
      await pumpProducts(tester);

      final photos = tester.widgetList<ProductPhoto>(
        find.descendant(
          of: find.byType(AdminTable<Product>),
          matching: find.byType(ProductPhoto),
        ),
      );
      expect(photos.map((photo) => photo.url), contains(stored));
      expect(photos, hasLength(4));
    });
  });
}
