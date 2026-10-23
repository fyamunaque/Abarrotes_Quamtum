import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/products/photo_picker.dart';
import '../../../admin/products/product_input.dart';
import '../../../catalog/catalog_providers.dart';
import '../../../catalog/category.dart';
import '../../../catalog/product.dart';
import '../../../common/api_client.dart';
import '../../../common/money.dart';
import '../../catalog/product_photo.dart';
import '../../shared/date_format.dart';
import '../../shared/error_message.dart';
import '../shared/admin_form.dart';
import '../shared/admin_page.dart';

/// Crear ([product] null) o editar un producto. Valida lo mismo que el
/// servidor; lo que el servidor rechaza igual (un SKU que ya existe) se
/// muestra en su campo. Se cierra con el producto como quedó.
///
/// La foto se sube (de la galería, los archivos o la cámara) o se pega la URL
/// de una imagen. Una foto elegida se sube después de guardar el producto: si
/// eso falla, el producto ya quedó guardado y el formulario ofrece volver a
/// intentar solo la foto.
class ProductForm extends ConsumerStatefulWidget {
  const ProductForm({
    super.key,
    this.product,
    required this.onSubmit,
    required this.onUploadImage,
    this.onDeactivate,
  });

  final Product? product;

  /// Crea o guarda con lo del formulario.
  final Future<Product> Function(ProductInput input) onSubmit;

  /// Le sube la foto elegida al producto ya guardado.
  final Future<Product> Function(String productId, PickedPhoto photo)
  onUploadImage;

  /// Lo da de baja. Solo al editar un producto activo.
  final Future<Product> Function()? onDeactivate;

  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _price;
  late final TextEditingController _initialStock;
  late final TextEditingController _minStock;
  late final TextEditingController _imageUrl;
  late final TextEditingController _description;
  String? _categoryId;
  DateTime? _expiration;
  late bool _active;

  /// La foto elegida, que se sube al guardar.
  PickedPhoto? _photo;

  /// Si se mantiene la foto subida que ya tiene el producto (no se muestra
  /// en el campo de URL: es una ruta de este servidor).
  late bool _keepStoredPhoto;

  /// El producto ya guardado cuando falló la subida de la foto: guardar
  /// otra vez solo reintenta la foto.
  Product? _saved;

  bool _busy = false;
  String? _error;

  /// El 409 del servidor: ya hay un producto con ese SKU.
  String? _skuError;

  bool get _creating => widget.product == null;

