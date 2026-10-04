import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:abarrotes_server/src/common/input_reader.dart';
import 'package:test/test.dart';

void main() {
  List<String> errorsOf(void Function() read) {
    try {
      read();
    } on ApiException catch (e) {
      return (e.message as List).cast<String>();
    }
    return const [];
  }

  test('las propiedades no permitidas son error, como en NestJS', () {
    final body = InputReader.body({'name': 'x', 'extra': 1}, allowed: {'name'});
    body.text('name', maxLength: 10);

    expect(errorsOf(body.check), ['La propiedad extra no está permitida']);
  });

  test('distingue obligatorio, opcional y nullable', () {
    final body = InputReader.body(
      {'opcional': null, 'nullable': null},
      allowed: {'obligatorio', 'opcional', 'nullable', 'ausente'},
    );

    expect(body.text('obligatorio', maxLength: 10), isNull);
    expect(body.integer('opcional', required: false), isNull);
    expect(body.text('nullable', maxLength: 10, nullable: true), isNull);
    expect(body.text('ausente', maxLength: 10, nullable: true), isNull);
    expect(body.has('nullable'), isTrue);
    expect(body.has('ausente'), isFalse);
    expect(errorsOf(body.check), [
      'obligatorio es obligatorio',
      'opcional no puede ser null',
    ]);
  });

  test('montos: hasta dos decimales y dentro del rango', () {
    final body = InputReader.body(
      {'a': 4.5, 'b': 4.555, 'c': 0, 'd': '4.5'},
      allowed: {'a', 'b', 'c', 'd'},
    );

    expect(body.cents('a', minCents: 1), 450);
    body.cents('b', minCents: 1);
    body.cents('c', minCents: 1);
    body.cents('d', minCents: 1);
    expect(errorsOf(body.check), [
      'b debe ser un número con 2 decimales como máximo',
      'c debe estar entre 0.01 y 99999999.99',
      'd debe ser un número con 2 decimales como máximo',
    ]);
  });

  test('textos: recorta espacios y respeta el largo', () {
    final body = InputReader.body(
      {'a': '  Arroz  ', 'b': '   ', 'c': 'abcdef'},
      allowed: {'a', 'b', 'c'},
    );

    expect(body.text('a', maxLength: 10), 'Arroz');
    body.text('b', maxLength: 10);
    body.text('c', maxLength: 3);
    expect(errorsOf(body.check), [
      'b debe ser un texto no vacío',
      'c admite como máximo 3 caracteres',
    ]);
  });

  test('fechas: sin zona horaria se toman como UTC', () {
    final body = InputReader.body(
      {
        'a': '2026-12-31',
        'b': '2026-12-31T10:00:00-05:00',
        'c': 'mañana',
      },
      allowed: {'a', 'b', 'c'},
    );

    expect(body.dateTime('a'), DateTime.utc(2026, 12, 31));
    expect(body.dateTime('b'), DateTime.utc(2026, 12, 31, 15));
    body.dateTime('c');
    expect(errorsOf(body.check), ['c debe ser una fecha ISO 8601']);
  });

  test('url, uuid, día y enum', () {
    final body = InputReader.body(
      {
        'url': 'ftp://x.pe/a.png',
        'id': 'no-uuid',
        'day': '2026-02-30',
        'status': 'otro',
      },
      allowed: {'url', 'id', 'day', 'status'},
    );

    body.url('url', maxLength: 100);
    body.uuid('id');
    body.day('day');
    body.oneOf('status', _Status.values);
    expect(errorsOf(body.check), [
      'url debe ser una URL http(s)',
      'id debe ser un UUID',
      'day debe ser una fecha AAAA-MM-DD',
      'status debe ser uno, dos o tres',
    ]);
  });

  test('un body que no es objeto es 400', () {
    expect(
      () => InputReader.body([1, 2], allowed: const {}),
      throwsA(isA<ApiException>()),
    );
  });

  group('objects', () {
    test('lee cada objeto de la lista con sus propias reglas', () {
      final body = InputReader.body(
        {
          'items': [
            {'id': 'a', 'n': 1},
            {'id': 'b', 'n': 2},
          ],
        },
        allowed: {'items'},
      );

      final items = body.objects('items', allowed: {'id', 'n'}, min: 1)!;
      final read = [
        for (final item in items)
          (item.text('id', maxLength: 5), item.integer('n', min: 1)),
      ];

      expect(read, [('a', 1), ('b', 2)]);
      expect(errorsOf(body.check), isEmpty);
    });

    test('los errores de cada objeto dicen su posición y van al mismo 400', () {
      final body = InputReader.body(
        {
          'name': '',
          'items': [
            {'n': 1},
            {'n': 0, 'extra': true},
            'no es un objeto',
          ],
        },
        allowed: {'name', 'items'},
      );

      body.text('name', maxLength: 5);
      for (final item in body.objects('items', allowed: {'n'})!) {
        item.integer('n', min: 1, max: 9);
      }

      expect(errorsOf(body.check), [
        'name debe ser un texto no vacío',
        'La propiedad items[1].extra no está permitida',
        'items[2] debe ser un objeto',
        'items[1].n debe estar entre 1 y 9',
      ]);
    });

    test('la lista tiene que ser una lista y respetar su tamaño', () {
      final body = InputReader.body(
        {'a': 'x', 'b': <Object?>[], 'c': List.filled(3, <String, Object?>{})},
        allowed: {'a', 'b', 'c', 'd'},
      );

      body.objects('a', allowed: const {});
      body.objects('b', allowed: const {}, min: 1);
      body.objects('c', allowed: const {}, min: 1, max: 2);
      body.objects('d', allowed: const {});

      expect(errorsOf(body.check), [
        'a debe ser una lista',
        'b debe tener al menos 1 elemento',
        'c debe tener entre 1 y 2 elementos',
        'd es obligatorio',
      ]);
    });
  });
}

enum _Status { uno, dos, tres }
