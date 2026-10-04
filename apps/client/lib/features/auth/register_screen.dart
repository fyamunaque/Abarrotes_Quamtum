import 'package:flutter/material.dart';

import '../../router/routes.dart';
import 'auth_form.dart';

/// Registro de clientes. Toda cuenta nueva es de cliente: las de admin y staff
/// las crea un admin desde el panel.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthForm(
      title: 'Crear una cuenta',
      fields: [
        TextField(
          decoration: InputDecoration(labelText: 'Nombre'),
          autofillHints: [AutofillHints.name],
        ),
        TextField(
          decoration: InputDecoration(labelText: 'Correo'),
          keyboardType: TextInputType.emailAddress,
          autofillHints: [AutofillHints.email],
        ),
        TextField(
          decoration: InputDecoration(labelText: 'Contraseña'),
          obscureText: true,
          autofillHints: [AutofillHints.newPassword],
        ),
      ],
      submitLabel: 'Crear cuenta',
      switchLabel: '¿Ya tienes cuenta? Ingresa',
      switchRoute: Routes.login,
    );
  }
}
