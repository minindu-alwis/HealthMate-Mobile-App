import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../features/settings/model/goals.dart';
import '../utils/date_utils.dart';
import 'sample_data.dart';

/// One schema step. [up] runs inside the transaction sqflite opens for
/// `onCreate` / `onUpgrade`, so a failure rolls the whole step back.
typedef Migration = Future<void> Function(DatabaseExecutor db, String today);

/// Opens `healthmate.db` and keeps its schema up to date.
///
/// The schema version is stored by sqflite in `PRAGMA user_version`:
/// * `onCreate` runs on a fresh install and applies every migration from 1.
/// * `onUpgrade` runs after an app update and applies only the newer ones.
/// Never edit a released migration; append a new one and bump [version].
class AppDatabase {
  AppDatabase._();

  static const String fileName = 'healthmate.db';

  /// Latest schema version. Must equal `migrations.length`.
  static const int version = 1;

  /// Ordered migrations: index 0 is version 1.
  static final List<Migration> migrations = [_createSchemaV1];

  /// Opens (or creates) the database file.
  ///
  /// [factory] and [path] are injectable so tests can use `sqflite_common_ffi`
  /// with an in-memory database; [today] is injectable so the seed data is
  /// deterministic in tests.
  static Future<Database> open({
    DatabaseFactory? factory,
    String? path,
    String Function() today = todayIso,
    List<Migration>? migrationsOverride,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await dbFactory.getDatabasesPath(), fileName);
    final steps = migrationsOverride ?? migrations;

    Future<void> runMigrations(Database db, int from, int to) async {
      for (var v = from + 1; v <= to; v++) {
        await steps[v - 1](db, today());
      }
    }

    return dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: steps.length,
        // Foreign keys are off by default in SQLite; enabled for future tables.
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, newVersion) => runMigrations(db, 0, newVersion),
        onUpgrade: (db, oldVersion, newVersion) => runMigrations(db, oldVersion, newVersion),
        // In-memory databases must not be shared between tests.
        singleInstance: dbPath != inMemoryDatabasePath,
      ),
    );
  }
}

/// Version 1: both tables, the date index, default goals and the dummy records.
/// Seeding here means the sample data appears on first launch only, never again
/// after the user clears it.
Future<void> _createSchemaV1(DatabaseExecutor db, String today) async {
  await db.execute('''
    CREATE TABLE health_records (
      id       INTEGER PRIMARY KEY AUTOINCREMENT,
      date     TEXT    NOT NULL,
      steps    INTEGER NOT NULL DEFAULT 0 CHECK (steps >= 0),
      calories INTEGER NOT NULL DEFAULT 0 CHECK (calories >= 0),
      water    INTEGER NOT NULL DEFAULT 0 CHECK (water >= 0)
    )''');
  await db.execute('CREATE INDEX idx_health_records_date ON health_records (date)');
  await db.execute('''
    CREATE TABLE user_goals (
      key   TEXT    PRIMARY KEY NOT NULL,
      value INTEGER NOT NULL CHECK (value > 0)
    )''');

  final batch = db.batch();
  const goals = DailyGoals.defaults;
  for (final entry in {'steps': goals.steps, 'calories': goals.calories, 'water': goals.water}.entries) {
    batch.rawInsert('INSERT OR IGNORE INTO user_goals (key, value) VALUES (?, ?)', [entry.key, entry.value]);
  }
  for (final record in buildSampleRecords(today)) {
    batch.rawInsert('INSERT INTO health_records (date, steps, calories, water) VALUES (?, ?, ?, ?)', [
      record.date,
      record.steps,
      record.calories,
      record.water,
    ]);
  }
  await batch.commit(noResult: true);
}
