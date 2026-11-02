import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../admin/promotions/promotion.dart';
import '../../../catalog/product.dart';
import '../../../common/money.dart';
import '../shared/product_picker.dart';

/// Lo que se escribe en los campos de cada tipo de promoción.
class PromotionTypeControllers {
  PromotionTypeControllers([Promotion? promotion])
    : price = TextEditingController(
        text: switch (promotion?.promoPriceCents) {
          final cents? => formatSolesInput(cents),
          null => null,
        },
      ),
      percent = TextEditingController(text: promotion?.percent?.toString()),
      buy = TextEditingController(text: promotion?.buyQuantity?.toString()),
      pay = TextEditingController(text: promotion?.payQuantity?.toString()),
      giftQuantity = TextEditingController(
        text: promotion?.giftQuantity?.toString(),
      );

  final TextEditingController price;
  final TextEditingController percent;
  final TextEditingController buy;
  final TextEditingController pay;
  final TextEditingController giftQuantity;

  Listenable get all =>
      Listenable.merge([price, percent, buy, pay, giftQuantity]);

  int? get priceCents => parseSolesInput(price.text);
  int? get percentValue => int.tryParse(percent.text.trim());
  int? get buyValue => int.tryParse(buy.text.trim());
  int? get payValue => int.tryParse(pay.text.trim());
  int? get giftQuantityValue => int.tryParse(giftQuantity.text.trim());

  void dispose() {
    price.dispose();
    percent.dispose();
    buy.dispose();
    pay.dispose();
    giftQuantity.dispose();
  }
}

/// Los campos de [type], cada uno con su validación (como la del servidor) y
/// un resumen de lo que da ("Lleva 3, paga 2: una de cada 3 gratis").
class PromotionTypeFields extends StatelessWidget {
  const PromotionTypeFields({
    super.key,
    required this.type,
    required this.controllers,
    required this.normalCents,
    required this.productId,
    required this.gift,
    required this.onGiftChanged,
    required this.enabled,
    this.fixedGiftName,
  });

  final PromotionType type;
  final PromotionTypeControllers controllers;

  /// El precio normal del producto, o null si todavía no se eligió.
  final int? normalCents;

  /// El producto de la promoción (el regalo tiene que ser otro).
  final String? productId;

  /// El producto de regalo elegido.
  final Product? gift;
  final ValueChanged<Product?> onGiftChanged;
  final bool enabled;

