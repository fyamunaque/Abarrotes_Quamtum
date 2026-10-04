import 'package:serverpod/serverpod.dart';

import 'http_json.dart';
import 'money.dart';
import 'store_time.dart';

/// Lee y valida la entrada de una petición (body JSON o query) juntando todos
/// los errores, como el ValidationPipe de NestJS: las propiedades que no están
/// en `allowed` también son error. [check] lanza un 400 con la lista.
///
/// Cada lectura distingue tres casos, que importan en los PATCH:
/// - `required` (por defecto): ausente o null es error.
/// - `required: false`: ausente devuelve null; null explícito es error.
/// - `nullable: true`: opcional, y ausente o null devuelven null (sirve para
///   borrar el campo). Para saber si vino, usar [has].
class InputReader {
  InputReader._(this._values, this._fromQuery, Set<String> allowed) {
    _errors.addAll([
      for (final field in _values.keys)
        if (!allowed.contains(field)) 'La propiedad $field no está permitida',
    ]);
  }

  /// Body JSON: tiene que ser un objeto.
  factory InputReader.body(Object? json, {required Set<String> allowed}) {
    if (json is! Map<String, dynamic>) {
      throw const ApiException.badRequest(['El body debe ser un objeto JSON']);
    }
    return InputReader._(json, false, allowed);
  }

  /// Query string: todos los valores llegan como texto.
  factory InputReader.query(Request request, {required Set<String> allowed}) =>
      InputReader._(request.url.queryParameters, true, allowed);

  final Map<String, Object?> _values;
  final bool _fromQuery;
  final _errors = <String>[];

  bool has(String field) => _values.containsKey(field);

  /// Registra un error propio de la ruta (p. ej. un formato especial).
  void reject(String message) => _errors.add(message);

  /// Lanza [ApiException] 400 con todos los errores, si hubo alguno.
  void check() {
    if (_errors.isNotEmpty) throw ApiException.badRequest(List.of(_errors));
  }

  String? text(
    String field, {
    required int maxLength,
    bool required = true,
    bool nullable = false,
  }) => _read(field, required, nullable, 'un texto no vacío', (value) {
    if (value is! String || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    if (trimmed.length > maxLength) {
      _errors.add('$field admite como máximo $maxLength caracteres');
    }
    return trimmed;
  });

  /// Un monto con dos decimales como máximo, en céntimos.
  int? cents(
    String field, {
    required int minCents,
    int maxCents = 9999999999,
    bool required = true,
  }) => _read(field, required, false, 'un número con 2 decimales como máximo', (
    value,
  ) {
    final amount = _fromQuery && value is String ? num.tryParse(value) : value;
    if (amount is! num) return null;
    final cents = toCents(amount);
    if (cents != null && (cents < minCents || cents > maxCents)) {
      _errors.add(
        '$field debe estar entre ${formatMoney(minCents)} y ${formatMoney(maxCents)}',
      );
    }
    return cents;
  });

  int? integer(
    String field, {
    int min = 0,
    int? max,
    bool required = true,
  }) => _read(field, required, false, 'un número entero', (value) {
    final number = _fromQuery && value is String ? int.tryParse(value) : value;
    if (number is! int) return null;
    if (number < min || (max != null && number > max)) {
      _errors.add(
        max == null
            ? '$field debe ser mayor o igual a $min'
            : '$field debe estar entre $min y $max',
      );
    }
    return number;
  });

  bool? boolean(String field, {bool required = true}) =>
      _read(field, required, false, 'true o false', (value) {
        if (value is bool) return value;
        if (_fromQuery && (value == 'true' || value == 'false')) {
          return value == 'true';
        }
        return null;
      });

  UuidValue? uuid(String field, {bool required = true}) =>
      _read(field, required, false, 'un UUID', (value) => parseUuid(value));

  /// Un día de la tienda, `AAAA-MM-DD`.
  String? day(String field, {bool required = true}) =>
      _read(field, required, false, 'una fecha AAAA-MM-DD', (value) {
        return value is String && isValidDay(value) ? value : null;
      });

  /// Fecha y hora ISO 8601. Sin zona horaria se toma como UTC, como en JS.
  DateTime? dateTime(String field, {bool nullable = false}) =>
      _read(field, true, nullable, 'una fecha ISO 8601', (value) {
        if (value is! String) return null;
        final parsed = DateTime.tryParse(value);
        if (parsed == null || parsed.isUtc) return parsed;
        final hasOffset = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(value);
        return hasOffset
            ? parsed.toUtc()
            : DateTime.utc(
                parsed.year,
                parsed.month,
                parsed.day,
                parsed.hour,
                parsed.minute,
                parsed.second,
                parsed.millisecond,
              );
      });

  /// Una URL http o https.
  String? url(String field, {required int maxLength, bool nullable = false}) =>
      _read(field, true, nullable, 'una URL http(s)', (value) {
        if (value is! String) return null;
        final uri = Uri.tryParse(value.trim());
        final valid =
            uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty;
        if (valid && value.trim().length > maxLength) {
          _errors.add('$field admite como máximo $maxLength caracteres');
        }
        return valid ? value.trim() : null;
      });

  /// Uno de los [options] por nombre.
  T? oneOf<T extends Enum>(
    String field,
    List<T> options, {
    bool required = true,
  }) => _read(
    field,
    required,
    false,
    _alternatives(options.map((option) => option.name).toList()),
    (value) => options.where((option) => option.name == value).firstOrNull,
  );

  T? _read<T>(
    String field,
    bool required,
    bool nullable,
    String expected,
    T? Function(Object value) parse,
  ) {
    final value = _values[field];
    if (value == null) {
      if (nullable) return null;
      if (_values.containsKey(field)) {
        _errors.add('$field no puede ser null');
      } else if (required) {
        _errors.add('$field es obligatorio');
      }
      return null;
    }
    final parsed = parse(value);
    if (parsed == null) _errors.add('$field debe ser $expected');
    return parsed;
  }
}

/// "a, b o c".
String _alternatives(List<String> names) => names.length == 1
    ? names.single
    : '${names.sublist(0, names.length - 1).join(', ')} o ${names.last}';

/// [value] como UUID, o null si no lo es.
UuidValue? parseUuid(Object? value) {
  if (value is! String) return null;
  try {
    return UuidValue.withValidation(value);
  } on FormatException {
    return null;
  }
}
