import 'package:flutter/material.dart';

import '../../common/money.dart';
import '../../orders/order.dart';
import '../../theme/palette.dart';

/// Las líneas de [order] con lo que se cobró: "2 × Arroz extra 5 kg" con el
/// total de la línea y, debajo, cada promoción con lo que ahorró ("2x1
/// −S/ 24.90"); un regalo dice "Regalo" en vez del precio. Abajo, si hubo
/// descuentos, el subtotal y los descuentos; y siempre el total. En Mis
/// pedidos y en el detalle del panel.
class OrderLines extends StatelessWidget {
  const OrderLines({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saving = theme.textTheme.bodySmall?.copyWith(
      color: context.palette.positive,
    );
    final discounted = order.discountCents > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in order.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Row(
                  '${line.quantity} × ${line.name}',
                  line.isGift ? 'Regalo' : formatSoles(line.lineTotalCents),
                  valueStyle: line.isGift ? saving : null,
                ),
                // El regalo ya dice qué es.
                if (!line.isGift)
                  for (final promotion in line.promotions)
                    Text(
                      '${promotion.label} −${formatSoles(promotion.savedCents)}',
                      style: saving,
                    ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        if (discounted) ...[
          _Row('Subtotal', formatSoles(order.subtotalCents)),
          const SizedBox(height: 2),
          _Row(
            'Descuentos',
            '−${formatSoles(order.discountCents)}',
            valueStyle: theme.textTheme.bodyMedium?.copyWith(
              color: context.palette.positive,
            ),
          ),
          const SizedBox(height: 4),
        ],
        _Row(
          'Total',
          formatSoles(order.totalCents),
          labelStyle: theme.textTheme.titleSmall,
          valueStyle: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}

/// Lo que se cobra a la izquierda y el monto a la derecha.
class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.labelStyle, this.valueStyle});

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(label, style: labelStyle)),
      const SizedBox(width: 12),
      Text(value, style: valueStyle),
    ],
  );
}