  /// Los campos se editan salvo mientras guarda o cuando el producto ya se
  /// guardó y solo falta la foto.
  bool get _editable => !_busy && _saved == null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name);
    _sku = TextEditingController(text: product?.sku);
    _price = TextEditingController(
      text: product == null ? null : formatSolesInput(product.priceCents),
    );
    _initialStock = TextEditingController(text: '0');
    _minStock = TextEditingController(text: '${product?.minStock ?? 0}');
    final stored = _isStoredPhoto(product?.imageUrl);
    _keepStoredPhoto = stored;
    _imageUrl = TextEditingController(text: stored ? null : product?.imageUrl);
    _description = TextEditingController(text: product?.description);
    _categoryId = product?.category?.id;
    _expiration = product?.expirationDate;
    _active = product?.active ?? true;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _sku,
      _price,
      _initialStock,
      _minStock,
      _imageUrl,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  ProductInput _input() {
    String? optional(TextEditingController controller) =>
        controller.text.trim().isEmpty ? null : controller.text.trim();
    return ProductInput(
      name: _name.text.trim(),
      sku: _sku.text.trim(),
      priceCents: parseSolesInput(_price.text)!,
      categoryId: _categoryId!,
      minStock: int.parse(_minStock.text),
      active: _active,
      description: optional(_description),
      imageUrl: _imageUrlToSave(optional(_imageUrl)),
      expirationDate: _expiration,
      initialStock: _creating ? int.parse(_initialStock.text) : 0,
    );
  }

  /// Lo que va en `imageUrl`. Con una foto elegida, la que tenía (la nueva
  /// la reemplaza al subirse; si la subida falla, no pierde la anterior).
  String? _imageUrlToSave(String? typed) {
    if (typed != null) return typed;
    final current = widget.product?.imageUrl;
    if (_photo != null) return current;
    return _keepStoredPhoto ? current : null;
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _skuError = null);
    final saved = _saved;
    if (saved == null && !_formKey.currentState!.validate()) return;
    await _run(() async {
      final product = saved ?? await widget.onSubmit(_input());
      final photo = _photo;
      if (photo == null) return product;
      try {
        return await widget.onUploadImage(product.id, photo);
      } catch (error) {
        _saved = product;
        throw _PhotoFailure(errorMessage(error, 'No se pudo subir la foto.'));
      }
    }, fallback: 'No se pudo guardar el producto.');
  }

  Future<void> _pickPhoto(PhotoSource source) async {
    try {
      final photo = await ref.read(photoPickerProvider).pick(source);
      if (photo == null || !mounted) return;
      setState(() {
        _photo = photo;
        _imageUrl.clear();
        _keepStoredPhoto = false;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = errorMessage(error, 'No se pudo abrir la foto.'),
        );
      }
    }
  }

  void _removePhoto() => setState(() {
    _photo = null;
    _imageUrl.clear();
    _keepStoredPhoto = false;
  });

  Future<void> _deactivate() async {
    final confirmed = await confirmAction(
      context,
      title: '¿Dar de baja "${widget.product!.name}"?',
      message:
          'Deja de verse en la tienda. Sus pedidos y su historial se '
          'mantienen, y puedes volver a activarlo desde aquí.',
      confirmLabel: 'Dar de baja',
    );
    if (!confirmed) return;
    await _run(
      widget.onDeactivate!,
      fallback: 'No se pudo dar de baja el producto.',
    );
  }

  /// Corre [action] mostrando el progreso, y cierra con su resultado. Si
  /// falla, deja el formulario abierto con el error.
  Future<void> _run(
    Future<Product> Function() action, {
    required String fallback,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final product = await action();
      if (mounted) Navigator.of(context).pop(product);
    } on _PhotoFailure catch (failure) {
      if (mounted) {
        setState(
          () => _error =
              'Se guardó el producto, pero no se pudo subir la foto: '
              '${failure.message}',
        );
      }
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        if (failure.status == 409) {
          _skuError = failure.message;
        } else {
          _error = failure.message;
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error, fallback));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickExpiration() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final current = switch (_expiration) {
      final day? => DateTime(day.year, day.month, day.day),
      null => today,
    };
    final picked = await showDatePicker(
      context: context,
      helpText: 'Vencimiento',
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 10, 12, 31),
    );
    if (picked != null) setState(() => _expiration = picked);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final categories = ref.watch(categoriesProvider);
    final loaded = categories.value ?? const <Category>[];
    // Mientras cargan (o si la del producto ya no está), la que tiene.
    final options = [
      ...loaded,
      if (product?.category case final current?
          when !loaded.any((category) => category.id == current.id))
        current,
    ];

    return Form(
      key: _formKey,
      // Un campo con error se vuelve a validar mientras se corrige.
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            enabled: _editable,
            decoration: const InputDecoration(labelText: 'Nombre'),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            validator: (value) => _requiredText(value, 'el nombre', 150),
          ),
          const SizedBox(height: 16),
          FieldPair(
            TextFormField(
              controller: _sku,
              enabled: _editable,
              decoration: const InputDecoration(labelText: 'SKU'),
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              forceErrorText: _skuError,
              onChanged: (_) {
                if (_skuError != null) setState(() => _skuError = null);
              },
              validator: (value) => _requiredText(value, 'el SKU', 50),
            ),
            TextFormField(
              controller: _price,
              enabled: _editable,
              decoration: const InputDecoration(
                labelText: 'Precio',
                prefixText: 'S/ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              validator: validatePrice,
            ),
          ),
          const SizedBox(height: 16),
          FieldPair(
            DropdownButtonFormField<String>(
              style: Theme.of(context).textTheme.bodyLarge,
              initialValue: _categoryId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Categoría',
                helperText: categories.hasError && loaded.isEmpty
                    ? 'No se pudieron cargar las categorías.'
                    : null,
                suffixIcon: categories.hasError && loaded.isEmpty
                    ? IconButton(
                        tooltip: 'Volver a cargar las categorías',
                        icon: const Icon(Icons.refresh),
                        onPressed: () => ref.invalidate(categoriesProvider),
                      )
                    : null,
              ),
              items: [
                for (final category in options)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: _editable
                  ? (id) => setState(() => _categoryId = id)
                  : null,
              validator: (id) => id == null ? 'Elige una categoría.' : null,
            ),
            _DateField(
              label: 'Vencimiento (opcional)',
              value: _expiration,
              enabled: _editable,
              onPick: _pickExpiration,
              onClear: () => setState(() => _expiration = null),
            ),
          ),
          const SizedBox(height: 16),
          FieldPair(
            product == null
                ? _CountField(
                    controller: _initialStock,
                    enabled: _editable,
                    label: 'Stock inicial',
                    helper: 'Después se cambia en Inventario.',
                  )
                : InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Stock actual',
                      helperText: 'Se cambia en Inventario.',
                      enabled: false,
                    ),
                    child: Text('${product.stock}'),
                  ),
            _CountField(
              controller: _minStock,
              enabled: _editable,
              label: 'Stock mínimo',
              helper: 'Con esto o menos, es stock bajo.',
            ),
          ),
          const SizedBox(height: 16),
          // La inicial del marcador sigue al nombre mientras se escribe.
          ListenableBuilder(
            listenable: _name,
            builder: (context, _) => _PhotoSection(
              photo: _photo,
              // Una URL escrita se ve recién cuando es válida: a medio
              // escribir, pediría imágenes que no existen.
              url: switch (_imageUrl.text.trim()) {
                '' => _keepStoredPhoto ? widget.product?.imageUrl : null,
                final typed => validateImageUrl(typed) == null ? typed : null,
              },
              name: _name.text,
              colorKey: _categoryId,
              enabled: _editable,
              canUseCamera: ref.watch(photoPickerProvider).canUseCamera,
              onPick: _pickPhoto,
              onRemove: _removePhoto,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _imageUrl,
            enabled: _editable,
            decoration: const InputDecoration(
              labelText: 'O pega la URL de una imagen (opcional)',
              hintText: 'https://…',
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            validator: validateImageUrl,
            // Una URL escrita reemplaza a la foto elegida.
            onChanged: (text) => setState(() {
              if (text.trim().isNotEmpty) {
                _photo = null;
                _keepStoredPhoto = false;
              }
            }),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            enabled: _editable,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              alignLabelWithHint: true,
            ),
            textCapitalization: TextCapitalization.sentences,
            minLines: 2,
            maxLines: 5,
            validator: (value) => (value?.trim().length ?? 0) > 1000
                ? 'Máximo 1000 caracteres.'
                : null,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activo'),
            subtitle: Text(
              _active ? 'Se ve en la tienda.' : 'No se ve en la tienda.',
            ),
            value: _active,
            onChanged: _editable ? (on) => setState(() => _active = on) : null,
          ),
          const SizedBox(height: 16),
          if (_error case final error?) ...[
            FormError(error),
            const SizedBox(height: 16),
          ],
          FormActions(
            submitLabel: _saved != null
                ? 'Reintentar la foto'
                : _creating
                ? 'Crear producto'
                : 'Guardar cambios',
            onSubmit: _submit,
            busy: _busy,
            destructive: widget.onDeactivate == null
                ? null
                : DestructiveButton(
                    label: 'Dar de baja',
                    onPressed: _busy ? null : _deactivate,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Si [url] es de una foto subida al servidor (`/images/products/…`).
bool _isStoredPhoto(String? url) =>
    url != null && url.startsWith('/images/products/');

/// Falló solo la subida de la foto: el producto ya quedó guardado.
class _PhotoFailure implements Exception {
  const _PhotoFailure(this.message);

  final String message;
}

/// La foto del producto: la vista previa y los botones para subirla (o
/// tomarla, en el teléfono) y quitarla.
class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.photo,
    required this.url,
    required this.name,
    required this.colorKey,
    required this.enabled,
    required this.canUseCamera,
    required this.onPick,
    required this.onRemove,
  });

  final PickedPhoto? photo;
  final String? url;
  final String name;
  final String? colorKey;
  final bool enabled;
  final bool canUseCamera;
  final ValueChanged<PhotoSource> onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picked = photo;
    final hasPhoto = picked != null || url != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: 96,
            child: picked != null
                ? Image.memory(
                    picked.bytes,
                    fit: BoxFit.cover,
                    semanticLabel: 'La foto elegida',
                  )
                : ProductPhoto(
                    url,
                    name: name.trim().isEmpty ? '?' : name,
                    colorKey: colorKey,
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Foto', style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                picked != null
                    ? 'Se sube al guardar.'
                    : 'JPEG, PNG o WebP. Se achica sola.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    onPressed: enabled
                        ? () => onPick(PhotoSource.gallery)
                        : null,
                    icon: const Icon(Icons.upload_outlined),
                    label: Text(hasPhoto ? 'Cambiar foto' : 'Subir foto'),
                  ),
                  if (canUseCamera)
                    OutlinedButton.icon(
                      onPressed: enabled
                          ? () => onPick(PhotoSource.camera)
                          : null,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Tomar foto'),
                    ),
                  if (hasPhoto)
                    TextButton(
                      onPressed: enabled ? onRemove : null,
                      child: const Text('Quitar foto'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String? _requiredText(String? value, String what, int maxLength) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Escribe $what.';
  if (text.length > maxLength) return 'Máximo $maxLength caracteres.';
  return null;
}

/// Como el servidor: hasta dos decimales, de 0 a S/ 99 999 999.99.
String? validatePrice(String? value) {
  if (value == null || value.trim().isEmpty) return 'Escribe el precio.';
  final cents = parseSolesInput(value);
  if (cents == null) return 'Escribe un monto como 24.90.';
  if (cents > 9999999999) return 'El precio es demasiado alto.';
  return null;
}

/// Opcional; si está, una URL http(s) completa.
String? validateImageUrl(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  final valid =
      uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
  if (!valid) return 'Escribe una dirección que empiece con https://';
  if (text.length > 2000) return 'Máximo 2000 caracteres.';
  return null;
}

/// Una cantidad entera de 0 en adelante.
class _CountField extends StatelessWidget {
  const _CountField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.helper,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(7),
      ],
      textInputAction: TextInputAction.next,
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Escribe una cantidad.' : null,
    );
  }
}

/// Un día opcional: se elige con el calendario y se puede quitar.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final day = value;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: enabled ? onPick : null,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          isEmpty: day == null,
          decoration: InputDecoration(
            labelText: label,
            enabled: enabled,
            suffixIcon: day == null
                ? const Icon(Icons.event_outlined)
                : IconButton(
                    tooltip: 'Quitar la fecha',
                    icon: const Icon(Icons.close),
                    onPressed: enabled ? onClear : null,
                  ),
          ),
          child: Text(day == null ? '' : formatStoreDay(context, day)),
        ),
      ),
    );
  }
}
