import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../admin/promotions/promotion.dart';
import '../../../admin/vip/vip_customer.dart';
import '../../../admin/vip/vip_providers.dart';
import '../../../catalog/product.dart';
import '../../../common/days.dart';
import '../../shared/date_format.dart';
import '../../shared/error_message.dart';
import '../shared/admin_form.dart';
import '../shared/admin_page.dart';
import '../shared/product_picker.dart';
import 'overlap_dialog.dart';
import 'promotion_type_fields.dart';

/// Crear ([promotion] null) o editar una promoción. El producto y el tipo
/// (precio especial, %, NxM, unidad extra o regalo) solo se eligen al
/// crear, y cada tipo muestra sus campos, validados como en el servidor. Si
/// se cruza con otras promociones del producto, avisa con la lista (se
/// acumulan) y la guarda solo si la persona confirma. El título es opcional
/// y la audiencia, "Todos", "Solo clientes VIP" o "Clientes elegidos" (los
/// VIP que se buscan con [searchVips]). Se cierra con el aviso para la
/// persona ("Creaste…", "Eliminaste…").
class PromotionForm extends StatefulWidget {
  const PromotionForm({
    super.key,
    this.promotion,
    required this.onSubmit,
    required this.searchVips,
    this.onDelete,
    this.promoCodeId,
  });

  final Promotion? promotion;

  /// Una promoción de este código: la audiencia es el código y no se
  /// elige.
  final String? promoCodeId;
  final VipSearch searchVips;

  /// Con `confirmOverlap`, se guarda aunque se cruce con otras.
  final Future<Promotion> Function(
    PromotionInput input, {
    required bool confirmOverlap,
  })
  onSubmit;

  /// Solo al editar.
  final Future<void> Function()? onDelete;

  @override
  State<PromotionForm> createState() => _PromotionFormState();
}

class _PromotionFormState extends State<PromotionForm> {
  final _formKey = GlobalKey<FormState>();
  late final PromotionTypeControllers _fields;
  late final TextEditingController _title;
  Product? _product;
  late PromotionType _type;

  /// El producto de regalo, al crear un regalo.
  Product? _gift;
  DateTimeRange? _range;
  late bool _active;
  late PromotionAudience _audience;
  late List<PromotionRecipient> _recipients;
  bool _busy = false;
  String? _error;

  bool get _creating => widget.promotion == null;

  /// El código que la da, si es de un código.
  String? get _promoCodeId =>
      widget.promoCodeId ??
      (widget.promotion?.audience == PromotionAudience.code
          ? widget.promotion?.promoCodeId
          : null);

  /// El precio normal del producto, o null si todavía no se eligió.
  int? get _normalCents => widget.promotion?.priceCents ?? _product?.priceCents;

  @override
  void initState() {
    super.initState();
    final promotion = widget.promotion;
    _fields = PromotionTypeControllers(promotion);
    _type = promotion?.type ?? PromotionType.specialPrice;
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
    _fields.dispose();
    _title.dispose();
    super.dispose();
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
    // Cada tipo manda solo sus campos (`PromotionInput.toJson`).
    final input = PromotionInput(
      productId: _creating ? _product!.id : null,
      type: _type,
      promoPriceCents: _fields.priceCents,
      percent: _fields.percentValue,
      buyQuantity: _fields.buyValue,
      payQuantity: _fields.payValue,
      giftProductId: _gift?.id ?? widget.promotion?.giftProductId,
      giftQuantity: _fields.giftQuantityValue,
      startDate: formatDay(range.start),
      endDate: formatDay(range.end),
      active: _active,
      audience: _promoCodeId == null ? _audience : PromotionAudience.code,
      title: _title.text.trim().isEmpty ? null : _title.text.trim(),
      recipients: _recipients,
      promoCodeId: _promoCodeId,
    );
    String saved(Promotion promotion) => _creating
        ? 'Creaste la promoción de ${promotion.productName}.'
        : 'Guardaste la promoción de ${promotion.productName}.';
    const fallback = 'No se pudo guardar la promoción.';

    var overlaps = const <PromotionOverlapItem>[];
    await _run(() async {
      try {
        return saved(await widget.onSubmit(input, confirmOverlap: false));
      } on PromotionOverlap catch (overlap) {
        overlaps = overlap.overlaps;
        return null;
      }
    }, fallback: fallback);
    // Se pregunta con el formulario libre; "Volver" lo deja abierto, sin
    // error.
    if (overlaps.isEmpty || !mounted) return;
    final confirmed = await showOverlapDialog(
      context,
      overlaps,
      confirmLabel: _creating ? 'Crear igual' : 'Guardar igual',
    );
    if (!confirmed || !mounted) return;
    await _run(
      () async => saved(await widget.onSubmit(input, confirmOverlap: true)),
      fallback: fallback,
    );
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

  /// Corre [action] mostrando el progreso y cierra con su aviso (sin aviso,
  /// null, queda abierto). Si falla, el formulario queda abierto con el
  /// error.
  Future<void> _run(
    Future<String?> Function() action, {
    required String fallback,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await action();
      if (message != null && mounted) Navigator.of(context).pop(message);
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
          if (promotion == null)
            DropdownButtonFormField<PromotionType>(
              style: Theme.of(context).textTheme.bodyLarge,
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Tipo de promoción'),
              items: [
                for (final type in PromotionType.values)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: _busy
                  ? null
                  : (type) => setState(() => _type = type ?? _type),
            )
          else
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tipo de promoción',
                helperText: 'No cambia. Para otro tipo, crea otra.',
                enabled: false,
              ),
              child: Text(promotion.type.label),
            ),
          const SizedBox(height: 16),
          PromotionTypeFields(
            type: _type,
            controllers: _fields,
            normalCents: _normalCents,
            productId: promotion?.productId ?? _product?.id,
            gift: _gift,
            onGiftChanged: (product) => setState(() => _gift = product),
            enabled: !_busy,
            // Al editar, el regalo no cambia.
            fixedGiftName: promotion == null
                ? null
                : promotion.giftProductName ?? '',
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
          // La de un código la ve solo quien lo activa.
          if (_promoCodeId == null)
            _AudienceField(
              value: _audience,
              enabled: !_busy,
              onChanged: (audience) => setState(() => _audience = audience),
            ),
          if (_promoCodeId == null &&
              _audience == PromotionAudience.selected) ...[
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
            direction: constraints.maxWidth < 440
                ? Axis.vertical
                : Axis.horizontal,
            segments: [
              for (final audience in PromotionAudience.values)
                if (audience != PromotionAudience.code)
                  ButtonSegment(
                    value: audience,
                    label: Text(audience.label),
                    icon: Icon(switch (audience) {
                      PromotionAudience.everyone => Icons.groups_outlined,
                      PromotionAudience.vip => Icons.workspace_premium_outlined,
                      PromotionAudience.selected => Icons.how_to_reg_outlined,
                      PromotionAudience.code =>
                        Icons.confirmation_number_outlined,
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
          PromotionAudience.code => 'Solo quien activa el código.',
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
