import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/number_utils.dart';
import '../../model/health_record.dart';

/// One record in the list: date badge, three coloured metric pills, edit/delete.
///
/// The tappable area and the icon buttons are siblings, never nested, so screen
/// readers announce them as separate controls.
class RecordCard extends StatelessWidget {
  const RecordCard({
    super.key,
    required this.record,
    required this.isToday,
    required this.onEdit,
    required this.onDelete,
  });

  final HealthRecord record;
  final bool isToday;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dateLabel = formatShortDate(record.date);
    final summary = MetricKey.values
        .map((k) => '${formatNumber(record.valueOf(k))} ${metricStyles[k]!.unit}')
        .join(', ');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: cardDecoration(),
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Record for $dateLabel: $summary',
                hint: 'Opens the record for editing',
                excludeSemantics: true,
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(cardRadius)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
                    child: Row(
                      children: [
                        _DateBadge(date: record.date, isToday: isToday),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateLabel, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (final key in MetricKey.values) ...[
                                    if (key != MetricKey.values.first) const SizedBox(width: 4),
                                    Expanded(
                                      child: _MetricPill(metric: key, value: record.valueOf(key)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.onSurfaceVariant,
                  tooltip: 'Edit record for $dateLabel',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  tooltip: 'Delete record for $dateLabel',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date, required this.isToday});

  final String date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final day = parseIsoDate(date);
    final color = isToday ? Colors.white : AppColors.primary;
    final small = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: color);
    return Container(
      width: 56,
      height: 66,
      decoration: BoxDecoration(
        color: isToday ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(isToday ? 'TODAY' : formatWeekday(date).toUpperCase(), style: small),
          Text(
            '${day.day}',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.15, color: color),
          ),
          Text(formatMonthAbbr(date), style: small),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.metric, required this.value});

  final MetricKey metric;
  final int value;

  @override
  Widget build(BuildContext context) {
    final style = metricStyles[metric]!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(color: style.container, borderRadius: BorderRadius.circular(999)),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 15, color: style.color),
            const SizedBox(width: 3),
            Text(
              formatNumber(value),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: style.color),
            ),
          ],
        ),
      ),
    );
  }
}
