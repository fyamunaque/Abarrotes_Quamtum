import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/admin/categories/admin_categories_providers.dart';
import 'package:neils/admin/products/photo_picker.dart';
import 'package:neils/catalog/category.dart';
import 'package:neils/common/api_client.dart';
import 'package:neils/features/admin/categories/admin_categories_screen.dart';
import 'package:neils/features/admin/categories/category_form.dart';
import 'package:neils/session/staff_permission.dart';

import '../fakes.dart';
import '../support.dart';
import 'panel_support.dart';

void main() {
  useBundledFonts();

  late FakeAdminCategoriesRepository repository;
  late FakePhotoPicker picker;

  setUp(() {
    repository = FakeAdminCategoriesRepository(
      [
        const Category(
          id: 'cat-embutidos',
          name: 'Embutidos',
          description: 'Hot dogs, jamonadas y más',
        ),
        const Category(id: 'cat-lacteos', name: 'Lácteos'),
      ],
      productCounts: {'cat-embutidos': 3},
    );
    picker = FakePhotoPicker();
  });

  Future<void> pumpCategories(
    WidgetTester tester, {
    Set<StaffPermission>? permissions,
  }) => pumpPanel(
    tester,
    at: '/admin/categorias',
    permissions: permissions,
    overrides: [
      adminCategoriesRepositoryProvider.overrideWithValue(repository),
      photoPickerProvider.overrideWithValue(picker),
    ],
  );

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('lista las categorías con su cantidad de productos', (
    tester,
  ) async {
    await pumpCategories(tester);

    expect(find.byType(AdminCategoriesScreen), findsOneWidget);
    expect(find.text('Embutidos'), findsWidgets);
    expect(find.text('Hot dogs, jamonadas y más'), findsOneWidget);
    expect(find.text('3 productos'), findsOneWidget);
    expect(find.text('Sin productos'), findsOneWidget);
  });

  testWidgets('crea una categoría con descripción', (tester) async {
    await pumpCategories(tester);

    await tapAndSettle(tester, find.text('Nueva categoría'));
    await tester.enterText(field('Nombre'), 'Salsas');
    await tester.enterText(field('Descripción'), 'Mayonesa, kétchup y más');
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Crear'));

    expect(repository.created, [('Salsas', 'Mayonesa, kétchup y más', null)]);
    expect(find.text('Mayonesa, kétchup y más'), findsOneWidget);
  });

  testWidgets('la descripción tiene hasta 80', (tester) async {
    await pumpCategories(tester);

    await tapAndSettle(tester, find.text('Nueva categoría'));
    await tester.enterText(field('Nombre'), 'Salsas');
    await tester.enterText(field('Descripción'), 'x' * 81);
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Crear'));

    expect(find.text('Como máximo 80 caracteres.'), findsOneWidget);
    expect(repository.created, isEmpty);
  });

  testWidgets('sube la foto', (tester) async {
    await pumpCategories(tester);

    await tapAndSettle(tester, find.text('Lácteos').first);
    await tapAndSettle(tester, find.text('Subir foto'));
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Guardar'));

    expect(repository.uploads, ['cat-lacteos']);
    expect(picker.sources, [PhotoSource.gallery]);
  });

  testWidgets('si la foto no sube, reintentar no crea la categoría otra vez', (
    tester,
  ) async {
    repository.uploadFailure = const ApiFailure('No se pudo subir la foto');
    await pumpCategories(tester);

    await tapAndSettle(tester, find.text('Nueva categoría'));
    await tester.enterText(field('Nombre'), 'Salsas');
    await tapAndSettle(tester, find.text('Subir foto'));
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Crear'));

    expect(find.text('No se pudo subir la foto'), findsOneWidget);
    expect(find.byType(CategoryForm), findsOneWidget);

    repository.uploadFailure = null;
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Crear'));

    // Se creó una sola vez y la foto quedó en esa.
    expect(repository.created, [('Salsas', null, null)]);
    expect(repository.uploads, ['cat-3']);
    expect(find.byType(CategoryForm), findsNothing);
  });

  testWidgets('quitar la foto', (tester) async {
    repository.categories[1] = const Category(
      id: 'cat-lacteos',
      name: 'Lácteos',
      imageUrl: '/images/categories/cat-lacteos/0123456789abcdef.jpg',
    );
    await pumpCategories(tester);

    await tapAndSettle(tester, find.text('Lácteos').first);
    await tapAndSettle(tester, find.text('Quitar foto'));
    // Ya no hay foto que quitar: se puede elegir otra.
    expect(find.text('Quitar foto'), findsNothing);
    expect(find.text('Subir foto'), findsOneWidget);
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Guardar'));

    expect(repository.categories[1].imageUrl, isNull);
    expect(repository.uploads, isEmpty);
  });

  testWidgets('sin foto no se ofrece quitarla', (tester) async {
    await pumpCategories(tester);

    await tapAndSettle(tester, find.text('Lácteos').first);

    expect(find.text('Quitar foto'), findsNothing);
  });

  testWidgets('borrar una con productos muestra el aviso del servidor', (
    tester,
  ) async {
    await pumpCategories(tester);

    await tapAndSettle(tester, find.text('Embutidos').first);
    await tapAndSettle(tester, find.text('Borrar categoría'));
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Borrar'));

    expect(
      find.text(
        'La categoría tiene 3 productos: muévelos a otra antes de eliminarla',
      ),
      findsOneWidget,
    );
    expect(repository.categories, hasLength(2));
  });

  testWidgets('borrar pide confirmar como el resto del panel', (tester) async {
    await pumpCategories(tester);

    await tapAndSettle(tester, find.text('Lácteos').first);
    await tapAndSettle(tester, find.text('Borrar categoría'));

    // El diálogo común (confirmAction): "Volver" y el botón en rojo de error.
    expect(find.text('Volver'), findsOneWidget);
    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Borrar'),
    );
    final context = tester.element(find.widgetWithText(FilledButton, 'Borrar'));
    expect(
      confirm.style?.backgroundColor?.resolve({}),
      Theme.of(context).colorScheme.error,
    );

    await tapAndSettle(tester, find.text('Volver'));
    expect(repository.categories, hasLength(2));
  });

  testWidgets('sin categories.manage no aparece en el menú', (tester) async {
    await pumpCategories(tester, permissions: {StaffPermission.productsView});

    expect(find.text('Categorías'), findsNothing);
    expect(find.byType(AdminCategoriesScreen), findsNothing);
  });

  group('la foto desde una URL', () {
    const url = 'https://cdn.tienda.pe/salsas.jpg';
    Finder urlField() => field('O pega la URL de una imagen (opcional)');
    // La foto elegida se muestra desde sus bytes.
    Finder chosenPhoto() =>
        find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage);

    testWidgets('crea una categoría con la URL de una imagen', (tester) async {
      await pumpCategories(tester);

      await tapAndSettle(tester, find.text('Nueva categoría'));
      await tester.enterText(field('Nombre'), 'Salsas');
      await tester.enterText(urlField(), url);
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Crear'));

      expect(repository.created, [('Salsas', null, url)]);
      expect(repository.uploads, isEmpty);
      expect(find.byType(CategoryForm), findsNothing);
    });

    testWidgets('la URL tiene que empezar con https://', (tester) async {
      await pumpCategories(tester);

      await tapAndSettle(tester, find.text('Nueva categoría'));
      await tester.enterText(field('Nombre'), 'Salsas');
      await tester.enterText(urlField(), 'salsas.jpg');
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Crear'));

      expect(
        find.text('Escribe una dirección que empiece con https://'),
        findsOneWidget,
      );
      expect(repository.created, isEmpty);
    });

    testWidgets(
      'pegar una URL reemplaza la foto elegida, y elegir una foto borra la URL',
      (tester) async {
        await pumpCategories(tester);
        await tapAndSettle(tester, find.text('Lácteos').first);

        await tapAndSettle(tester, find.text('Subir foto'));
        expect(chosenPhoto(), findsOneWidget);

        await tester.enterText(urlField(), url);
        await tester.pumpAndSettle();
        expect(chosenPhoto(), findsNothing);

        await tapAndSettle(tester, find.text('Cambiar foto'));
        expect(chosenPhoto(), findsOneWidget);
        expect(
          tester.widget<TextFormField>(urlField()).controller!.text,
          isEmpty,
        );
      },
    );

    testWidgets('cambia la foto subida por una URL', (tester) async {
      repository.categories[1] = const Category(
        id: 'cat-lacteos',
        name: 'Lácteos',
        imageUrl: '/images/categories/cat-lacteos/0123456789abcdef.jpg',
      );
      await pumpCategories(tester);
      await tapAndSettle(tester, find.text('Lácteos').first);

      // La foto subida no se muestra como texto en el campo.
      expect(
        tester.widget<TextFormField>(urlField()).controller!.text,
        isEmpty,
      );
      await tester.enterText(urlField(), url);
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Guardar'));

      expect(repository.categories[1].imageUrl, url);
      expect(repository.uploads, isEmpty);
    });

    testWidgets('guardar sin tocar la foto la deja como estaba', (
      tester,
    ) async {
      const stored = '/images/categories/cat-lacteos/0123456789abcdef.jpg';
      repository.categories[1] = const Category(
        id: 'cat-lacteos',
        name: 'Lácteos',
        imageUrl: stored,
      );
      await pumpCategories(tester);
      await tapAndSettle(tester, find.text('Lácteos').first);

      await tester.enterText(field('Descripción'), 'Leches y yogures');
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Guardar'));

      expect(repository.categories[1].imageUrl, stored);
      expect(repository.categories[1].description, 'Leches y yogures');
    });

    testWidgets('una URL externa se ve en el campo; vaciarlo quita la foto', (
      tester,
    ) async {
      const external = 'https://cdn.tienda.pe/lacteos.jpg';
      repository.categories[1] = const Category(
        id: 'cat-lacteos',
        name: 'Lácteos',
        imageUrl: external,
      );
      await pumpCategories(tester);
      await tapAndSettle(tester, find.text('Lácteos').first);

      expect(
        tester.widget<TextFormField>(urlField()).controller!.text,
        external,
      );
      await tester.enterText(urlField(), '');
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Guardar'));

      expect(repository.categories[1].imageUrl, isNull);
    });

    testWidgets('en la app de Android también se puede tomar la foto', (
      tester,
    ) async {
      picker = FakePhotoPicker(canUseCamera: true);
      await pumpCategories(tester);
      await tapAndSettle(tester, find.text('Lácteos').first);

      await tapAndSettle(tester, find.text('Tomar foto'));
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Guardar'));

      expect(picker.sources, [PhotoSource.camera]);
      expect(repository.uploads, ['cat-lacteos']);
    });
  });
}
