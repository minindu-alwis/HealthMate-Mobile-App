import 'package:sqflite/sqflite.dart';

import '../../../core/database/sample_data.dart';
import '../../../core/utils/errors.dart';
import '../model/health_record.dart';

/// Thrown when an update/delete targets an id that is no longer in the table.
class RecordNotFoundException extends AppException {
  RecordNotFoundException(this.id) : super('Health record $id no longer exists');

  final int id;
}

/// All SQL for the `health_records` table lives in this class.
/// Every value is passed as a bound parameter (`?`), never concatenated.
class HealthRecordRepository {
  HealthRecordRepository(this._db);

  final Database _db;

  static const String _table = 'health_records';
  static const String _columns = 'id, date, steps, calories, water';

  Future<List<HealthRecord>> findAll({DateFilter filter = const AllDates(), SortOrder sort = SortOrder.newest}) async {
    final (where, args) = switch (filter) {
      AllDates() => ('', const <Object?>[]),
      SingleDay(:final date) => ('WHERE date = ?', [date]),
      DateSpan(:final from, :final to) => ('WHERE date BETWEEN ? AND ?', [from, to]),
    };
    // ISO dates sort correctly as text; id breaks ties between entries on the same day.
    final order = sort == SortOrder.newest ? 'date DESC, id DESC' : 'date ASC, id ASC';
    final rows = await _db.rawQuery('SELECT $_columns FROM $_table $where ORDER BY $order', args);
    return rows.map(HealthRecord.fromMap).toList();
  }

  Future<HealthRecord?> findById(int id) async {
    final rows = await _db.rawQuery('SELECT $_columns FROM $_table WHERE id = ?', [id]);
    return rows.isEmpty ? null : HealthRecord.fromMap(rows.first);
  }

  Future<HealthRecord> create(HealthRecordInput input) async {
    final id = await _db.insert(_table, input.toMap());
    return HealthRecord.fromInput(id, input);
  }

  Future<HealthRecord> update(int id, HealthRecordInput input) async {
    final changes = await _db.update(_table, input.toMap(), where: 'id = ?', whereArgs: [id]);
    if (changes == 0) throw RecordNotFoundException(id);
    return HealthRecord.fromInput(id, input);
  }

  Future<void> remove(int id) async {
    final changes = await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
    if (changes == 0) throw RecordNotFoundException(id);
  }

  /// Re-inserts a deleted record with its original id (used by "Undo").
  Future<void> restore(HealthRecord record) async {
    await _db.insert(_table, record.toMap());
  }

  /// Adds water to the latest entry for [date], creating an entry if none exists.
  /// Read-then-write runs in one transaction so two quick taps cannot race.
  Future<HealthRecord> addWater(String date, int ml) async {
    final id = await _db.transaction((txn) async {
      final latest = await txn.rawQuery('SELECT id FROM $_table WHERE date = ? ORDER BY id DESC LIMIT 1', [date]);
      if (latest.isNotEmpty) {
        final id = latest.first['id'] as int;
        await txn.rawUpdate('UPDATE $_table SET water = water + ? WHERE id = ?', [ml, id]);
        return id;
      }
      return txn.rawInsert('INSERT INTO $_table (date, steps, calories, water) VALUES (?, 0, 0, ?)', [date, ml]);
    });
    final record = await findById(id);
    if (record == null) throw RecordNotFoundException(id);
    return record;
  }

  Future<void> removeAll() async {
    await _db.delete(_table);
  }

  /// Clears the table and inserts the 14-day sample set, all or nothing.
  Future<void> replaceWithSampleData(String today) async {
    await _db.transaction((txn) async {
      await txn.delete(_table);
      final batch = txn.batch();
      for (final record in buildSampleRecords(today)) {
        batch.insert(_table, record.toMap());
      }
      await batch.commit(noResult: true);
    });
  }
}
