import '../common/input_reader.dart';
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

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Valida el JSON recibido; si algo falla, lanza un 400 con la lista de
  /// errores.
  static CreateUserRequest parse(Object? json) {
    final body = InputReader.body(
      json,
      allowed: {'firebaseUid', 'email', 'name', 'role', 'phone', 'address'},
    );
    final firebaseUid = body.text('firebaseUid', maxLength: 128);
    final email = body.text('email', maxLength: 254)?.toLowerCase();
    if (email != null && !_emailPattern.hasMatch(email)) {
      body.reject('email debe ser un correo válido');
    }
    final name = body.text('name', maxLength: 100);
    final role = body.oneOf('role', const [UserRole.admin, UserRole.staff]);
    final phone = body.text('phone', maxLength: 30, nullable: true);
    final address = body.text('address', maxLength: 300, nullable: true);
    body.check();

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
