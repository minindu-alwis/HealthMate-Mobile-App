import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_database.dart';

Future<int> countRecords(Database db) async =>
    (await db.rawQuery('SELECT COUNT(*) AS n FROM health_records')).first['n'] as int;

void main() {
  setUpAll(initTestDatabaseFactory);

  group('AppDatabase migrations', () {
    test('creates health_records with the fields required by the brief', () async {
      final db = await openTestDatabase();
      final columns = await db.rawQuery('PRAGMA table_info(health_records)');
      final byName = {for (final c in columns) c['name']: c};

      expect(byName.keys, ['id', 'date', 'steps', 'calories', 'water']);
      expect(byName['id']!['pk'], 1);
      expect(byName['date']!['type'], 'TEXT');
      expect(byName['date']!['notnull'], 1);
      for (final name in ['steps', 'calories', 'water']) {
        expect(byName[name]!['type'], 'INTEGER');
        expect(byName[name]!['notnull'], 1);
      }
      await db.close();
    });

    test('creates the date index and stores schema version 1', () async {
      final db = await openTestDatabase();
      final index = await db.rawQuery("SELECT name FROM sqlite_master WHERE type = 'index' AND name = ?", [
        'idx_health_records_date',
      ]);
      expect(index, hasLength(1));
      expect(await db.getVersion(), AppDatabase.version);
      await db.close();
    });

    test("seeds 14 days ending today, with the brief's example as today's row", () async {
      final db = await openTestDatabase(today: '2026-11-07');
      final rows = await db.rawQuery('SELECT date, steps, calories, water FROM health_records ORDER BY date');

      expect(rows, hasLength(14));
      expect(rows.first['date'], '2026-10-25');
      expect(rows.last, {'date': '2026-11-07', 'steps': 7850, 'calories': 420, 'water': 2000});
      await db.close();
    });

    test('seeds the default goals: 10,000 steps, 500 kcal, 2,500 ml', () async {
      final db = await openTestDatabase();
      final rows = await db.rawQuery('SELECT key, value FROM user_goals ORDER BY key');
      expect(rows, [
        {'key': 'calories', 'value': 500},
        {'key': 'steps', 'value': 10000},
        {'key': 'water', 'value': 2500},
      ]);
      await db.close();
    });

    test('seeds only once: reopening neither duplicates nor re-seeds after the user cleared the data', () async {
      final dir = await Directory.systemTemp.createTemp('healthmate_test_');
      final path = p.join(dir.path, 'healthmate.db');
      try {
        var db = await AppDatabase.open(factory: databaseFactoryFfi, path: path, today: () => testToday);
        expect(await countRecords(db), 14);
        await db.close();

        db = await AppDatabase.open(factory: databaseFactoryFfi, path: path, today: () => testToday);
        expect(await countRecords(db), 14);
        await db.delete('health_records');
        await db.close();

        db = await AppDatabase.open(factory: databaseFactoryFfi, path: path, today: () => testToday);
        expect(await countRecords(db), 0);
        await db.close();
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('rolls back a failed migration so nothing is half-created', () async {
      final dir = await Directory.systemTemp.createTemp('healthmate_test_');
      final path = p.join(dir.path, 'healthmate.db');
      try {
        Future<void> broken(DatabaseExecutor db, String today) async {
          await db.execute('CREATE TABLE half_done (id INTEGER)');
          throw StateError('migration failed');
        }

        await expectLater(
          AppDatabase.open(factory: databaseFactoryFfi, path: path, migrationsOverride: [broken]),
          throwsA(isA<StateError>()),
        );

        final db = await AppDatabase.open(factory: databaseFactoryFfi, path: path, today: () => testToday);
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'half_done'");
        expect(tables, isEmpty);
        expect(await db.getVersion(), 1);
        expect(await countRecords(db), 14);
        await db.close();
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
