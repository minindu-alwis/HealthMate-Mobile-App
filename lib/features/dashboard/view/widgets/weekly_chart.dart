import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../records/model/health_record.dart';
import '../../viewmodel/dashboard_view_model.dart';

const double _chartHeight = 150;
const double _labelHeight = 16;

/// Label height plus the gap: where the bar area starts above the chart bottom.
const double _labelSpace = _labelHeight + 6;

/// 7-day bar chart drawn with plain widgets and one [CustomPaint] for the goal line.
/// The scale always includes the goal so the dashed line is visible.
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({
    super.key,
    required this.bars,
    required this.metric,
    required this.goal,
    required this.average,
    required this.onMetricChange,
  });

  final List<ChartBar> bars;
  final MetricKey metric;
  final int goal;
  final double average;
  final ValueChanged<MetricKey> onMetricChange;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = metricStyles[metric]!;
    final maxValue = [goal, ...bars.map((b) => b.value), 1].reduce(math.max).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Last 7 days', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text(
            'Average ${formatNumber(average)} ${style.unit} a day',
            style: text.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SegmentedButton<MetricKey>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primaryContainer,
              selectedForegroundColor: AppColors.onPrimaryContainer,
              side: const BorderSide(color: AppColors.outline),
              visualDensity: VisualDensity.compact,
            ),
            segments: [
              for (final key in MetricKey.values)
                ButtonSegment(
                  value: key,
                  icon: Icon(metricStyles[key]!.icon, size: 18),
                  label: Text(metricStyles[key]!.shortLabel),
                ),
            ],
            selected: {metric},
            onSelectionChanged: (selection) => onMetricChange(selection.first),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: _chartHeight + _labelSpace,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _labelSpace + (goal / maxValue) * _chartHeight,
                  child: Semantics(
                    label: 'Goal ${formatNumber(goal)} ${style.unit}',
                    child: CustomPaint(
                      size: const Size(double.infinity, 1.5),
                      painter: DashedLinePainter(color: style.color.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final bar in bars)
                      Expanded(
                        child: _Bar(bar: bar, maxValue: maxValue, style: style),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CustomPaint(
                size: const Size(18, 1.5),
                painter: DashedLinePainter(color: style.color),
              ),
              const SizedBox(width: 8),
              Text(
                'Daily goal · ${formatNumber(goal)} ${style.unit}',
                style: text.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.bar, required this.maxValue, required this.style});

  final ChartBar bar;
  final double maxValue;
  final MetricStyle style;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final height = math.max(4.0, (bar.value / maxValue) * _chartHeight);
    return Semantics(
      label: '${bar.isToday ? 'Today' : bar.label}: ${formatNumber(bar.value)} ${style.unit}',
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FractionallySizedBox(
            widthFactor: 0.78,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: bar.isToday ? style.color : style.color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: _labelHeight,
            child: Text(
              bar.isToday ? 'Today' : bar.label,
              maxLines: 1,
              style: text.labelSmall?.copyWith(
                color: bar.isToday ? style.color : AppColors.onSurfaceVariant,
                fontWeight: bar.isToday ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal dashed line across the full width of its canvas.
class DashedLinePainter extends CustomPainter {
  DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 5.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + dash, size.width), y), paint);
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter old) => old.color != color;
}
