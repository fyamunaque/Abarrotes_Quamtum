import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/categories/admin_categories_providers.dart';
import '../../../admin/categories/admin_categories_repository.dart';
import '../../../admin/products/photo_picker.dart';
import '../../../catalog/category.dart';
import '../../catalog/category_photo.dart';
import '../../shared/error_message.dart';
import '../shared/admin_form.dart';

/// Lo que pasó en el formulario: se guardó (o creó) una categoría, o se
/// borró.
sealed class CategoryFormResult {
  const CategoryFormResult();
}

class CategorySaved extends CategoryFormResult {
  const CategorySaved(this.category);

  final Category category;
}

class CategoryDeleted extends CategoryFormResult {
  const CategoryDeleted(this.name);

  final String name;
}

/// Crear o editar una categoría: el nombre, la descripción (hasta 80
/// caracteres) y la foto. Editando, también borrarla: si tiene productos, el
/// servidor lo impide y el aviso se muestra aquí.
class CategoryForm extends ConsumerStatefulWidget {
  const CategoryForm({super.key, this.row});

  /// La categoría a editar; sin ella, una nueva.
  final AdminCategory? row;

  static const maxDescription = 80;

  @override
  ConsumerState<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.row?.category.name);
  late final _description = TextEditingController(
    text: widget.row?.category.description,
  );
  PickedPhoto? _photo;

  /// Se tocó "Quitar foto": al guardar, la categoría queda sin foto.
  bool _removePhoto = false;

  /// La categoría ya guardada en este formulario: si después falla la foto,
  /// reintentar guarda sobre ella en vez de crearla otra vez.
  Category? _saved;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick(PhotoSource source) async {
    try {
      final photo = await ref.read(photoPickerProvider).pick(source);
      if (photo != null && mounted) {
        setState(() {
          _photo = photo;
          _removePhoto = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = errorMessage(error, 'No se pudo abrir la foto.'),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final notifier = ref.read(adminCategoriesProvider.notifier);
    final name = _name.text.trim();
    final description = _description.text.trim();
    try {
      var category = switch (_saved ?? widget.row?.category) {
        null => await notifier.create(
          name,
          description: description.isEmpty ? null : description,
        ),
        final existing => await notifier.save(
          existing.id,
          name: name,
          description: description,
        ),
      };
      _saved = category;
      if (_photo case final photo?) {
        category = await notifier.uploadImage(
          category.id,
          photo.bytes,
          contentType: photo.contentType,
        );
      } else if (_removePhoto && category.imageUrl != null) {
        category = await notifier.removeImage(category.id);
      }
      if (mounted) Navigator.of(context).pop(CategorySaved(category));
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = errorMessage(error, 'No se pudo guardar la categoría.');
        });
      }
    }
  }

  Future<void> _delete() async {
    final row = widget.row!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar la categoría?'),
        content: Text(
          'Se borra "${row.category.name}". Solo se puede si no tiene '
          'productos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(adminCategoriesProvider.notifier).delete(row.category.id);
      if (mounted) {
        Navigator.of(context).pop(CategoryDeleted(row.category.name));
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = errorMessage(error, 'No se pudo borrar la categoría.');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final picker = ref.watch(photoPickerProvider);
    final current = widget.row?.category;
    final hasPhoto =
        _photo != null || (current?.imageUrl != null && !_removePhoto);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre'),
            textInputAction: TextInputAction.next,
            validator: (value) {
              final name = value?.trim() ?? '';
              if (name.isEmpty) return 'Escribe el nombre.';
              if (name.length > 60) return 'Como máximo 60 caracteres.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              helperText: 'Una línea para el encabezado de la categoría',
            ),
            // Se ve el contador, pero se puede pasar: el mensaje lo dice.
            maxLength: CategoryForm.maxDescription,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            validator: (value) =>
                (value?.trim().length ?? 0) > CategoryForm.maxDescription
                ? 'Como máximo ${CategoryForm.maxDescription} caracteres.'
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 90,
                  child: switch (_photo) {
                    final photo? => Image.memory(
                      photo.bytes,
                      fit: BoxFit.cover,
                      semanticLabel: 'La foto elegida',
                    ),
                    null => CategoryPhoto(
                      category: Category(
                        id: current?.id ?? 'nueva',
                        name: current?.name ?? _name.text,
                        imageUrl: _removePhoto ? null : current?.imageUrl,
                      ),
                    ),
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _pick(PhotoSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(hasPhoto ? 'Cambiar foto' : 'Elegir foto'),
                    ),
                    if (picker.canUseCamera)
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _pick(PhotoSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Tomar foto'),
                      ),
                    if (hasPhoto)
                      TextButton.icon(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _photo = null;
                                _removePhoto = true;
                              }),
                        icon: const Icon(Icons.hide_image_outlined),
                        label: const Text('Quitar foto'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 16),
            FormError(error),
          ],
          const SizedBox(height: 24),
          FormActions(
            submitLabel: widget.row == null ? 'Crear' : 'Guardar',
            onSubmit: _submit,
            busy: _busy,
            destructive: widget.row == null
                ? null
                : DestructiveButton(
                    label: 'Borrar categoría',
                    onPressed: _busy ? null : _delete,
                  ),
          ),
        ],
      ),
    );
  }
}
