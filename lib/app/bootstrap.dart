import 'package:sqflite/sqflite.dart';

import '../core/database/app_database.dart';
import '../features/dashboard/data/summary_repository.dart';
import '../features/dashboard/viewmodel/dashboard_view_model.dart';
import '../features/records/data/health_record_repository.dart';
import '../features/records/viewmodel/records_view_model.dart';
import '../features/settings/data/goals_repository.dart';
import '../features/settings/viewmodel/goals_view_model.dart';

/// Composition root: the only place that knows about every layer.
///
/// Opens the database, builds the repositories, creates the shared view-models
/// and loads their first data before any screen is shown.
class AppServices {
  AppServices._({required this.database, required this.records, required this.goals, required this.dashboard});

  final Database database;
  final RecordsViewModel records;
  final GoalsViewModel goals;
  final DashboardViewModel dashboard;

  static Future<AppServices> start({Future<Database> Function()? openDatabase}) async {
    final db = await (openDatabase ?? AppDatabase.open)();

    final records = RecordsViewModel(HealthRecordRepository(db));
    final goals = GoalsViewModel(GoalsRepository(db));
    final dashboard = DashboardViewModel(SummaryRepository(db), records, goals);

    await Future.wait([records.load(), goals.load(), dashboard.load()]);
    if (records.error != null) throw StateError(records.error!);

    return AppServices._(database: db, records: records, goals: goals, dashboard: dashboard);
  }
}
