import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/emails.dart';
import '../../../admin/promo_codes/promo_code.dart';
import '../../../admin/promo_codes/promo_codes_providers.dart';
import '../../../admin/promotions/promotion.dart';
import '../../../admin/vip/vip_providers.dart';
import '../../../common/days.dart';
import '../../../common/money.dart';
import '../../shared/date_format.dart';
import '../../shared/error_message.dart';
import '../shared/admin_form.dart';
import '../shared/admin_page.dart';
import 'promotion_form.dart';

/// Crear ([code] null) o editar un código. Valida como el servidor: el
/// texto (en mayúsculas al escribir), la vigencia, los límites (vacío: sin
/// límite) y las condiciones. Al crearlo empieza apagado; al editarlo se
/// enciende, y lista sus promociones con "Agregar promoción" (el formulario
/// de promociones con la audiencia fija en el código). Si alguien ya lo
/// activó, el texto no cambia.
class PromoCodeForm extends ConsumerStatefulWidget {
  const PromoCodeForm({
    super.key,
    this.code,
    required this.onSubmit,
    this.onDelete,
  });

  final PromoCode? code;
  final Future<PromoCode> Function(PromoCodeInput input) onSubmit;

  /// Solo al editar.
  final Future<void> Function()? onDelete;

  @override
  ConsumerState<PromoCodeForm> createState() => _PromoCodeFormState();
}

