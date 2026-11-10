import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_banner.dart';
import '../viewmodel/dashboard_view_model.dart';
import 'widgets/hero_header.dart';
import 'widgets/hydration_card.dart';
import 'widgets/metric_tile.dart';
import 'widgets/weekly_chart.dart';

/// How far the metric tiles overlap the bottom of the hero.
const double _tileOverlap = 44;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final text = Theme.of(context).textTheme;

    Future<void> addWater(int ml) async {
      final message = await vm.quickAddWater(ml);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(milliseconds: 2500)));
    }

    // White status-bar icons over the teal hero; the other tabs use dark icons.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightStatusBar,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: vm.load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              HeroHeader(
                greeting: vm.greeting,
                dateLabel: vm.todayLabel,
                score: vm.score,
                goalsMet: vm.goalsMet,
                goalCount: vm.metrics.length,
              ),
              Transform.translate(
                offset: const Offset(0, -_tileOverlap),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final metric in vm.metrics) ...[
                              if (metric != vm.metrics.first) const SizedBox(width: 10),
                              Expanded(child: MetricTile(metric: metric)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (vm.error != null) ...[
                        ErrorBanner(message: vm.error!, onRetry: vm.load),
                        const SizedBox(height: 12),
                      ],
                      if (!vm.hasEntriesToday && !vm.loading) ...[
                        Text(
                          'Nothing logged yet today. Tap “Add record” to start.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                      ],
                      HydrationCard(water: vm.water, onAdd: addWater),
                      const SizedBox(height: 16),
                      WeeklyChart(
                        bars: vm.chart,
                        metric: vm.chartMetric,
                        goal: vm.chartGoal,
                        average: vm.chartAverage,
                        onMetricChange: vm.setChartMetric,
                      ),
                    ],
                  ),
                ),
              ),
              // Room for the FAB; the translate above already freed 44px.
              const SizedBox(height: 104 - _tileOverlap),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'dashboard-fab',
          onPressed: () => openRecordForm(context),
          icon: const Icon(Icons.add),
          label: const Text('Add record', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
