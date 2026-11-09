import 'package:sqflite/sqflite.dart';

import '../../../core/utils/date_utils.dart';
import '../../records/model/health_record.dart';

/// Totals for one day. Several entries on the same date are summed.
class DailyTotals {
  const DailyTotals({required this.date, this.steps = 0, this.calories = 0, this.water = 0, this.entries = 0});

  factory DailyTotals.fromMap(String date, Map<String, Object?> row) => DailyTotals(
    date: date,
    steps: (row['steps'] as num?)?.toInt() ?? 0,
    calories: (row['calories'] as num?)?.toInt() ?? 0,
    water: (row['water'] as num?)?.toInt() ?? 0,
    entries: (row['entries'] as num?)?.toInt() ?? 0,
  );

  final String date;
  final int steps;
  final int calories;
  final int water;

  /// Number of records that make up the totals.
  final int entries;

  int valueOf(MetricKey key) => switch (key) {
    MetricKey.steps => steps,
    MetricKey.calories => calories,
    MetricKey.water => water,
  };
}

/// Read-only aggregate queries for the dashboard.
class SummaryRepository {
  SummaryRepository(this._db);

  final Database _db;

  static const String _totals = '''
    COALESCE(SUM(steps), 0)    AS steps,
    COALESCE(SUM(calories), 0) AS calories,
    COALESCE(SUM(water), 0)    AS water,
    COUNT(id)                  AS entries''';

  /// Sum of every entry recorded for [date] (zeros when nothing was logged).
  Future<DailyTotals> getDailyTotals(String date) async {
    final rows = await _db.rawQuery('SELECT $_totals FROM health_records WHERE date = ?', [date]);
    return DailyTotals.fromMap(date, rows.first);
  }

  /// One row per day from [from] to [to] inclusive; days without records are zero-filled.
  Future<List<DailyTotals>> getTotalsBetween(String from, String to) async {
    final rows = await _db.rawQuery(
      'SELECT date, $_totals FROM health_records '
      'WHERE date BETWEEN ? AND ? GROUP BY date ORDER BY date',
      [from, to],
    );
    final byDate = {for (final row in rows) row['date'] as String: DailyTotals.fromMap(row['date'] as String, row)};
    return [for (final date in dateRange(from, to)) byDate[date] ?? DailyTotals(date: date)];
  }
}