class _PromoCodeFormState extends ConsumerState<PromoCodeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _benefitDays;
  late final TextEditingController _maxRedemptions;
  late final TextEditingController _usesPerCustomer;
  late final TextEditingController _minPurchase;
  DateTimeRange? _range;
  late bool _active;
  late bool _withMinimum;
  late bool _newCustomersOnly;
  late PromoCodeEligibility _eligibility;
  late List<String> _emails;
  bool _busy = false;
  String? _error;

  bool get _creating => widget.code == null;

  @override
  void initState() {
    super.initState();
    final code = widget.code;
    _code = TextEditingController(text: code?.code);
    _benefitDays = TextEditingController(text: code?.benefitDays?.toString());
    _maxRedemptions = TextEditingController(
      text: code?.maxRedemptions?.toString(),
    );
    _usesPerCustomer = TextEditingController(
      text: code?.usesPerCustomer?.toString(),
    );
    _minPurchase = TextEditingController(
      text: switch (code?.minPurchaseCents) {
        final cents? => formatSolesInput(cents),
        null => null,
      },
    );
    if (code != null) {
      _range = DateTimeRange(
        start: parseDay(code.startDate),
        end: parseDay(code.endDate),
      );
    }
    _active = code?.active ?? false;
    _withMinimum = code?.minPurchaseCents != null;
    _newCustomersOnly = code?.newCustomersOnly ?? false;
    _eligibility = code?.eligibility ?? PromoCodeEligibility.everyone;
    _emails = [...?code?.allowedEmails];
  }

  @override
  void dispose() {
    _code.dispose();
    _benefitDays.dispose();
    _maxRedemptions.dispose();
    _usesPerCustomer.dispose();
    _minPurchase.dispose();
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

  /// Un número opcional entre 1 y [max] (vacío: sin límite).
  static String? _limit(String? value, int max) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final number = int.tryParse(text);
    if (number == null) return 'Escribe un número.';
    if (number < 1) return 'Tiene que ser 1 o más.';
    if (number > max) return 'Como mucho $max.';
    return null;
  }

  static int? _number(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final range = _range!;
    final input = PromoCodeInput(
      code: _code.text,
      startDate: formatDay(range.start),
      endDate: formatDay(range.end),
      // Sin promociones todavía, se crea apagado.
      active: _creating ? false : _active,
      benefitDays: _number(_benefitDays),
      maxRedemptions: _number(_maxRedemptions),
      usesPerCustomer: _number(_usesPerCustomer),
      minPurchaseCents: _withMinimum
          ? parseSolesInput(_minPurchase.text)
          : null,
      newCustomersOnly: _newCustomersOnly,
      eligibility: _eligibility,
      allowedEmails: _emails,
    );
    await _run(() async {
      final saved = await widget.onSubmit(input);
      return _creating
          ? 'Creaste el código ${saved.code}. Ahora agrégale promociones.'
          : 'Guardaste el código ${saved.code}.';
    }, fallback: 'No se pudo guardar el código.');
  }

  Future<void> _delete() async {
    final code = widget.code!.code;
    final confirmed = await confirmAction(
      context,
      title: '¿Eliminar el código $code?',
      message:
          'Se borra con sus promociones. Si alguien ya lo activó, no se puede: '
          'apágalo y guarda.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed) return;
    await _run(() async {
      await widget.onDelete!();
      return 'Eliminaste el código $code.';
    }, fallback: 'No se pudo eliminar el código.');
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
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final redeemed = (widget.code?.redemptions ?? 0) > 0;
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _code,
            enabled: !_busy && !redeemed,
            decoration: InputDecoration(
              labelText: 'Código',
              hintText: 'VERANO-10',
              helperText: redeemed
                  ? 'Ya lo activaron: el texto no cambia.'
                  : 'Letras, números o guiones. El cliente lo escribe como '
                        'quiera.',
              helperMaxLines: 2,
            ),
            inputFormatters: [
              const _PromoCodeFormatter(),
              LengthLimitingTextInputFormatter(20),
            ],
            validator: (value) =>
                RegExp(r'^[A-Z0-9-]{3,20}$').hasMatch(value ?? '')
                ? null
                : 'De 3 a 20 letras, números o guiones.',
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
                    helperText:
                        'Los días en que se puede activar, los dos incluidos.',
                    helperMaxLines: 2,
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
          _NumberField(
            controller: _benefitDays,
            label: 'Días de beneficio',
            helper:
                'Dura N días desde que cada cliente lo activa. Vacío: hasta '
                'el fin de la vigencia.',
            enabled: !_busy,
            validator: (value) => _limit(value, 365),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final limits = [
                _NumberField(
                  controller: _maxRedemptions,
                  label: 'Límite de clientes',
                  helper: 'Cuántos pueden activarlo. Vacío: sin límite.',
                  enabled: !_busy,
                  validator: (value) => _limit(value, 1000000),
                ),
                _NumberField(
                  controller: _usesPerCustomer,
                  label: 'Usos por cliente',
                  helper: 'En cuántos pedidos. Vacío: sin límite.',
                  enabled: !_busy,
                  validator: (value) => _limit(value, 1000),
                ),
              ];
              if (constraints.maxWidth < 440) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [limits[0], const SizedBox(height: 16), limits[1]],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: limits[0]),
                  const SizedBox(width: 12),
                  Expanded(child: limits[1]),
                ],
              );
            },
          ),
          if (!_creating) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Encendido'),
              subtitle: Text(
                _active
                    ? 'Se puede activar en sus fechas.'
                    : 'Apagado: no se activa y sus promociones no valen.',
              ),
              value: _active,
              onChanged: _busy ? null : (on) => setState(() => _active = on),
            ),
          ],
          const SizedBox(height: 16),
          Text('Condiciones', style: theme.textTheme.titleSmall),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Compra mínima'),
            subtitle: const Text('Sus promociones valen desde ese total.'),
            value: _withMinimum,
            onChanged: _busy
                ? null
                : (on) => setState(() => _withMinimum = on ?? false),
          ),
          if (_withMinimum)
            TextFormField(
              controller: _minPurchase,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Monto mínimo',
                prefixText: 'S/ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) => switch (parseSolesInput(value ?? '')) {
                null => 'Escribe un monto como 30.00.',
                final cents when cents < 1 => 'Tiene que ser mayor que 0.',
                _ => null,
              },
            ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Solo clientes nuevos'),
            subtitle: const Text('Quien todavía no hizo ningún pedido.'),
            value: _newCustomersOnly,
            onChanged: _busy
                ? null
                : (on) => setState(() => _newCustomersOnly = on ?? false),
          ),
          const SizedBox(height: 8),
          Text('¿Quién puede activarlo?', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) =>
                SegmentedButton<PromoCodeEligibility>(
                  direction: constraints.maxWidth < 440
                      ? Axis.vertical
                      : Axis.horizontal,
                  segments: [
                    for (final eligibility in PromoCodeEligibility.values)
                      ButtonSegment(
                        value: eligibility,
                        label: Text(eligibility.label),
                      ),
                  ],
                  selected: {_eligibility},
                  showSelectedIcon: false,
                  onSelectionChanged: _busy
                      ? null
                      : (selected) =>
                            setState(() => _eligibility = selected.single),
                ),
          ),
          if (_eligibility == PromoCodeEligibility.listed) ...[
            const SizedBox(height: 16),
            _EmailsField(
              initialValue: _emails,
              enabled: !_busy,
              onChanged: (emails) => _emails = emails,
            ),
          ],
          const SizedBox(height: 24),
          Text('Promociones que da', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (widget.code case final code?)
            _CodePromotions(codeId: code.id, enabled: !_busy)
          else
            Text(
              'Crea el código y después agrégale sus promociones.',
              style: muted,
            ),
          const SizedBox(height: 16),
          if (_error case final error?) ...[
            FormError(error),
            const SizedBox(height: 16),
          ],
          FormActions(
            submitLabel: _creating ? 'Crear código' : 'Guardar cambios',
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

/// Las promociones del código (al día con [promoCodeProvider]), cada una
/// para editarla, y "Agregar promoción".
class _CodePromotions extends ConsumerWidget {
  const _CodePromotions({required this.codeId, required this.enabled});

  final String codeId;
  final bool enabled;

  Future<void> _open(
    BuildContext context,
    WidgetRef ref, {
    Promotion? promotion,
  }) async {
    final notifier = ref.read(promoCodeProvider(codeId).notifier);
    final message = await showAdminForm<String>(
      context,
      title: promotion == null
          ? 'Nueva promoción del código'
          : 'Editar promoción',
      builder: (_) => PromotionForm(
        promotion: promotion,
        promoCodeId: codeId,
        searchVips: ref.read(vipSearchProvider),
        onSubmit: (input, {required confirmOverlap}) => promotion == null
            ? notifier.addPromotion(input, confirmOverlap: confirmOverlap)
            : notifier.savePromotion(
                promotion.id,
                input,
                confirmOverlap: confirmOverlap,
              ),
        onDelete: promotion == null
            ? null
            : () => notifier.deletePromotion(promotion.id),
      ),
    );
    if (message == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final value = ref.watch(promoCodeProvider(codeId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (value) {
          AsyncData(:final value) when value.promotions.isEmpty => Text(
            'Todavía no da ninguna promoción.',
            style: muted,
          ),
          AsyncData(:final value) => Column(
            children: [
              for (final promotion in value.promotions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.local_offer_outlined),
                  title: Text('${promotion.label} en ${promotion.productName}'),
                  subtitle: Text(
                    '${promotion.status.label} · ${formatStoreRange(context, parseDay(promotion.startDate), parseDay(promotion.endDate))}',
                  ),
                  onTap: enabled
                      ? () => _open(context, ref, promotion: promotion)
                      : null,
                ),
            ],
          ),
          AsyncError(:final error) => Text(
            errorMessage(error, 'No se pudieron cargar sus promociones.'),
            style: muted,
          ),
          _ => const LinearProgressIndicator(),
        },
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: enabled && value.hasValue
                ? () => _open(context, ref)
                : null,
            icon: const Icon(Icons.add),
            label: const Text('Agregar promoción'),
          ),
        ),
      ],
    );
  }
}

