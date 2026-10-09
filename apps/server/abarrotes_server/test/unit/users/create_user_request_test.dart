import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:abarrotes_server/src/generated/protocol.dart';
import 'package:abarrotes_server/src/users/create_user_request.dart';
import 'package:test/test.dart';

void main() {
  final valid = {
    'firebaseUid': 'uid-luis',
    'email': '  Luis@Tienda.PE ',
    'name': ' Luis Rojas ',
    'role': 'staff',
  };

  Matcher rejectedWith(String error) => throwsA(
    isA<ApiException>()
        .having((e) => e.statusCode, 'statusCode', 400)
        .having((e) => e.message, 'message', contains(error)),
  );

  test('acepta un body válido y normaliza email y nombre', () {
    final input = CreateUserRequest.parse(valid);

    expect(input.firebaseUid, 'uid-luis');
    expect(input.email, 'luis@tienda.pe');
    expect(input.name, 'Luis Rojas');
    expect(input.role, UserRole.staff);
    expect(input.phone, isNull);
    expect(input.address, isNull);
  });

  test('acepta phone y address opcionales, y role admin', () {
    final input = CreateUserRequest.parse({
      ...valid,
      'role': 'admin',
      'phone': '987654321',
      'address': null,
    });

    expect(input.role, UserRole.admin);
    expect(input.phone, '987654321');
    expect(input.address, isNull);
  });

  test('role customer no está permitido', () {
    expect(
      () => CreateUserRequest.parse({...valid, 'role': 'customer'}),
      rejectedWith('role debe ser admin o staff'),
    );
  });

  test('reúne todos los errores en una lista', () {
    expect(
      () => CreateUserRequest.parse({'email': 'no-es-correo', 'extra': 1}),
      throwsA(
        isA<ApiException>().having((e) => e.message, 'message', [
          'La propiedad extra no está permitida',
          'firebaseUid es obligatorio',
          'email debe ser un correo válido',
          'name es obligatorio',
          'role es obligatorio',
        ]),
      ),
    );
  });

  test('rechaza textos demasiado largos', () {
    expect(
      () => CreateUserRequest.parse({...valid, 'firebaseUid': 'u' * 129}),
      rejectedWith('firebaseUid admite como máximo 128 caracteres'),
    );
  });

  test('rechaza un body que no es un objeto', () {
    expect(
      () => CreateUserRequest.parse(['no', 'objeto']),
      rejectedWith('El body debe ser un objeto JSON'),
    );
  });
}
