import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/dashboard/data/summary_repository.dart';
import 'package:healthmate/features/dashboard/viewmodel/dashboard_view_model.dart';
import 'package:healthmate/features/records/data/health_record_repository.dart';
import 'package:healthmate/features/records/model/health_record.dart';
import 'package:healthmate/features/records/viewmodel/records_view_model.dart';
import 'package:healthmate/features/settings/data/goals_repository.dart';
import 'package:healthmate/features/settings/viewmodel/goals_view_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_database.dart';

void main() {
  setUpAll(initTestDatabaseFactory);

  late Database db;
  late HealthRecordRepository records;
  late SummaryRepository summary;

  setUp(() async {
    db = await openTestDatabase(seeded: false);
    records = HealthRecordRepository(db);
    summary = SummaryRepository(db);
  });

  tearDown(() => db.close());

  group('SummaryRepository', () {
    test("sums every entry logged for a day (today's total water intake)", () async {
      await records.create(const HealthRecordInput(date: testToday, steps: 5000, calories: 300, water: 1500));
      await records.create(const HealthRecordInput(date: testToday, steps: 2850, calories: 120, water: 500));
      await records.create(const HealthRecordInput(date: '2026-11-06', steps: 9999, water: 9999));

      final totals = await summary.getDailyTotals(testToday);
      expect((totals.steps, totals.calories, totals.water, totals.entries), (7850, 420, 2000, 2));
    });

    test('returns zeros for a day with no records', () async {
      final totals = await summary.getDailyTotals(testToday);
      expect((totals.steps, totals.calories, totals.water, totals.entries), (0, 0, 0, 0));
    });

    test('returns one row per day for the week, zero-filling missing days', () async {
      await records.create(const HealthRecordInput(date: '2026-11-01', steps: 1000));
      await records.create(const HealthRecordInput(date: '2026-11-04', steps: 400));
      await records.create(const HealthRecordInput(date: '2026-11-04', steps: 600));
      await records.create(const HealthRecordInput(date: '2026-11-07', steps: 7850));

      final week = await summary.getTotalsBetween('2026-11-01', '2026-11-07');
      expect(week.map((d) => d.date), [
        '2026-11-01',
        '2026-11-02',
        '2026-11-03',
        '2026-11-04',
        '2026-11-05',
        '2026-11-06',
        '2026-11-07',
      ]);
      expect(week.map((d) => d.steps), [1000, 0, 0, 1000, 0, 0, 7850]);
      expect(week[3].entries, 2);
    });
  });

  group('DashboardViewModel', () {
    test('computes goal progress, daily score and goals reached from the seed data', () async {
      final seeded = await openTestDatabase();
      final recordsVm = RecordsViewModel(HealthRecordRepository(seeded), today: () => testToday);
      final goalsVm = GoalsViewModel(GoalsRepository(seeded));
      await goalsVm.load();
      final vm = DashboardViewModel(
        SummaryRepository(seeded),
        recordsVm,
        goalsVm,
        today: () => testToday,
        now: () => DateTime(2026, 11, 7, 19),
      );
      await vm.load();

      expect(vm.metrics.map((m) => m.percent), [79, 84, 80]);
      expect(vm.score, 81);
      expect(vm.goalsMet, 0);
      expect(vm.greeting, 'Good evening');
      expect(vm.todayLabel, 'Saturday, 7 November 2026');
      expect(vm.chart, hasLength(7));
      expect(vm.chart.last.isToday, isTrue);
      vm.dispose();
      await seeded.close();
    });

    test('reloads automatically after any record write (quick-add water)', () async {
      final recordsVm = RecordsViewModel(records, today: () => testToday);
      final goalsVm = GoalsViewModel(GoalsRepository(db));
      final vm = DashboardViewModel(summary, recordsVm, goalsVm, today: () => testToday);
      await vm.load();
      expect(vm.water.value, 0);

      final message = await vm.quickAddWater(500);
      expect(message, 'Added 500 ml of water');
      // The dashboard reloads in response to the records revision change.
      await Future<void>.delayed(Duration.zero);
      await pumpEventQueue();
      expect(vm.water.value, 500);
      expect(vm.water.percent, 20);
      vm.dispose();
    });
  });
}
