import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../records/model/health_record.dart';
import '../../viewmodel/dashboard_view_model.dart';

const List<int> _amountsMl = [250, 500];

/// Today's water progress plus one-tap logging (adds to today's latest record).
class HydrationCard extends StatelessWidget {
  const HydrationCard({super.key, required this.water, required this.onAdd});

  final MetricProgress water;
  final ValueChanged<int> onAdd;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = metricStyles[MetricKey.water]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: style.container, borderRadius: BorderRadius.circular(cardRadius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: style.color, shape: BoxShape.circle),
                child: const Icon(Icons.local_drink, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hydration', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      '${formatNumber(water.value)} of ${formatNumber(water.goal)} ml',
                      style: text.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                '${water.percent}%',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: style.color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Water progress ${water.percent} percent',
            excludeSemantics: true,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                height: 10,
                color: Colors.white,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: water.percent / 100,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: style.color, borderRadius: BorderRadius.circular(5)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final ml in _amountsMl) ...[
                if (ml != _amountsMl.first) const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    label: 'Add $ml millilitres of water',
                    button: true,
                    excludeSemantics: true,
                    child: FilledButton.icon(
                      onPressed: () => onAdd(ml),
                      style: FilledButton.styleFrom(backgroundColor: style.color),
                      icon: const Icon(Icons.add),
                      label: Text('$ml ml'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
