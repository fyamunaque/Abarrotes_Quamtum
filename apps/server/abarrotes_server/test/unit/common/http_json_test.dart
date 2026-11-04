import 'dart:convert';

import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:test/test.dart';

void main() {
  test('un error con details suma esas claves al JSON', () async {
    final response = await withApiErrors(
      () async => throw const ApiException.conflict(
        'Se acumula con otras promociones del producto',
        details: {'overlaps': []},
      ),
    );

    expect(response.statusCode, 409);
    final body = jsonDecode(await response.readAsString());
    expect(body, {
      'statusCode': 409,
      'message': 'Se acumula con otras promociones del producto',
      'error': 'Conflict',
      'overlaps': [],
    });
  });
}
