import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../admin/promotions/promotion.dart';
import '../../../admin/vip/vip_customer.dart';
import '../../../admin/vip/vip_providers.dart';
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
/// rechaza igual (otra promoción del producto para la misma audiencia en esas
/// fechas: 409) se muestra. El producto solo se elige al crear; el título es
/// opcional y la audiencia, "Todos", "Solo clientes VIP" o "Clientes
/// elegidos" (los VIP que se buscan con [searchVips]). Se cierra con el
/// aviso para la persona ("Creaste…", "Eliminaste…").
class PromotionForm extends StatefulWidget {
  const PromotionForm({
    super.key,
    this.promotion,
    required this.onSubmit,
    required this.searchVips,
    this.onDelete,
  });

  final Promotion? promotion;
  final VipSearch searchVips;
  final Future<Promotion> Function(PromotionInput input) onSubmit;

  /// Solo al editar.
  final Future<void> Function()? onDelete;

  @override
  State<PromotionForm> createState() => _PromotionFormState();
}

class _PromotionFormState extends State<PromotionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _price;
  late final TextEditingController _title;
  Product? _product;
  DateTimeRange? _range;
  late bool _active;
  late PromotionAudience _audience;
  late List<PromotionRecipient> _recipients;
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
    _audience = promotion?.audience ?? PromotionAudience.everyone;
    _recipients = promotion?.recipients ?? const [];
    _title = TextEditingController(text: promotion?.title);
  }

  @override
  void dispose() {
    _price.dispose();
    _title.dispose();
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
          audience: _audience,
          title: _title.text.trim().isEmpty ? null : _title.text.trim(),
          recipients: _recipients,
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
            controller: _title,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: 'Título de la oferta (opcional)',
              hintText: 'Semana del arroz',
            ),
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(100)],
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
          const SizedBox(height: 16),
          _AudienceField(
            value: _audience,
            enabled: !_busy,
            onChanged: (audience) => setState(() => _audience = audience),
          ),
          if (_audience == PromotionAudience.selected) ...[
            const SizedBox(height: 16),
            _RecipientsField(
              initialValue: _recipients,
              search: widget.searchVips,
              enabled: !_busy,
              onChanged: (recipients) => _recipients = recipients,
            ),
          ],
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

/// "¿Quién la ve?": Todos, Solo clientes VIP o Clientes elegidos, con lo que
/// significa debajo. En un teléfono, uno debajo del otro.
class _AudienceField extends StatelessWidget {
  const _AudienceField({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final PromotionAudience value;
  final bool enabled;
  final ValueChanged<PromotionAudience> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('¿Quién la ve?', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => SegmentedButton<PromotionAudience>(
            direction: constraints.maxWidth < 520
                ? Axis.vertical
                : Axis.horizontal,
            segments: [
              for (final audience in PromotionAudience.values)
                ButtonSegment(
                  value: audience,
                  label: Text(audience.label),
                  icon: Icon(switch (audience) {
                    PromotionAudience.everyone => Icons.groups_outlined,
                    PromotionAudience.vip => Icons.workspace_premium_outlined,
                    PromotionAudience.selected => Icons.how_to_reg_outlined,
                  }),
                ),
            ],
            selected: {value},
            showSelectedIcon: false,
            onSelectionChanged: enabled
                ? (selected) => onChanged(selected.single)
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(switch (value) {
          PromotionAudience.everyone =>
            'La ven todos, también quien no tiene cuenta.',
          PromotionAudience.vip =>
            'Solo la ven los clientes VIP que ingresan con su correo '
                'verificado. Puede cruzarse con una promoción para todos del '
                'mismo producto: cada cliente paga la más barata.',
          PromotionAudience.selected =>
            'Solo la ven los clientes VIP que elijas, cuando ingresan con su '
                'correo verificado. Si alguno deja de ser VIP, deja de verla.',
        }, style: muted),
      ],
    );
  }
}

/// Los clientes VIP elegidos de una promoción: el buscador por correo (con
/// lo que encuentra [search]) y cada elegido en un chip con su "x". Hace
/// falta al menos uno.
class _RecipientsField extends StatefulWidget {
  const _RecipientsField({
    required this.initialValue,
    required this.search,
    required this.enabled,
    required this.onChanged,
  });

  final List<PromotionRecipient> initialValue;
  final VipSearch search;
  final bool enabled;
  final ValueChanged<List<PromotionRecipient>> onChanged;

  static const required = 'Elige al menos un cliente VIP.';

  @override
  State<_RecipientsField> createState() => _RecipientsFieldState();
}

class _RecipientsFieldState extends State<_RecipientsField> {
  /// El texto del buscador, para borrarlo al elegir.
  TextEditingController? _query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FormField<List<PromotionRecipient>>(
      initialValue: widget.initialValue,
      // El valor del campo, que cambia al elegir o quitar (antes de que el
      // formulario se reconstruya).
      validator: (chosen) =>
          (chosen ?? const []).isEmpty ? _RecipientsField.required : null,
      builder: (field) {
        final chosen = field.value ?? const <PromotionRecipient>[];
        void change(List<PromotionRecipient> next) {
          field.didChange(next);
          widget.onChanged(next);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Autocomplete<VipCustomer>(
              optionsBuilder: (value) async {
                final text = value.text.trim();
                if (text.isEmpty) return const [];
                final found = await widget.search(text);
                return [
                  for (final vip in found)
                    if (!chosen.any((r) => r.id == vip.id)) vip,
                ];
              },
              displayStringForOption: (vip) => vip.email,
              onSelected: (vip) {
                change([...chosen, (id: vip.id, email: vip.email)]);
                _query?.clear();
              },
              fieldViewBuilder: (context, controller, focusNode, _) {
                _query = controller;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: widget.enabled,
                  decoration: InputDecoration(
                    labelText: 'Buscar cliente VIP',
                    hintText: 'Su correo',
                    prefixIcon: const Icon(Icons.search),
                    helperText: chosen.isEmpty
                        ? 'Escribe parte del correo y elígelo.'
                        : 'Elegidos (${chosen.length})',
                    errorText: field.errorText,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                );
              },
            ),
            if (chosen.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final recipient in chosen)
                    InputChip(
                      label: Text(recipient.email),
                      labelStyle: theme.textTheme.bodyMedium,
                      onDeleted: widget.enabled
                          ? () => change([
                              for (final r in chosen)
                                if (r.id != recipient.id) r,
                            ])
                          : null,
                      deleteButtonTooltipMessage: 'Quitar a ${recipient.email}',
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
