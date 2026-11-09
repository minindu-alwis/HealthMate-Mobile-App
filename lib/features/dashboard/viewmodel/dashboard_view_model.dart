import 'dart:async';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/errors.dart';
import '../../../core/utils/number_utils.dart';
import '../../../core/viewmodel/safe_change_notifier.dart';
import '../../records/model/health_record.dart';
import '../../records/viewmodel/records_view_model.dart';
import '../../settings/viewmodel/goals_view_model.dart';
import '../data/summary_repository.dart';

const int weekLength = 7;

/// Progress of one metric towards its daily goal.
class MetricProgress {
  const MetricProgress({required this.key, required this.value, required this.goal, required this.percent});

  final MetricKey key;
  final int value;
  final int goal;

  /// 0..100
  final int percent;
}

/// One bar of the 7-day chart.
class ChartBar {
  const ChartBar({required this.date, required this.label, required this.value, required this.isToday});

  final String date;
  final String label;
  final int value;
  final bool isToday;
}

String greetingFor(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

/// Today's totals, goal progress and the last 7 days.
///
/// Listens to [RecordsViewModel.revision] so any write anywhere in the app
/// (form, list delete, settings reset, quick water) refreshes the dashboard,
/// and to [GoalsViewModel] so new goals redraw the rings straight away.
class DashboardViewModel extends SafeChangeNotifier {
  DashboardViewModel(
    this._summary,
    this._records,
    this._goals, {
    String Function() today = todayIso,
    this._now = DateTime.now,
  }) : _todayFn = today,
       _today = today(),
       _seenRevision = _records.revision {
    _records.addListener(_onRecordsChanged);
    _goals.addListener(notifyListeners);
  }

  final SummaryRepository _summary;
  final RecordsViewModel _records;
  final GoalsViewModel _goals;
  final String Function() _todayFn;
  final DateTime Function() _now;

  String _today;
  int _seenRevision;
  DailyTotals? _totals;
  List<DailyTotals> _week = const [];
  bool _loading = false;
  String? _error;
  MetricKey _chartMetric = MetricKey.steps;

  bool get loading => _loading;
  String? get error => _error;
  MetricKey get chartMetric => _chartMetric;
  String get today => _today;

  String get greeting => greetingFor(_now().hour);
  String get todayLabel => formatLongDate(_today);
  bool get hasEntriesToday => (_totals?.entries ?? 0) > 0;

  List<MetricProgress> get metrics => [
    for (final key in MetricKey.values)
      MetricProgress(
        key: key,
        value: _totals?.valueOf(key) ?? 0,
        goal: _goals.goals.of(key),
        percent: percentOf(_totals?.valueOf(key) ?? 0, _goals.goals.of(key)),
      ),
  ];

  /// Average progress across the three goals, 0..100.
  int get score {
    final list = metrics;
    return (list.fold<int>(0, (sum, m) => sum + m.percent) / list.length).round();
  }

  int get goalsMet => metrics.where((m) => m.percent >= 100).length;

  MetricProgress get water => metrics[MetricKey.water.index];

  List<ChartBar> get chart => [
    for (final day in _week)
      ChartBar(
        date: day.date,
        label: formatWeekday(day.date),
        value: day.valueOf(_chartMetric),
        isToday: day.date == _today,
      ),
  ];

  int get chartGoal => _goals.goals.of(_chartMetric);

  double get chartAverage {
    final bars = chart;
    if (bars.isEmpty) return 0;
    return bars.fold<int>(0, (sum, bar) => sum + bar.value) / bars.length;
  }

  void setChartMetric(MetricKey metric) {
    _chartMetric = metric;
    notifyListeners();
  }

  /// Loads today's totals and the 7 days ending today.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _summary.getDailyTotals(_today),
        _summary.getTotalsBetween(addDays(_today, -(weekLength - 1)), _today),
      ]);
      _totals = results[0] as DailyTotals;
      _week = results[1] as List<DailyTotals>;
    } catch (e) {
      _error = errorMessage(e);
    }
    _loading = false;
    notifyListeners();
  }

  /// The app may stay open past midnight: re-read "today" when the dashboard
  /// becomes visible again or the app resumes.
  Future<void> refreshDay() async {
    final now = _todayFn();
    if (now != _today) {
      _today = now;
      await load();
    }
  }

  /// One-tap water logging. Returns the SnackBar text.
  Future<String> quickAddWater(int ml) async {
    try {
      await _records.addWater(_today, ml);
      return 'Added $ml ml of water';
    } catch (e) {
      return errorMessage(e);
    }
  }

  void _onRecordsChanged() {
    if (_records.revision != _seenRevision) {
      _seenRevision = _records.revision;
      unawaited(load());
    }
  }

  @override
  void dispose() {
    _records.removeListener(_onRecordsChanged);
    _goals.removeListener(notifyListeners);
    super.dispose();
  }
}
