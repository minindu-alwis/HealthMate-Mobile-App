import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../viewmodel/dashboard_view_model.dart';

/// Compact tile: the ring shows progress to the daily goal, value and unit underneath.
class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.metric});

  final MetricProgress metric;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = metricStyles[metric.key]!;

    return Semantics(
      label:
          '${style.label}: ${formatNumber(metric.value)} ${style.unit}, '
          '${metric.percent} percent of your ${formatNumber(metric.goal)} goal',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: cardDecoration(),
        child: Column(
          children: [
            ProgressRing(
              percent: metric.percent,
              size: 64,
              strokeWidth: 7,
              color: style.color,
              trackColor: style.container,
              child: Icon(style.icon, size: 24, color: style.color),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(formatNumber(metric.value), style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            Text(
              '${style.unit} · ${metric.percent}%',
              style: text.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(
              style.shortLabel,
              style: text.labelMedium?.copyWith(color: style.color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
