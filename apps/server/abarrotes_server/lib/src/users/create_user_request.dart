import '../common/http_json.dart';
import '../generated/protocol.dart';

/// Body de POST /users: un admin crea una cuenta admin o staff y la vincula
/// con el uid de una cuenta de Firebase que ya existe.
class CreateUserRequest {
  const CreateUserRequest({
    required this.firebaseUid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.address,
  });

  final String firebaseUid;

  /// En minúsculas y sin espacios alrededor.
  final String email;
  final String name;
  final UserRole role;
  final String? phone;
  final String? address;

  static const _fields = {
    'firebaseUid',
    'email',
    'name',
    'role',
    'phone',
    'address',
  };
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Valida el JSON recibido. Si algo falla, lanza un [ApiException] 400 con
  /// la lista de errores, como el ValidationPipe de NestJS.
  static CreateUserRequest parse(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const ApiException.badRequest(['El body debe ser un objeto JSON']);
    }
    final errors = <String>[
      for (final field in json.keys)
        if (!_fields.contains(field)) 'La propiedad $field no está permitida',
    ];

    String? text(
      String field, {
      required int maxLength,
      bool optional = false,
    }) {
      final value = json[field];
      if (value == null && optional) return null;
      if (value is! String || value.trim().isEmpty) {
        errors.add('$field es obligatorio y debe ser un texto');
        return null;
      }
      final trimmed = value.trim();
      if (trimmed.length > maxLength) {
        errors.add('$field admite como máximo $maxLength caracteres');
        return null;
      }
      return trimmed;
    }

    final firebaseUid = text('firebaseUid', maxLength: 128);
    final email = text('email', maxLength: 254)?.toLowerCase();
    if (email != null && !_emailPattern.hasMatch(email)) {
      errors.add('email debe ser un correo válido');
    }
    final name = text('name', maxLength: 100);
    final phone = text('phone', maxLength: 30, optional: true);
    final address = text('address', maxLength: 300, optional: true);
    final role = switch (json['role']) {
      'admin' => UserRole.admin,
      'staff' => UserRole.staff,
      _ => null,
    };
    if (role == null) errors.add('role debe ser admin o staff');

    if (errors.isNotEmpty) throw ApiException.badRequest(errors);
    return CreateUserRequest(
      firebaseUid: firebaseUid!,
      email: email!,
      name: name!,
      role: role!,
      phone: phone,
      address: address,
    );
  }
}