  /// Al editar un regalo: el producto no cambia.
  final String? fixedGiftName;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controllers.all,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: switch (type) {
          PromotionType.specialPrice => [
            _number(
              controllers.price,
              'Precio de la promoción',
              prefix: 'S/ ',
              decimal: true,
              helper: _priceHelper,
              validator: _validatePrice,
            ),
          ],
          PromotionType.percentOff => [
            _number(
              controllers.percent,
              '% menos',
              helper: _percentHelper,
              validator: (value) => _range(value, 1, 90),
            ),
          ],
          PromotionType.buyXPayY => [
            _row([
              _number(
                controllers.buy,
                'Lleva',
                validator: (value) => _range(value, 2, 10),
              ),
              _number(controllers.pay, 'Paga', validator: _validatePay),
            ]),
            _summary(switch ((controllers.buyValue, controllers.payValue)) {
              (final buy?, final pay?) when pay < buy =>
                'Lleva $buy, paga $pay: '
                    '${buy - pay == 1 ? 'una' : '${buy - pay}'} de cada $buy '
                    'gratis',
              _ => null,
            }),
          ],
          PromotionType.extraUnit => [
            _row([
              _number(
                controllers.buy,
                'Cada',
                suffix: '.ª unidad',
                validator: (value) => _range(value, 2, 10),
              ),
              _number(
                controllers.percent,
                '% menos',
                validator: (value) => _range(value, 1, 100),
              ),
            ]),
            _summary(switch ((controllers.buyValue, controllers.percentValue)) {
              (final every?, final percent?) =>
                'La $every.ª unidad al $percent %',
              _ => null,
            }),
          ],
          PromotionType.gift => [
            _row([
              _number(
                controllers.buy,
                'Cada',
                suffix: 'unidades',
                validator: (value) => _range(value, 1, 10),
              ),
              _number(
                controllers.giftQuantity,
                'Cuántos de regalo',
                validator: (value) => _range(value, 1, 10),
              ),
            ]),
            const SizedBox(height: 16),
            if (fixedGiftName case final name?)
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Producto de regalo',
                  enabled: false,
                ),
                child: Text(name),
              )
            else
              ProductPicker(
                selected: gift,
                enabled: enabled,
                label: 'Producto de regalo',
                onChanged: onGiftChanged,
                validator: (selected) => switch (selected) {
                  null => 'Elige el producto de regalo.',
                  final product when product.id == productId =>
                    'Tiene que ser otro producto.',
                  _ => null,
                },
              ),
            _summary(switch ((
              controllers.buyValue,
              controllers.giftQuantityValue,
            )) {
              (final every?, final quantity?) =>
                'Cada $every lleva $quantity de regalo',
              _ => null,
            }),
          ],
        },
      ),
    );
  }

  Widget _number(
    TextEditingController controller,
    String label, {
    String? prefix,
    String? suffix,
    bool decimal = false,
    String? helper,
    required FormFieldValidator<String> validator,
  }) => TextFormField(
    controller: controller,
    enabled: enabled,
    decoration: InputDecoration(
      labelText: label,
      prefixText: prefix,
      suffixText: suffix,
      helperText: helper,
      helperMaxLines: 2,
    ),
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    inputFormatters: decimal ? null : [FilteringTextInputFormatter.digitsOnly],
    validator: validator,
  );

  Widget _row(List<Widget> fields) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: fields[0]),
      const SizedBox(width: 12),
      Expanded(child: fields[1]),
    ],
  );

  Widget _summary(String? text) => Builder(
    builder: (context) {
      if (text == null) return const SizedBox.shrink();
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    },
  );

  /// Un entero entre [min] y [max] (el valor del propio campo).
  static String? _range(String? value, int min, int max) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null) return 'Escribe un número.';
    if (number < min || number > max) return 'Entre $min y $max.';
    return null;
  }

  String? _validatePay(String? value) {
    final pay = int.tryParse(value?.trim() ?? '');
    if (pay == null) return 'Escribe un número.';
    if (pay < 1) return 'Tiene que ser 1 o más.';
    if (controllers.buyValue case final buy? when pay >= buy) {
      return 'Tiene que ser menor que lo que lleva.';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Escribe el precio de la promoción.';
    }
    final cents = parseSolesInput(value);
    if (cents == null) return 'Escribe un monto como 19.90.';
    if (cents < 1) return 'Tiene que ser mayor que 0.';
    if (normalCents case final normal? when cents >= normal) {
      return 'Tiene que ser menor que el precio normal '
          '(${formatSoles(normal)}).';
    }
    return null;
  }

  /// "Precio normal S/ 24.90 · 20 % menos" con lo que hay escrito.
  String? get _priceHelper {
    final normal = normalCents;
    if (normal == null) return null;
    final cents = controllers.priceCents;
    final discount = cents == null || cents < 1 || cents >= normal
        ? null
        : ((normal - cents) * 100 / normal).round();
    return 'Precio normal ${formatSoles(normal)}'
        '${discount == null ? '' : ' · $discount % menos'}';
  }

  /// "Precio normal S/ 24.90 · queda en S/ 19.92".
  String? get _percentHelper {
    final normal = normalCents;
    final percent = controllers.percentValue;
    if (normal == null) return null;
    if (percent == null || percent < 1 || percent > 90) {
      return 'Precio normal ${formatSoles(normal)}';
    }
    return 'Precio normal ${formatSoles(normal)} · queda en '
        '${formatSoles((normal * (100 - percent) / 100).round())}';
  }
}
