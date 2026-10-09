import 'package:flutter/material.dart';

import '../../../admin/promotions/promotion.dart';
import '../../../catalog/product.dart';
import '../../../common/days.dart';
import '../../../common/money.dart';
import '../../shared/date_format.dart';
import '../../shared/error_message.dart';
import '../shared/admin_form.dart';
import '../shared/admin_page.dart';
import '../shared/product_picker.dart';

/// Crear ([promotion] null) o editar una promoción. Valida como el servidor:
/// el precio menor que el normal y las fechas en orden. Lo que el servidor
/// rechaza igual (otra promoción del producto en esas fechas: 409) se
/// muestra. El producto solo se elige al crear. Se cierra con el aviso para
/// la persona ("Creaste…", "Eliminaste…").
class PromotionForm extends StatefulWidget {
  const PromotionForm({
    super.key,
    this.promotion,
    required this.onSubmit,
    this.onDelete,
  });

  final Promotion? promotion;
  final Future<Promotion> Function(PromotionInput input) onSubmit;

  /// Solo al editar.
  final Future<void> Function()? onDelete;

  @override
  State<PromotionForm> createState() => _PromotionFormState();
}

class _PromotionFormState extends State<PromotionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _price;
  Product? _product;
  DateTimeRange? _range;
  late bool _active;
  bool _busy = false;
  String? _error;

  bool get _creating => widget.promotion == null;

  /// El precio normal del producto, o null si todavía no se eligió.
  int? get _normalCents => widget.promotion?.priceCents ?? _product?.priceCents;

  @override
  void initState() {
    super.initState();
    final promotion = widget.promotion;
    _price = TextEditingController(
      text: promotion == null
          ? null
          : formatSolesInput(promotion.promoPriceCents),
    );
    if (promotion != null) {
      _range = DateTimeRange(
        start: parseDay(promotion.startDate),
        end: parseDay(promotion.endDate),
      );
    }
    _active = promotion?.active ?? true;
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Escribe el precio de la promoción.';
    }
    final cents = parseSolesInput(value);
    if (cents == null) return 'Escribe un monto como 19.90.';
    if (cents < 1) return 'Tiene que ser mayor que 0.';
    if (_normalCents case final normal? when cents >= normal) {
      return 'Tiene que ser menor que el precio normal '
          '(${formatSoles(normal)}).';
    }
    return null;
  }

  /// "Precio normal S/ 24.90 · 20 % menos" con lo que hay escrito.
  String? get _priceHelper {
    final normal = _normalCents;
    if (normal == null) return null;
    final cents = parseSolesInput(_price.text);
    final discount = cents == null || cents < 1 || cents >= normal
        ? null
        : ((normal - cents) * 100 / normal).round();
    return 'Precio normal ${formatSoles(normal)}'
        '${discount == null ? '' : ' · $discount % menos'}';
  }

  Future<void> _pickRange(FormFieldState<DateTimeRange> field) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 2, 12, 31),
      helpText: 'Vigencia',
      saveText: 'Listo',
    );
    if (picked == null) return;
    setState(() => _range = picked);
    field.didChange(picked);
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final range = _range!;
    await _run(() async {
      final saved = await widget.onSubmit(
        PromotionInput(
          productId: _creating ? _product!.id : null,
          promoPriceCents: parseSolesInput(_price.text)!,
          startDate: formatDay(range.start),
          endDate: formatDay(range.end),
          active: _active,
        ),
      );
      return _creating
          ? 'Creaste la promoción de ${saved.productName}.'
          : 'Guardaste la promoción de ${saved.productName}.';
    }, fallback: 'No se pudo guardar la promoción.');
  }

  Future<void> _delete() async {
    final name = widget.promotion!.productName;
    final confirmed = await confirmAction(
      context,
      title: '¿Eliminar la promoción de $name?',
      message:
          'Se borra del todo. Si solo quieres que deje de regir, apágala '
          'y guarda.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed) return;
    await _run(() async {
      await widget.onDelete!();
      return 'Eliminaste la promoción de $name.';
    }, fallback: 'No se pudo eliminar la promoción.');
  }

  /// Corre [action] mostrando el progreso y cierra con su aviso. Si falla,
  /// el formulario queda abierto con el error.
  Future<void> _run(
    Future<String> Function() action, {
    required String fallback,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await action();
      if (mounted) Navigator.of(context).pop(message);
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error, fallback));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final promotion = widget.promotion;
    return Form(
      key: _formKey,
      // Un campo con error se vuelve a validar mientras se corrige.
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (promotion == null)
            ProductPicker(
              selected: _product,
              enabled: !_busy,
              onChanged: (product) => setState(() => _product = product),
            )
          else
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Producto',
                helperText: 'No cambia. Para otro producto, crea otra.',
                enabled: false,
              ),
              child: Text('${promotion.productName} · ${promotion.sku}'),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _price,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: 'Precio de la promoción',
              prefixText: 'S/ ',
              helperText: _priceHelper,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            validator: _validatePrice,
          ),
          const SizedBox(height: 16),
          FormField<DateTimeRange>(
            initialValue: _range,
            validator: (range) =>
                range == null ? 'Elige desde y hasta qué día.' : null,
            builder: (field) => Semantics(
              button: true,
              child: InkWell(
                onTap: _busy ? null : () => _pickRange(field),
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  isEmpty: _range == null,
                  decoration: InputDecoration(
                    labelText: 'Vigencia',
                    helperText: 'Días de la tienda, los dos incluidos.',
                    errorText: field.errorText,
                    enabled: !_busy,
                    suffixIcon: const Icon(Icons.date_range_outlined),
                  ),
                  child: Text(switch (_range) {
                    final range? => formatStoreRange(
                      context,
                      range.start,
                      range.end,
                    ),
                    null => '',
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Encendida'),
            subtitle: Text(
              _active
                  ? 'Rige en sus fechas.'
                  : 'Apagada: no rige aunque esté en fecha.',
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
            submitLabel: _creating ? 'Crear promoción' : 'Guardar cambios',
            onSubmit: _submit,
            busy: _busy,
            destructive: widget.onDelete == null
                ? null
                : DestructiveButton(
                    label: 'Eliminar',
                    onPressed: _busy ? null : _delete,
                  ),
          ),
        ],
      ),
    );
  }
}
