import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../model/health_record.dart';
import '../../viewmodel/records_view_model.dart';

/// Search-by-date controls: quick chips plus Material date / date-range pickers.
/// Pickers stop at today, because a record cannot be in the future.
class DateFilterBar extends StatelessWidget {
  const DateFilterBar({super.key, required this.vm});

  final RecordsViewModel vm;

  Future<void> _pickDay(BuildContext context) async {
    final today = parseIsoDate(vm.today);
    final current = vm.filter;
    final picked = await showDatePicker(
      context: context,
      initialDate: current is SingleDay ? parseIsoDate(current.date) : today,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Show records for',
    );
    if (picked != null) await vm.showDay(toIsoDate(picked));
  }

  Future<void> _pickRange(BuildContext context) async {
    final today = parseIsoDate(vm.today);
    final current = vm.filter;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDateRange: current is DateSpan
          ? DateTimeRange(start: parseIsoDate(current.from), end: parseIsoDate(current.to))
          : null,
      helpText: 'Show records between',
    );
    if (picked != null) await vm.showRange(toIsoDate(picked.start), toIsoDate(picked.end));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final chips = <(FilterPreset, String, IconData?, VoidCallback)>[
      (FilterPreset.all, 'All', null, vm.showAll),
      (FilterPreset.today, 'Today', null, vm.showToday),
      (FilterPreset.week, 'Last 7 days', null, vm.showLastWeek),
      (FilterPreset.day, 'Pick date', Icons.calendar_today, () => _pickDay(context)),
      (FilterPreset.range, 'Date range', Icons.date_range, () => _pickRange(context)),
    ];
    final newest = vm.sort == SortOrder.newest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final (preset, label, icon, onTap) = chips[index];
              final selected = vm.activePreset == preset;
              return Center(
                child: FilterChip(
                  label: Text(label),
                  selected: selected,
                  showCheckmark: selected,
                  avatar: selected || icon == null ? null : Icon(icon, size: 18, color: AppColors.primary),
                  labelStyle: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.onPrimaryContainer : AppColors.onSurface,
                  ),
                  side: BorderSide(color: selected ? AppColors.primaryContainer : AppColors.outline),
                  onSelected: (_) => onTap(),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(vm.filterLabel, style: text.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
              ),
              if (vm.isFiltered)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear date filter',
                  onPressed: vm.showAll,
                ),
              IconButton(
                icon: Icon(newest ? Icons.arrow_downward : Icons.arrow_upward, size: 20),
                color: AppColors.onSurfaceVariant,
                tooltip: newest
                    ? 'Sorted newest first. Tap for oldest first'
                    : 'Sorted oldest first. Tap for newest first',
                onPressed: vm.toggleSort,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
