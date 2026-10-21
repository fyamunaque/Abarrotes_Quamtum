import 'dart:convert';

import 'package:abarrotes_server/src/push/fcm_push_sender.dart';
import 'package:abarrotes_server/src/push/google_access_tokens.dart';
import 'package:abarrotes_server/src/push/push_sender.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pointycastle/asn1.dart';
import 'package:test/test.dart';

import '../../support/test_tokens.dart';

/// La llave en PEM PKCS#1, como la puede traer el JSON de una cuenta de
/// servicio.
String _pkcs1Pem(RSAPrivateKey key) {
  final k = key.key;
  final p = k.p!;
  final q = k.q!;
  final d = k.privateExponent!;
  final der = ASN1Sequence(
    elements: [
      ASN1Integer(BigInt.zero),
      ASN1Integer(k.modulus),
      ASN1Integer(k.publicExponent),
      ASN1Integer(d),
      ASN1Integer(p),
      ASN1Integer(q),
      ASN1Integer(d % (p - BigInt.one)),
      ASN1Integer(d % (q - BigInt.one)),
      ASN1Integer(q.modInverse(p)),
    ],
  ).encode();
  final lines = RegExp('.{1,64}').allMatches(base64.encode(der));
  return [
    '-----BEGIN RSA PRIVATE KEY-----',
    for (final line in lines) line.group(0)!,
    '-----END RSA PRIVATE KEY-----',
  ].join('\n');
}

