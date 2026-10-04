import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../admin/stats/stats.dart';
import '../../../common/days.dart';
import '../../../common/money.dart';
import '../../../theme/motion.dart';

/// Las ventas de cada día como una línea: una sola serie, así que no lleva
/// leyenda (el título de la tarjeta dice qué es).
///
/// - Línea de 2 px en `primary`, el área de abajo al 10 %, y un punto al final
///   (hoy) con un anillo del color de la tarjeta.
/// - Cuadrícula horizontal en líneas finas y sólidas, con montos redondos.
/// - Al tocar o pasar el mouse, una línea vertical marca el día y el tooltip
///   muestra primero el monto y después los pedidos y el día.
///
/// Los lectores de pantalla oyen [semanticSummary]; los valores de cada día
/// están también en la vista de tabla de la tarjeta.
class SalesChart extends StatelessWidget {
  const SalesChart({
    super.key,
    required this.daily,
    required this.semanticSummary,
  });

  final List<DailySales> daily;
  final String semanticSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final axisStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final values = [for (final day in daily) day.totalCents / 100];
    final scale = niceScale(values.fold(0.0, math.max));
    final last = daily.length - 1;

    String dayLabel(int index) =>
        localizations.formatShortMonthDay(parseDay(daily[index].date));

    // container: un nodo propio; si no, la tarjeta lo junta con su título.
    return Semantics(
      container: true,
      label: semanticSummary,
      child: ExcludeSemantics(
        child: LineChart(
          duration: NeilsMotion.reduced(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          LineChartData(
            minX: 0,
            maxX: last.toDouble(),
            minY: 0,
            maxY: scale.max,
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (final (i, value) in values.indexed)
                    FlSpot(i.toDouble(), value),
                ],
                color: scheme.primary,
                barWidth: 2,
                isStrokeCapRound: true,
                isStrokeJoinRound: true,
                belowBarData: BarAreaData(
                  show: true,
                  color: scheme.primary.withValues(alpha: 0.10),
                ),
                dotData: FlDotData(
                  checkToShowDot: (spot, _) => spot.x == last,
                  getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                    radius: 4,
                    color: scheme.primary,
                    strokeWidth: 2,
                    strokeColor: scheme.surfaceContainerLowest,
                  ),
                ),
              ),
            ],
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: scale.step,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: scheme.outlineVariant, strokeWidth: 1),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(bottom: BorderSide(color: scheme.outline)),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  interval: scale.step,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text('S/ ${value.round()}', style: axisStyle),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  // Una fecha por semana, contando hacia atrás desde hoy.
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (i != value || (last - i) % 7 != 0) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      // La fecha de hoy va en el borde: sin esto se corta.
                      fitInside: SideTitleFitInsideData.fromTitleMeta(
                        meta,
                        distanceFromEdge: 0,
                      ),
                      child: Text(dayLabel(i), style: axisStyle),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              getTouchedSpotIndicator: (_, indexes) => [
                for (final _ in indexes)
                  TouchedSpotIndicatorData(
                    FlLine(
                      color: scheme.onSurface.withValues(alpha: 0.35),
                      strokeWidth: 1,
                    ),
                    FlDotData(
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 4,
                        color: scheme.primary,
                        strokeWidth: 2,
                        strokeColor: scheme.surfaceContainerLowest,
                      ),
                    ),
                  ),
              ],
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => scheme.inverseSurface,
                tooltipBorderRadius: BorderRadius.circular(8),
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (spots) => [
                  for (final spot in spots)
                    LineTooltipItem(
                      formatSoles(daily[spot.x.round()].totalCents),
                      theme.textTheme.titleSmall!.copyWith(
                        color: scheme.onInverseSurface,
                      ),
                      children: [
                        TextSpan(
                          text:
                              '\n${_orders(daily[spot.x.round()].orders)}, '
                              '${dayLabel(spot.x.round())}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onInverseSurface,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _orders(int count) =>
      count == 1 ? '1 pedido' : '$count pedidos';
}

/// El tope del eje Y y el paso entre líneas: números redondos (1, 2 o 5 por
/// una potencia de 10) y unas 4 líneas. Sin ventas, de 0 a 100.
({double max, double step}) niceScale(double maxValue) {
  if (maxValue <= 0) return (max: 100, step: 25);
  final rough = maxValue / 4;
  final magnitude = math.pow(10, (math.log(rough) / math.ln10).floor());
  final step =
      [1, 2, 5, 10].map((m) => m * magnitude).firstWhere((s) => s >= rough) *
      1.0;
  return (max: (maxValue / step).ceil() * step, step: step);
}
