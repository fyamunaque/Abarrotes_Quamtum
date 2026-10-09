import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../router/routes.dart';
import '../../session/session_provider.dart';
import 'auth_form.dart';

/// Registro de clientes. Toda cuenta nueva es de cliente: las de admin y staff
/// las crea un admin desde el panel.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthForm(
      title: 'Crear una cuenta',
      fields: (submit) => [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Nombre'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          validator: validateName,
        ),
        EmailField(controller: _email),
        PasswordField(controller: _password, onSubmitted: submit, isNew: true),
      ],
      submitLabel: 'Crear cuenta',
      submit: () => ref
          .read(sessionProvider.notifier)
          .register(
            name: _name.text,
            email: _email.text,
            password: _password.text,
          ),
      switchLabel: '¿Ya tienes cuenta? Ingresa',
      switchRoute: Routes.login,
    );
  }
}
