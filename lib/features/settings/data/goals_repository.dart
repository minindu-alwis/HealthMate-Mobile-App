import 'package:sqflite/sqflite.dart';

import '../../records/model/health_record.dart';
import '../model/goals.dart';

/// Reads and writes the `user_goals` key/value table.
class GoalsRepository {
  GoalsRepository(this._db);

  final Database _db;

  Future<DailyGoals> getGoals() async {
    final rows = await _db.rawQuery('SELECT key, value FROM user_goals');
    var goals = DailyGoals.defaults;
    for (final row in rows) {
      final key = MetricKey.values.where((k) => k.name == row['key']).firstOrNull;
      if (key != null) goals = goals.copyWithMetric(key, row['value'] as int);
    }
    return goals;
  }

  /// Saves all three goals in one transaction, so a failure leaves none changed.
  Future<void> saveGoals(DailyGoals goals) async {
    await _db.transaction((txn) async {
      for (final key in MetricKey.values) {
        await txn.rawInsert('INSERT OR REPLACE INTO user_goals (key, value) VALUES (?, ?)', [key.name, goals.of(key)]);
      }
    });
  }
}
