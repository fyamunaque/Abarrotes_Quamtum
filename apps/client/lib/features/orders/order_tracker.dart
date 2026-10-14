import 'package:flutter/material.dart';

import '../../orders/fulfillment.dart';
import '../../orders/order_status.dart';
import '../../theme/brand_colors.dart';
import '../../theme/motion.dart';

/// El color de cada estado (ver [OrderStatusColors]).
Color orderStatusColor(OrderStatus status) => switch (status) {
  OrderStatus.pendingConfirmation => OrderStatusColors.pending,
  OrderStatus.confirmed => OrderStatusColors.confirmed,
  OrderStatus.preparing => OrderStatusColors.preparing,
  OrderStatus.readyForPickup => OrderStatusColors.readyForPickup,
  OrderStatus.outForDelivery => OrderStatusColors.onTheWay,
  OrderStatus.delivered => OrderStatusColors.delivered,
  OrderStatus.cancelled => OrderStatusColors.cancelled,
};

/// Seguimiento de un pedido: los pasos de su tipo de entrega, de pendiente a
/// entregado (o recogido), unidos por una línea que se llena hasta el estado
/// actual, en el color de ese estado.
///
/// Al mostrarse no se anima. Cuando [status] cambia, la línea se llena (o se
/// vacía) hasta el estado nuevo en [NeilsMotion.progress], y el color pasa al
/// del estado nuevo. Un pedido cancelado muestra los pasos apagados y el
/// aviso: el servidor no guarda en qué paso se canceló.
class OrderTracker extends StatefulWidget {
  const OrderTracker({
    super.key,
    required this.status,
    this.fulfillmentType = FulfillmentType.delivery,
  });

  final OrderStatus status;
  final FulfillmentType fulfillmentType;

  @override
  State<OrderTracker> createState() => _OrderTrackerState();
}

class _OrderTrackerState extends State<OrderTracker>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: NeilsMotion.progress,
    value: 1,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );
  late var _reach = Tween<double>(
    begin: _reachOf(widget.status),
    end: _reachOf(widget.status),
  );

  List<OrderStatus> get _steps => widget.fulfillmentType.steps;
  late var _color = ColorTween(
    begin: orderStatusColor(widget.status),
    end: orderStatusColor(widget.status),
  );

  /// Hasta qué paso llega la línea (0 = el primero). Cancelado no avanza.
  double _reachOf(OrderStatus status) =>
      _steps.indexOf(status).clamp(0, _steps.length).toDouble();

  @override
  void didUpdateWidget(OrderTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status == widget.status &&
        oldWidget.fulfillmentType == widget.fulfillmentType) {
      return;
    }
    // Parte de donde está ahora, aunque la animación anterior no terminara.
    _reach = Tween(
      begin: _reach.evaluate(_curve),
      end: _reachOf(widget.status),
    );
    _color = ColorTween(
      begin: _color.evaluate(_curve),
      end: orderStatusColor(widget.status),
    );
    if (NeilsMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (NeilsMotion.reduced(context)) _controller.value = 1;
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final type = widget.fulfillmentType;
    final cancelled = status == OrderStatus.cancelled;
    final steps = _steps;
    final semantics = cancelled
        ? 'Estado del pedido: ${type.labelOf(status)}'
        : 'Estado del pedido: ${type.labelOf(status)}, '
              'paso ${steps.indexOf(status) + 1} de ${steps.length}';

    return Semantics(
      container: true,
      label: semantics,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _curve,
          builder: (context, _) {
            final reach = _reach.evaluate(_curve);
            final color = _color.evaluate(_curve)!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, step) in steps.indexed)
                      Expanded(
                        child: _Step(
                          label: type.stepLabelOf(step),
                          index: i,
                          count: steps.length,
                          reach: reach,
                          color: color,
                          cancelled: cancelled,
                          finished: status == OrderStatus.delivered,
                          current: step == status,
                        ),
                      ),
                  ],
                ),
                if (cancelled) ...[
                  const SizedBox(height: 12),
                  const _CancelledNotice(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Un paso: el punto con la mitad de línea a cada lado, y su nombre debajo.
/// La línea entre dos pasos se arma con la mitad derecha de uno y la
/// izquierda del siguiente, así el nombre queda centrado bajo su punto.
class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.index,
    required this.count,
    required this.reach,
    required this.color,
    required this.cancelled,
    required this.finished,
    required this.current,
  });

  final String label;
  final int index;
  final int count;

  /// Hasta dónde llega la línea, en pasos (puede ir a mitad de un tramo).
  final double reach;
  final Color color;
  final bool cancelled;
  final bool finished;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Un punto se enciende cuando la línea llega a él.
    final reached = !cancelled && reach >= index - 0.001;
    // Cuánto de cada mitad está lleno.
    final before = (2 * (reach - index) + 1).clamp(0.0, 1.0);
    final after = (2 * (reach - index)).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              Expanded(
                child: index == 0
                    ? const SizedBox()
                    : _Line(fill: before, color: color),
              ),
              _Dot(
                reached: reached,
                done: reached && (!current || finished),
                color: color,
              ),
              Expanded(
                child: index == count - 1
                    ? const SizedBox()
                    : _Line(fill: after, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: theme.textTheme.labelMedium?.copyWith(
              color: reached
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: reached ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Media línea: el riel apagado y, encima, la parte llena desde la izquierda.
class _Line extends StatelessWidget {
  const _Line({required this.fill, required this.color});

  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      color: Theme.of(context).colorScheme.outlineVariant,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fill,
        heightFactor: 1,
        child: ColoredBox(color: color),
      ),
    );
  }
}

/// El punto de un paso: vacío si la línea no llegó; lleno con un check si ya
/// pasó (o si es la entrega); lleno con un centro claro si es el actual.
class _Dot extends StatelessWidget {
  const _Dot({required this.reached, required this.done, required this.color});

  final bool reached;
  final bool done;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reached ? color : scheme.surface,
        border: reached ? null : Border.all(color: scheme.outline, width: 2),
      ),
      child: !reached
          ? null
          : done
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }
}

class _CancelledNotice extends StatelessWidget {
  const _CancelledNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.cancel, size: 18, color: OrderStatusColors.cancelled),
        const SizedBox(width: 6),
        Text(
          'Pedido cancelado',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: OrderStatusColors.cancelled,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
