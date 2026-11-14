import 'package:healthmate/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A fixed "today" so seed dates and assertions never depend on the real clock.
const String testToday = '2026-11-07';

bool _ffiReady = false;

/// sqflite needs a platform channel on a phone; on the desktop test runner the
/// same API is provided by sqflite_common_ffi on top of the bundled SQLite.
void initTestDatabaseFactory() {
  if (_ffiReady) return;
  sqfliteFfiInit();
  _ffiReady = true;
}

/// Opens a fresh in-memory database through the real AppDatabase migrations,
/// so every test runs the production SQL, schema and seed.
Future<Database> openTestDatabase({String today = testToday, bool seeded = true}) async {
  initTestDatabaseFactory();
  final db = await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath, today: () => today);
  if (!seeded) await db.delete('health_records');
  return db;
}
