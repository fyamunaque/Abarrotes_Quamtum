import 'package:flutter/material.dart';

import '../../router/routes.dart';
import 'auth_form.dart';

/// Ingreso. [from] es la ruta protegida que lo trajo aquí (p. ej. /admin):
/// después de ingresar se vuelve a ella.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, this.from});

  final String? from;

  @override
  Widget build(BuildContext context) {
    return const AuthForm(
      title: 'Ingresar',
      fields: [
        TextField(
          decoration: InputDecoration(labelText: 'Correo'),
          keyboardType: TextInputType.emailAddress,
          autofillHints: [AutofillHints.email],
        ),
        TextField(
          decoration: InputDecoration(labelText: 'Contraseña'),
          obscureText: true,
          autofillHints: [AutofillHints.password],
        ),
      ],
      submitLabel: 'Ingresar',
      switchLabel: '¿No tienes cuenta? Crea una',
      switchRoute: Routes.register,
    );
  }
}
