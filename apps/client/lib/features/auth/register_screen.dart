import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../router/routes.dart';
import '../../session/session.dart';
import '../../session/session_provider.dart';
import '../account/pending_profile.dart';
import '../account/profile_fields.dart';
import '../shared/error_message.dart';
import 'auth_form.dart';

/// Registro de clientes. Toda cuenta nueva es de cliente: las de admin y staff
/// las crea un admin desde el panel.
///
/// Pide una contraseña fuerte (con su indicador y repetida), el celular, el
/// DNI (opcional) y aceptar los términos y la política de privacidad. Primero
/// crea la cuenta (Firebase y el servidor) y después guarda esos datos
/// (`PATCH /users/me`). Si eso falla (p. ej. el DNI ya está en otra cuenta),
/// la cuenta igual queda creada: lo escrito y el error pasan a "Mi cuenta"
/// ([pendingProfileProvider]), adonde lleva el ingreso de una cuenta
/// incompleta.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _dni = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _dni,
      _password,
      _repeat,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<SessionUser> _register() async {
    final session = ref.read(sessionProvider.notifier);
    final user = await session.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
    );
    final phone = _phone.text.trim();
    final dni = _dni.text.trim();
    try {
      return await session.updateProfile(
        phone: phone,
        dni: dni.isEmpty ? null : dni,
        acceptTerms: true,
      );
    } catch (error) {
      ref.read(pendingProfileProvider.notifier).set((
        phone: phone,
        dni: dni,
        error: errorMessage(error, 'No se pudieron guardar tus datos.'),
      ));
      return user;
    }
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
        PhoneField(controller: _phone),
        DniField(controller: _dni),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PasswordField(controller: _password, isNew: true),
            const SizedBox(height: 8),
            PasswordStrengthMeter(controller: _password),
          ],
        ),
        PasswordField(
          controller: _repeat,
          label: 'Repetir contraseña',
          isNew: true,
          validator: validateRepeatedPassword(_password),
          onSubmitted: submit,
        ),
        TermsCheckbox(
          value: _acceptedTerms,
          onChanged: (accepted) => setState(() => _acceptedTerms = accepted),
        ),
      ],
      submitLabel: 'Crear cuenta',
      submit: _register,
      switchLabel: '¿Ya tienes cuenta? Ingresa',
      switchRoute: Routes.login,
    );
  }
}
