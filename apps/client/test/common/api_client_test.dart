import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neils/common/api_client.dart';

void main() {
  /// Como responde el servidor: JSON en UTF-8, sin charset en el Content-Type.
  http.Response json(int status, Object? body) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json'},
  );

  ApiClient api(MockClientHandler handler, {String base = 'http://api.pe/'}) =>
      ApiClient(MockClient(handler), baseUrl: Uri.parse(base));

  Matcher failsWith(String message, {int? status}) => throwsA(
    isA<ApiFailure>()
        .having((f) => f.message, 'message', message)
        .having((f) => f.status, 'status', status),
  );

  test('GET con query y token; devuelve el JSON en UTF-8', () async {
    late http.Request sent;
    final body = await api((request) async {
      sent = request;
      return json(200, {'name': 'Leche evaporada Ñ'});
    }).get('/products', query: {'page': '2'}, idToken: 't', fallback: 'x');

    expect(sent.url.toString(), 'http://api.pe/products?page=2');
    expect(sent.headers['authorization'], 'Bearer t');
    expect(body, {'name': 'Leche evaporada Ñ'});
  });

  test('POST manda el body como JSON', () async {
    late http.Request sent;
    await api((request) async {
      sent = request;
      return json(201, {'id': 'o-1'});
    }).post('/orders', {'items': []}, idToken: 't', fallback: 'x');

    expect(sent.method, 'POST');
    expect(sent.headers['content-type'], startsWith('application/json'));
    expect(jsonDecode(sent.body), {'items': []});
  });

  group('errores', () {
    test('sin conexión o sin respuesta a tiempo', () {
      expect(
        api((_) async => throw http.ClientException('refused'))
            .get('/x', fallback: 'x'),
        failsWith('No se pudo conectar con el servidor. Revisa tu conexión.'),
      );
      expect(
        api((_) async => throw TimeoutException('lento'))
            .get('/x', fallback: 'x'),
        failsWith('El servidor no responde. Vuelve a intentar.'),
      );
    });

    test('401 y 5xx tienen su propio mensaje', () {
      expect(
        api((_) async => json(401, {'message': 'Token vencido'}))
            .get('/x', fallback: 'x'),
        failsWith('Tu sesión no es válida. Vuelve a ingresar.', status: 401),
      );
      expect(
        api((_) async => json(503, null)).get('/x', fallback: 'x'),
        failsWith(
          'El servidor no está disponible. Intenta más tarde.',
          status: 503,
        ),
      );
    });

    test('un 4xx muestra el mensaje del servidor, o la lista', () {
      expect(
        api(
          (_) async => json(409, {
            'statusCode': 409,
            'message': 'Stock insuficiente: Aceite tiene 2 unidades',
          }),
        ).post('/orders', {}, fallback: 'x'),
        failsWith('Stock insuficiente: Aceite tiene 2 unidades', status: 409),
      );
      expect(
        api(
          (_) async => json(400, {
            'message': [
              'items es obligatorio',
              'deliveryAddress es obligatorio',
            ],
          }),
        ).post('/orders', {}, fallback: 'x'),
        failsWith(
          'items es obligatorio. deliveryAddress es obligatorio',
          status: 400,
        ),
      );
    });

    test('un 4xx sin mensaje usa el de quien llama', () {
      expect(
        api(
          (_) async => http.Response('', 404),
        ).get('/products/1', fallback: 'Este producto ya no está disponible.'),
        failsWith('Este producto ya no está disponible.', status: 404),
      );
    });
  });
}
