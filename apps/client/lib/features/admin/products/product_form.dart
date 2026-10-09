import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/products/product_input.dart';
import '../../../catalog/catalog_providers.dart';
import '../../../catalog/category.dart';
import '../../../catalog/product.dart';
import '../../../common/api_client.dart';
import '../../../common/money.dart';
import '../../shared/date_format.dart';
import '../../shared/error_message.dart';
import '../shared/admin_form.dart';
import '../shared/admin_page.dart';

/// Crear ([product] null) o editar un producto. Valida lo mismo que el
/// servidor; lo que el servidor rechaza igual (un SKU que ya existe) se
/// muestra en su campo. Se cierra con el producto como quedó.
class ProductForm extends ConsumerStatefulWidget {
  const ProductForm({
    super.key,
    this.product,
    required this.onSubmit,
    this.onDeactivate,
  });

  final Product? product;

  /// Crea o guarda con lo del formulario.
  final Future<Product> Function(ProductInput input) onSubmit;

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

  bool _busy = false;
  String? _error;

  /// El 409 del servidor: ya hay un producto con ese SKU.
  String? _skuError;

  bool get _creating => widget.product == null;

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
    _imageUrl = TextEditingController(text: product?.imageUrl);
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
      imageUrl: optional(_imageUrl),
      expirationDate: _expiration,
      initialStock: _creating ? int.parse(_initialStock.text) : 0,
    );
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _skuError = null);
    if (!_formKey.currentState!.validate()) return;
    await _run(
      () => widget.onSubmit(_input()),
      fallback: 'No se pudo guardar el producto.',
    );
  }

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
            enabled: !_busy,
            decoration: const InputDecoration(labelText: 'Nombre'),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            validator: (value) => _requiredText(value, 'el nombre', 150),
          ),
          const SizedBox(height: 16),
          FieldPair(
            TextFormField(
              controller: _sku,
              enabled: !_busy,
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
              enabled: !_busy,
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
              onChanged: _busy
                  ? null
                  : (id) => setState(() => _categoryId = id),
              validator: (id) => id == null ? 'Elige una categoría.' : null,
            ),
            _DateField(
              label: 'Vencimiento (opcional)',
              value: _expiration,
              enabled: !_busy,
              onPick: _pickExpiration,
              onClear: () => setState(() => _expiration = null),
            ),
          ),
          const SizedBox(height: 16),
          FieldPair(
            product == null
                ? _CountField(
                    controller: _initialStock,
                    enabled: !_busy,
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
              enabled: !_busy,
              label: 'Stock mínimo',
              helper: 'Con esto o menos, es stock bajo.',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _imageUrl,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'URL de la imagen (opcional)',
              hintText: 'https://…',
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            validator: validateImageUrl,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            enabled: !_busy,
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
            onChanged: _busy ? null : (on) => setState(() => _active = on),
          ),
          const SizedBox(height: 16),
          if (_error case final error?) ...[
            FormError(error),
            const SizedBox(height: 16),
          ],
          FormActions(
            submitLabel: _creating ? 'Crear producto' : 'Guardar cambios',
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