void main() {
  late RsaKeyPair keys;
  late ServiceAccount account;

  setUpAll(() {
    keys = generateRsaKeyPair();
    account = ServiceAccount(
      projectId: testProjectId,
      clientEmail: 'push@demo-abarrotes.iam.gserviceaccount.com',
      privateKey: _pkcs1Pem(keys.private),
      tokenUri: Uri.parse('https://oauth2.googleapis.com/token'),
    );
  });

  http.Response json(int status, Object? body) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  group('ServiceAccount', () {
    test('lee el JSON de Firebase y nunca muestra la llave', () {
      final read = ServiceAccount.fromJson({
        'type': 'service_account',
        'project_id': 'demo-abarrotes',
        'client_email': 'push@demo.iam.gserviceaccount.com',
        'private_key': 'LLAVE-SECRETA',
        'token_uri': 'https://oauth2.googleapis.com/token',
      });

      expect(read.projectId, 'demo-abarrotes');
      expect(read.tokenUri.host, 'oauth2.googleapis.com');
      expect(read.toString(), isNot(contains('LLAVE-SECRETA')));
      expect(
        () => ServiceAccount.fromJson({'type': 'authorized_user'}),
        throwsFormatException,
      );
    });
  });

  group('GoogleAccessTokens', () {
    test(
      'canjea un JWT firmado por la cuenta de servicio y lo guarda',
      () async {
        final requests = <http.Request>[];
        var now = testNow;
        final tokens = GoogleAccessTokens(
          account,
          scope: FcmPushSender.scope,
          now: () => now,
          client: MockClient((request) async {
            requests.add(request);
            return json(200, {
              'access_token': 'ya29.token-${requests.length}',
              'expires_in': 3600,
              'token_type': 'Bearer',
            });
          }),
        );

        expect(await tokens.token(), 'ya29.token-1');
        final request = requests.single;
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://oauth2.googleapis.com/token');
        final form = Uri.splitQueryString(request.body);
        expect(
          form['grant_type'],
          'urn:ietf:params:oauth:grant-type:jwt-bearer',
        );
        // La aserción está firmada con la llave de la cuenta de servicio.
        final assertion = JWT.verify(
          form['assertion']!,
          keys.public,
          checkExpiresIn: false,
          checkHeaderType: false,
        );
        final seconds = testNow.millisecondsSinceEpoch ~/ 1000;
        expect(assertion.payload, {
          'iss': account.clientEmail,
          'scope': 'https://www.googleapis.com/auth/firebase.messaging',
          'aud': 'https://oauth2.googleapis.com/token',
          'iat': seconds,
          'exp': seconds + 3600,
        });

        // Guardado hasta un minuto antes de vencer.
        now = testNow.add(const Duration(minutes: 58));
        expect(await tokens.token(), 'ya29.token-1');
        now = testNow.add(const Duration(minutes: 59, seconds: 1));
        expect(await tokens.token(), 'ya29.token-2');
        expect(requests, hasLength(2));
      },
    );

    test('varios pedidos a la vez canjean una sola vez', () async {
      var calls = 0;
      final tokens = GoogleAccessTokens(
        account,
        scope: FcmPushSender.scope,
        now: () => testNow,
        client: MockClient((_) async {
          calls++;
          return json(200, {'access_token': 'ya29.a', 'expires_in': 3600});
        }),
      );

      await Future.wait([tokens.token(), tokens.token(), tokens.token()]);

      expect(calls, 1);
    });

    test('si Google lo rechaza, lo dice sin mostrar la llave', () async {
      final tokens = GoogleAccessTokens(
        account,
        scope: FcmPushSender.scope,
        client: MockClient(
          (_) async => json(400, {'error': 'invalid_grant'}),
        ),
      );

      await expectLater(
        tokens.token(),
        throwsA(
          isA<AccessTokenException>().having(
            (e) => e.reason,
            'reason',
            allOf(
              contains('400'),
              contains('invalid_grant'),
              isNot(contains('PRIVATE KEY')),
            ),
          ),
        ),
      );
    });
  });

  group('FcmPushSender', () {
    const message = PushMessage(
      title: 'Nueva oferta exclusiva',
      body: 'Arroz extra 5 kg a S/ 17.90',
      data: {'type': 'vip_promotion', 'productId': 'p-1'},
    );

    /// Un sender cuyo canje de token responde bien y FCM responde [fcm].
    (FcmPushSender, List<http.Request>) sender(
      Future<http.Response> Function(http.Request request) fcm,
    ) {
      final sent = <http.Request>[];
      final client = MockClient((request) async {
        if (request.url.host == 'oauth2.googleapis.com') {
          return json(200, {'access_token': 'ya29.a', 'expires_in': 3600});
        }
        sent.add(request);
        return fcm(request);
      });
      return (
        FcmPushSender(
          projectId: testProjectId,
          accessTokens: GoogleAccessTokens(
            account,
            scope: FcmPushSender.scope,
            client: client,
          ),
          client: client,
        ),
        sent,
      );
    }

    test('manda un mensaje al token, con el access token', () async {
      final (push, sent) = sender((_) async => json(200, {'name': 'x'}));

      final outcome = await push.send('fcm-token-1', message);

      expect(outcome.result, PushResult.sent);
      final request = sent.single;
      expect(
        request.url.toString(),
        'https://fcm.googleapis.com/v1/projects/demo-abarrotes/messages:send',
      );
      expect(request.headers['authorization'], 'Bearer ya29.a');
      expect(jsonDecode(request.body), {
        'message': {
          'token': 'fcm-token-1',
          'notification': {
            'title': 'Nueva oferta exclusiva',
            'body': 'Arroz extra 5 kg a S/ 17.90',
          },
          'data': {'type': 'vip_promotion', 'productId': 'p-1'},
        },
      });
    });

    test('un token dado de baja o mal formado es inválido', () async {
      final (unregistered, _) = sender(
        (_) async => json(404, {
          'error': {
            'status': 'NOT_FOUND',
            'details': [
              {
                '@type': 'type.googleapis.com/google.firebase.fcm.v1.FcmError',
                'errorCode': 'UNREGISTERED',
              },
            ],
          },
        }),
      );
      final (malformed, _) = sender(
        (_) async => json(400, {
          'error': {
            'status': 'INVALID_ARGUMENT',
            'details': [
              {
                '@type': 'type.googleapis.com/google.rpc.BadRequest',
                'fieldViolations': [
                  {'field': 'message.token', 'description': 'Invalid'},
                ],
              },
            ],
          },
        }),
      );

      expect(
        (await unregistered.send('t', message)).result,
        PushResult.invalidToken,
      );
      expect(
        (await malformed.send('t', message)).result,
        PushResult.invalidToken,
      );
    });

    test('los demás errores no borran el token y dicen por qué', () async {
      for (final response in [
        json(404, {
          'error': {'status': 'NOT_FOUND'},
        }),
        json(500, {
          'error': {'status': 'INTERNAL'},
        }),
        json(429, {
          'error': {'status': 'RESOURCE_EXHAUSTED'},
        }),
      ]) {
        final (push, _) = sender((_) async => response);

        final outcome = await push.send('t', message);

        expect(outcome.result, PushResult.failed);
        expect(outcome.reason, contains('${response.statusCode}'));
      }
    });

    test('sin red o sin access token, falla sin lanzar', () async {
      final (offline, _) = sender(
        (_) async => throw http.ClientException('sin red'),
      );
      final noToken = FcmPushSender(
        projectId: testProjectId,
        accessTokens: GoogleAccessTokens(
          account,
          scope: FcmPushSender.scope,
          client: MockClient(
            (_) async => json(401, {'error': 'invalid_client'}),
          ),
        ),
      );

      expect((await offline.send('t', message)).result, PushResult.failed);
      final outcome = await noToken.send('t', message);
      expect(outcome.result, PushResult.failed);
      expect(outcome.reason, contains('invalid_client'));
    });
  });

  test('tokenHint muestra solo el final', () {
    expect(tokenHint('abcdefghijklmnop'), '…klmnop');
    expect(tokenHint('abc'), '…');
  });
}
