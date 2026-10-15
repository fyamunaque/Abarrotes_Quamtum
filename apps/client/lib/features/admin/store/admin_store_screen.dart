import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../store/store_providers.dart';
import '../../../store/store_settings.dart';
import '../../shared/error_message.dart';
import '../shared/admin_form.dart';
import '../shared/admin_page.dart';
import '../shared/panel_note.dart';

/// Los datos de la tienda que ven los clientes al elegir recoger en tienda y
/// en sus pedidos de recojo (solo con `store.manage`, ver route_guard.dart).
class AdminStoreScreen extends ConsumerWidget {
  const AdminStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminPage(
      title: 'Tienda',
      children: [
        const PanelNote(
          'Los clientes ven estos datos al elegir recoger en tienda y en sus '
          'pedidos de recojo.',
        ),
        const SizedBox(height: 16),
        switch (ref.watch(storeSettingsProvider)) {
          AsyncValue(value: final store?) => _StoreForm(store),
          AsyncError(:final error) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    errorMessage(
                      error,
                      'No se pudieron cargar los datos de la tienda.',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(storeSettingsProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          _ => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }
}

class _StoreForm extends ConsumerStatefulWidget {
  const _StoreForm(this.store);

  /// Los datos guardados cuando se abrió la pantalla.
  final StoreSettings store;

  @override
  ConsumerState<_StoreForm> createState() => _StoreFormState();
}

class _StoreFormState extends ConsumerState<_StoreForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.store.name);
  late final _address = TextEditingController(text: widget.store.address);
  late final _reference = TextEditingController(text: widget.store.reference);
  late final _phone = TextEditingController(text: widget.store.phone);
  late final _hours = TextEditingController(text: widget.store.openingHours);
  late final _instructions = TextEditingController(
    text: widget.store.pickupInstructions,
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _address,
      _reference,
      _phone,
      _hours,
      _instructions,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Vacío: se borra.
  static String? _optional(TextEditingController controller) =>
      controller.text.trim().isEmpty ? null : controller.text.trim();

  static FormFieldValidator<String> _required(String message, int max) =>
      (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return message;
        if (text.length > max) return 'Usa hasta $max caracteres.';
        return null;
      };

  static FormFieldValidator<String> _upTo(int max) =>
      (value) => (value?.trim().length ?? 0) > max
      ? 'Usa hasta $max caracteres.'
      : null;

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final saved = await ref
          .read(storeRepositoryProvider)
          .update(
            StoreSettings(
              name: _name.text.trim(),
              address: _address.text.trim(),
              reference: _optional(_reference),
              phone: _optional(_phone),
              openingHours: _optional(_hours),
              pickupInstructions: _optional(_instructions),
            ),
          );
      // La tienda y el carrito ven los datos nuevos.
      ref.invalidate(storeSettingsProvider);
      if (!mounted) return;
      _name.text = saved.name;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Guardaste los datos de la tienda.')),
        );
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = errorMessage(
            error,
            'No se pudieron guardar los datos de la tienda.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la tienda',
                    ),
                    validator: _required(
                      'Escribe el nombre de la tienda.',
                      100,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _address,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      helperText: 'Calle, número y distrito',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: _required(
                      'Escribe la dirección de la tienda.',
                      255,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FieldPair(
                    TextFormField(
                      controller: _reference,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: 'Referencia (opcional)',
                        hintText: 'Frente al parque',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: _upTo(255),
                    ),
                    TextFormField(
                      controller: _phone,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono (opcional)',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: _upTo(30),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _hours,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Horario de atención (opcional)',
                      hintText: 'Lun a sáb de 8 a 20 h',
                      alignLabelWithHint: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 3,
                    validator: _upTo(500),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _instructions,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Instrucciones de recojo (opcional)',
                      hintText: 'Muestra tu código en caja.',
                      alignLabelWithHint: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 5,
                    validator: _upTo(500),
                  ),
                  const SizedBox(height: 16),
                  if (_error case final error?) ...[
                    FormError(error),
                    const SizedBox(height: 16),
                  ],
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton(
                      onPressed: _busy ? null : _save,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
