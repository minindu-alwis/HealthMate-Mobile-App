/// The three tracked metrics, in display order.
enum MetricKey { steps, calories, water }

/// Upper bounds used by validation; values above these are almost certainly typos.
const Map<MetricKey, int> metricLimits = {MetricKey.steps: 100000, MetricKey.calories: 10000, MetricKey.water: 10000};

/// Values for a record that is not saved yet (no id).
class HealthRecordInput {
  const HealthRecordInput({required this.date, this.steps = 0, this.calories = 0, this.water = 0});

  /// ISO `YYYY-MM-DD`, local time.
  final String date;
  final int steps;

  /// kcal
  final int calories;

  /// millilitres
  final int water;

  int valueOf(MetricKey key) => switch (key) {
    MetricKey.steps => steps,
    MetricKey.calories => calories,
    MetricKey.water => water,
  };

  Map<String, Object?> toMap() => {'date': date, 'steps': steps, 'calories': calories, 'water': water};

  @override
  bool operator ==(Object other) =>
      other is HealthRecordInput &&
      other.runtimeType == runtimeType &&
      other.date == date &&
      other.steps == steps &&
      other.calories == calories &&
      other.water == water;

  @override
  int get hashCode => Object.hash(date, steps, calories, water);
}

/// One row of the `health_records` table.
class HealthRecord extends HealthRecordInput {
  const HealthRecord({required this.id, required super.date, super.steps, super.calories, super.water});

  factory HealthRecord.fromInput(int id, HealthRecordInput input) =>
      HealthRecord(id: id, date: input.date, steps: input.steps, calories: input.calories, water: input.water);

  factory HealthRecord.fromMap(Map<String, Object?> row) => HealthRecord(
    id: row['id'] as int,
    date: row['date'] as String,
    steps: row['steps'] as int,
    calories: row['calories'] as int,
    water: row['water'] as int,
  );

  final int id;

  @override
  Map<String, Object?> toMap() => {'id': id, ...super.toMap()};

  @override
  bool operator ==(Object other) => other is HealthRecord && other.id == id && super == other;

  @override
  int get hashCode => Object.hash(id, super.hashCode);

  @override
  String toString() => 'HealthRecord(#$id $date: $steps steps, $calories kcal, $water ml)';
}

/// Which records the list shows.
sealed class DateFilter {
  const DateFilter();
}

class AllDates extends DateFilter {
  const AllDates();

  @override
  bool operator ==(Object other) => other is AllDates;

  @override
  int get hashCode => 0;
}

class SingleDay extends DateFilter {
  const SingleDay(this.date);

  final String date;

  @override
  bool operator ==(Object other) => other is SingleDay && other.date == date;

  @override
  int get hashCode => date.hashCode;
}

class DateSpan extends DateFilter {
  const DateSpan(this.from, this.to);

  final String from;
  final String to;

  @override
  bool operator ==(Object other) => other is DateSpan && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

enum SortOrder { newest, oldest }
