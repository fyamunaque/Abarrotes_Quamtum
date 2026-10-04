import 'package:abarrotes_server/src/auth/firebase_identity.dart';
import 'package:abarrotes_server/src/auth/firebase_token_verifier.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:test/test.dart';

import '../../support/test_tokens.dart';

void main() {
  late RsaKeyPair google;
  late RsaKeyPair attacker;
  late FirebaseTokenVerifier verifier;

  setUpAll(() {
    google = generateRsaKeyPair();
    attacker = generateRsaKeyPair();
  });

  setUp(() {
    verifier = FirebaseTokenVerifier(
      projectId: testProjectId,
      keys: FakeKeys({'llave-1': google.public}),
      now: () => testNow,
    );
  });

  Matcher rejectedFor(String reason) => throwsA(
    isA<InvalidFirebaseTokenException>().having(
      (e) => e.reason,
      'reason',
      contains(reason),
    ),
  );

  Map<String, dynamic> claimsWith(Map<String, dynamic> changes) => {
    ...validClaims(),
    ...changes,
  };

  int secondsFromNow(Duration offset) =>
      testNow.add(offset).millisecondsSinceEpoch ~/ 1000;

  test('un token válido devuelve la identidad', () async {
    final identity = await verifier.verify(signToken(google.private));

    expect(identity.uid, 'uid-ana');
    expect(identity.email, 'ana@example.com');
    expect(identity.emailVerified, isTrue);
    expect(identity.name, 'Ana Quispe');
  });

  test('un token sin email ni nombre deja esos datos en null', () async {
    final claims = validClaims()
      ..remove('email')
      ..remove('email_verified')
      ..remove('name');

    final identity = await verifier.verify(
      signToken(google.private, claims: claims),
    );

    expect(identity.email, isNull);
    expect(identity.emailVerified, isFalse);
    expect(identity.name, isNull);
  });

  group('rechaza', () {
    test('una firma hecha con otra llave', () {
      expect(
        verifier.verify(signToken(attacker.private)),
        rejectedFor('firma inválida'),
      );
    });

    test('un payload alterado después de firmar', () {
      final parts = signToken(google.private).split('.');
      final forged = signToken(
        attacker.private,
        claims: validClaims(uid: 'uid-admin'),
      ).split('.');

      expect(
        verifier.verify('${parts[0]}.${forged[1]}.${parts[2]}'),
        rejectedFor('firma inválida'),
      );
    });

    test('un kid que Google no publica', () {
      expect(
        verifier.verify(signToken(google.private, kid: 'otra')),
        rejectedFor('kid desconocido'),
      );
    });

    test('un token sin firmar (alg none)', () {
      expect(
        verifier.verify(unsignedToken(validClaims())),
        rejectedFor('algoritmo none'),
      );
    });

    test('un token HS256', () {
      final token = JWT(validClaims(), header: {'kid': 'llave-1'}).sign(
        SecretKey('secreto'),
        algorithm: JWTAlgorithm.HS256,
        noIssueAt: true,
      );

      expect(verifier.verify(token), rejectedFor('algoritmo HS256'));
    });

    test('un token vencido', () {
      final claims = claimsWith({'exp': secondsFromNow(Duration.zero)});

      expect(
        verifier.verify(signToken(google.private, claims: claims)),
        rejectedFor('vencido'),
      );
    });

    test('un iat en el futuro más allá de la tolerancia', () {
      final claims = claimsWith({'iat': secondsFromNow(Duration(minutes: 2))});

      expect(
        verifier.verify(signToken(google.private, claims: claims)),
        rejectedFor('iat futuro'),
      );
    });

    test('un auth_time en el futuro', () {
      final claims = claimsWith({
        'auth_time': secondsFromNow(Duration(minutes: 2)),
      });

      expect(
        verifier.verify(signToken(google.private, claims: claims)),
        rejectedFor('auth_time futuro'),
      );
    });

    test('un token de otro proyecto (aud)', () {
      final claims = claimsWith({'aud': 'otro-proyecto'});

      expect(
        verifier.verify(signToken(google.private, claims: claims)),
        rejectedFor('aud'),
      );
    });

    test('un emisor distinto (iss)', () {
      final claims = claimsWith({
        'iss': 'https://securetoken.google.com/otro-proyecto',
      });

      expect(
        verifier.verify(signToken(google.private, claims: claims)),
        rejectedFor('iss'),
      );
    });

    test('un sub vacío', () {
      expect(
        verifier.verify(
          signToken(google.private, claims: claimsWith({'sub': ''})),
        ),
        rejectedFor('sub'),
      );
    });

    test('un sub de más de 128 caracteres', () {
      final claims = claimsWith({'sub': 'u' * 129});

      expect(
        verifier.verify(signToken(google.private, claims: claims)),
        rejectedFor('sub'),
      );
    });

    test('un texto que no es un JWT', () {
      expect(verifier.verify('no-es-un-token'), rejectedFor('tres partes'));
      expect(verifier.verify('a.b.c'), rejectedFor('ilegible'));
    });
  });

  test('acepta un iat unos segundos adelantado (reloj de Google)', () async {
    final claims = claimsWith({'iat': secondsFromNow(Duration(seconds: 30))});

    final identity = await verifier.verify(
      signToken(google.private, claims: claims),
    );

    expect(identity.uid, 'uid-ana');
  });

  test('si no hay llaves de Google, propaga el error', () {
    final verifier = FirebaseTokenVerifier(
      projectId: testProjectId,
      keys: FakeKeys(
        {},
        error: const PublicKeysUnavailableException('sin red'),
      ),
      now: () => testNow,
    );

    expect(
      verifier.verify(signToken(google.private)),
      throwsA(isA<PublicKeysUnavailableException>()),
    );
  });
}