/// Un número opcional (vacío: sin límite), con su ayuda debajo.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.helper,
    required this.enabled,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String helper;
  final bool enabled;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 3,
    ),
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    validator: validator,
  );
}

/// Los correos que pueden activar el código: se escriben o se pegan (varios,
/// separados por coma o en líneas) y cada uno queda en un chip con su "x".
/// Hace falta al menos uno.
class _EmailsField extends StatefulWidget {
  const _EmailsField({
    required this.initialValue,
    required this.enabled,
    required this.onChanged,
  });

  final List<String> initialValue;
  final bool enabled;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_EmailsField> createState() => _EmailsFieldState();
}

class _EmailsFieldState extends State<_EmailsField> {
  final _text = TextEditingController();

  /// Lo que se escribió y no es un correo.
  String? _invalid;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Pasa a chips lo escrito ([all]: también lo que sigue sin separador).
  void _take(FormFieldState<List<String>> field, {required bool all}) {
    final text = _text.text;
    final parts = splitEmails(text);
    final complete = all || RegExp(r'[,;\n\r]\s*$').hasMatch(text)
        ? parts
        : parts.take(parts.length - 1).toList();
    if (complete.isEmpty) return;
    final chosen = [...?field.value];
    final invalid = <String>[];
    for (final raw in complete) {
      final email = normalizeEmail(raw);
      if (!isValidEmail(email)) {
        invalid.add(raw);
      } else if (!chosen.contains(email)) {
        chosen.add(email);
      }
    }
    final rest = all || complete.length == parts.length ? '' : parts.last;
    _text.text = [...invalid, if (rest.isNotEmpty) rest].join(', ');
    setState(() => _invalid = invalid.isEmpty ? null : invalid.join(', '));
    field.didChange(chosen);
    widget.onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      initialValue: widget.initialValue,
      validator: (emails) =>
          (emails ?? const []).isEmpty ? 'Escribe al menos un correo.' : null,
      builder: (field) {
        final chosen = field.value ?? const <String>[];
        void remove(String email) {
          final next = [...chosen]..remove(email);
          field.didChange(next);
          widget.onChanged(next);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _text,
              enabled: widget.enabled,
              decoration: InputDecoration(
                labelText: 'Correos',
                hintText: 'Escribe o pega correos',
                helperText: chosen.isEmpty
                    ? 'Separados por coma o uno por línea.'
                    : 'En la lista (${chosen.length})',
                errorText:
                    field.errorText ??
                    (_invalid == null ? null : 'No es un correo: $_invalid'),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onChanged: (_) => _take(field, all: false),
              onSubmitted: (_) => _take(field, all: true),
            ),
            if (chosen.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final email in chosen)
                    InputChip(
                      label: Text(email),
                      onDeleted: widget.enabled ? () => remove(email) : null,
                      deleteButtonTooltipMessage: 'Quitar $email',
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

/// El código como se guarda: en mayúsculas y sin espacios, mientras se
/// escribe.
class _PromoCodeFormatter extends TextInputFormatter {
  const _PromoCodeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase().replaceAll(RegExp(r'\s'), '');
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
