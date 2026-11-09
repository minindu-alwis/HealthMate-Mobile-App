import '../../../core/utils/number_utils.dart';
import '../../records/model/health_record.dart';

/// Daily targets for each metric.
class DailyGoals {
  const DailyGoals({required this.steps, required this.calories, required this.water});

  final int steps;
  final int calories;
  final int water;

  static const defaults = DailyGoals(steps: 10000, calories: 500, water: 2500);

  int of(MetricKey key) => switch (key) {
    MetricKey.steps => steps,
    MetricKey.calories => calories,
    MetricKey.water => water,
  };

  DailyGoals copyWithMetric(MetricKey key, int value) => DailyGoals(
    steps: key == MetricKey.steps ? value : steps,
    calories: key == MetricKey.calories ? value : calories,
    water: key == MetricKey.water ? value : water,
  );

  @override
  bool operator ==(Object other) =>
      other is DailyGoals && other.steps == steps && other.calories == calories && other.water == water;

  @override
  int get hashCode => Object.hash(steps, calories, water);

  @override
  String toString() => 'DailyGoals($steps steps, $calories kcal, $water ml)';
}

/// Result of [validateGoals]: either [data] or a non-empty [errors] map.
class GoalsValidationResult {
  const GoalsValidationResult.valid(DailyGoals this.data) : errors = const {};
  const GoalsValidationResult.invalid(this.errors) : data = null;

  final DailyGoals? data;
  final Map<MetricKey, String> errors;

  bool get isValid => data != null;
}

final RegExp _digitsOnly = RegExp(r'^\d+$');

/// Goals must be whole numbers from 1 up to the same limits used for records.
GoalsValidationResult validateGoals(Map<MetricKey, String> values) {
  final errors = <MetricKey, String>{};
  var data = DailyGoals.defaults;
  for (final key in MetricKey.values) {
    final text = (values[key] ?? '').trim().replaceAll(',', '');
    final limit = metricLimits[key]!;
    final value = _digitsOnly.hasMatch(text) ? int.tryParse(text) : null;
    if (value == null || value < 1 || value > limit) {
      errors[key] = 'Enter a whole number from 1 to ${formatNumber(limit)}';
    } else {
      data = data.copyWithMetric(key, value);
    }
  }
  return errors.isEmpty ? GoalsValidationResult.valid(data) : GoalsValidationResult.invalid(errors);
}
