import '../../../core/utils/date_utils.dart';
import '../../../core/utils/number_utils.dart';
import 'health_record.dart';

/// Raw text exactly as typed into the form.
class RecordFormValues {
  const RecordFormValues({required this.date, this.steps = '', this.calories = '', this.water = ''});

  factory RecordFormValues.fromRecord(HealthRecordInput record) => RecordFormValues(
    date: record.date,
    steps: '${record.steps}',
    calories: '${record.calories}',
    water: '${record.water}',
  );

  final String date;
  final String steps;
  final String calories;
  final String water;

  String metric(MetricKey key) => switch (key) {
    MetricKey.steps => steps,
    MetricKey.calories => calories,
    MetricKey.water => water,
  };

  RecordFormValues copyWith({String? date, String? steps, String? calories, String? water}) => RecordFormValues(
    date: date ?? this.date,
    steps: steps ?? this.steps,
    calories: calories ?? this.calories,
    water: water ?? this.water,
  );

  RecordFormValues withMetric(MetricKey key, String text) => switch (key) {
    MetricKey.steps => copyWith(steps: text),
    MetricKey.calories => copyWith(calories: text),
    MetricKey.water => copyWith(water: text),
  };
}

/// Field names used as keys in [RecordFormErrors]. `form` is the whole-form message.
enum RecordFormField { date, steps, calories, water, form }

typedef RecordFormErrors = Map<RecordFormField, String>;

RecordFormField fieldOf(MetricKey key) => switch (key) {
  MetricKey.steps => RecordFormField.steps,
  MetricKey.calories => RecordFormField.calories,
  MetricKey.water => RecordFormField.water,
};

/// Result of [validateRecordForm]: either [data] or a non-empty [errors] map.
class RecordValidationResult {
  const RecordValidationResult.valid(HealthRecordInput this.data) : errors = const {};
  const RecordValidationResult.invalid(this.errors) : data = null;

  final HealthRecordInput? data;
  final RecordFormErrors errors;

  bool get isValid => data != null;
}

const Map<MetricKey, String> _metricLabels = {
  MetricKey.steps: 'Steps',
  MetricKey.calories: 'Calories',
  MetricKey.water: 'Water intake',
};

final RegExp _digitsOnly = RegExp(r'^\d+$');

/// Outcome of parsing one numeric field: a value or an error message.
typedef _Parsed = ({int? value, String? error});

/// Converts one numeric field. Empty means "not tracked" and becomes 0.
/// Thousands separators are accepted ("7,850") because users copy numbers from
/// fitness bands that format them that way.
_Parsed _parseMetric(MetricKey key, String raw) {
  final text = raw.trim().replaceAll(',', '');
  if (text.isEmpty) return (value: 0, error: null);
  final label = _metricLabels[key]!;
  if (text.startsWith('-')) return (value: null, error: '$label cannot be negative');
  if (!_digitsOnly.hasMatch(text)) return (value: null, error: '$label must be a whole number');
  final value = int.tryParse(text);
  final limit = metricLimits[key]!;
  if (value == null || value > limit) {
    return (value: null, error: '$label must be between 0 and ${formatNumber(limit)}');
  }
  return (value: value, error: null);
}

/// Validates the Add/Edit form. [today] is injected so tests are deterministic
/// and future dates can be rejected.
RecordValidationResult validateRecordForm(RecordFormValues values, String today) {
  final errors = <RecordFormField, String>{};

  final date = values.date.trim();
  if (date.isEmpty) {
    errors[RecordFormField.date] = 'Date is required';
  } else if (!isValidIsoDate(date)) {
    errors[RecordFormField.date] = 'Date must be a valid date (YYYY-MM-DD)';
  } else if (date.compareTo(today) > 0) {
    errors[RecordFormField.date] = 'Date cannot be in the future';
  }

  final parsed = <MetricKey, int>{};
  for (final key in MetricKey.values) {
    final result = _parseMetric(key, values.metric(key));
    if (result.error != null) {
      errors[fieldOf(key)] = result.error!;
    } else {
      parsed[key] = result.value!;
    }
  }

  final metricsValid = parsed.length == MetricKey.values.length;
  if (metricsValid && parsed.values.every((value) => value == 0)) {
    errors[RecordFormField.form] = 'Enter at least one value: steps, calories or water';
  }

  if (errors.isNotEmpty) return RecordValidationResult.invalid(errors);

  return RecordValidationResult.valid(
    HealthRecordInput(
      date: date,
      steps: parsed[MetricKey.steps]!,
      calories: parsed[MetricKey.calories]!,
      water: parsed[MetricKey.water]!,
    ),
  );
}
