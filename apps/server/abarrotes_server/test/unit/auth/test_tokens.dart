import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:abarrotes_server/src/auth/google_public_keys.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:pointycastle/export.dart' as pc;

/// Proyecto de Firebase ficticio de los tests.
const testProjectId = 'demo-abarrotes';

/// "Ahora" fijo de los tests.
final testNow = DateTime.utc(2026, 10, 1, 12);

typedef RsaKeyPair = ({RSAPrivateKey private, RSAPublicKey public});

/// Par de llaves RSA generado al vuelo, solo para firmar tokens de prueba.
RsaKeyPair generateRsaKeyPair() {
  final seed = Random.secure();
  final random = pc.FortunaRandom()
    ..seed(
      pc.KeyParameter(
        Uint8List.fromList(List.generate(32, (_) => seed.nextInt(256))),
      ),
    );
  final generator = pc.RSAKeyGenerator()
    ..init(
      pc.ParametersWithRandom(
        pc.RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
        random,
      ),
    );
  final pair = generator.generateKeyPair();
  return (
    private: RSAPrivateKey.raw(pair.privateKey),
    public: RSAPublicKey.raw(pair.publicKey),
  );
}

int _seconds(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;

/// Claims de un ID token válido emitido un minuto antes de [testNow].
Map<String, dynamic> validClaims({
  String uid = 'uid-ana',
  String? email = 'ana@example.com',
  String? name = 'Ana Quispe',
}) => {
  'iss': 'https://securetoken.google.com/$testProjectId',
  'aud': testProjectId,
  'auth_time': _seconds(testNow.subtract(const Duration(minutes: 5))),
  'iat': _seconds(testNow.subtract(const Duration(minutes: 1))),
  'exp': _seconds(testNow.add(const Duration(minutes: 59))),
  'sub': uid,
  'user_id': uid,
  if (email != null) ...{'email': email, 'email_verified': true},
  'name': ?name,
};

/// Token firmado con RS256, como los que emite Firebase.
String signToken(
  RSAPrivateKey key, {
  Map<String, dynamic>? claims,
  String kid = 'llave-1',
}) => JWT(
  claims ?? validClaims(),
  header: {'kid': kid},
).sign(key, algorithm: JWTAlgorithm.RS256, noIssueAt: true);

/// Token sin firmar (`alg: none`).
String unsignedToken(Map<String, dynamic> claims, {String kid = 'llave-1'}) {
  String encode(Object json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${encode({'alg': 'none', 'kid': kid})}.${encode(claims)}.';
}

/// Fuente de llaves en memoria.
class FakeKeys implements PublicKeySource {
  FakeKeys(this.keys, {this.error});

  final Map<String, JWTKey> keys;
  final Exception? error;

  @override
  Future<JWTKey?> keyFor(String kid) async {
    if (error case final error?) throw error;
    return keys[kid];
  }
}
