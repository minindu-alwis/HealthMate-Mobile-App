import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/records/data/health_record_repository.dart';
import 'package:healthmate/features/records/model/health_record.dart';
import 'package:healthmate/features/records/viewmodel/records_view_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_database.dart';

/// A repository whose reads always fail, to check the error state.
class _FailingRepository extends HealthRecordRepository {
  _FailingRepository(super.db);

  @override
  Future<List<HealthRecord>> findAll({DateFilter filter = const AllDates(), SortOrder sort = SortOrder.newest}) =>
      Future.error(Exception('disk I/O error'));
}

void main() {
  setUpAll(initTestDatabaseFactory);

  late Database db;
  late RecordsViewModel vm;

  setUp(() async {
    db = await openTestDatabase();
    vm = RecordsViewModel(HealthRecordRepository(db), today: () => testToday);
  });

  tearDown(() => db.close());

  group('RecordsViewModel', () {
    test('loads the seeded records newest first', () async {
      await vm.load();
      expect(vm.status, LoadStatus.ready);
      expect(vm.records, hasLength(14));
      expect(vm.records.first.date, testToday);
      expect(vm.filterLabel, 'Showing all records');
    });

    test('keeps the active date filter applied after a create and bumps the revision', () async {
      await vm.showToday();
      expect(vm.activePreset, FilterPreset.today);
      expect(vm.records, hasLength(1));

      await vm.create(const HealthRecordInput(date: testToday, steps: 1200));
      await vm.create(const HealthRecordInput(date: '2026-11-01', steps: 300));
      expect(vm.records, hasLength(2));
      expect(vm.records.every((r) => r.date == testToday), isTrue);
      expect(vm.revision, 2);
    });

    test('maps the last-7-days chip and range label', () async {
      await vm.showLastWeek();
      expect(vm.activePreset, FilterPreset.week);
      expect(vm.records, hasLength(7));
      expect(vm.filterLabel, 'Showing Sun, 1 Nov 2026 – Sat, 7 Nov 2026');

      await vm.showRange('2026-10-25', '2026-10-27');
      expect(vm.activePreset, FilterPreset.range);
      expect(vm.records, hasLength(3));
    });

    test('removes a record and brings it back with the same id on undo', () async {
      await vm.load();
      final record = vm.records.first;

      final message = await vm.deleteWithUndo(record);
      expect(message, 'Record for Sat, 7 Nov 2026 deleted');
      expect(vm.canUndo, isTrue);
      expect(vm.records.any((r) => r.id == record.id), isFalse);

      expect(await vm.undoDelete(), isNull);
      expect(vm.records.first, record);
      expect(vm.canUndo, isFalse);
    });

    test('surfaces a load failure as an error state instead of crashing', () async {
      final failing = RecordsViewModel(_FailingRepository(db));
      await failing.load();
      expect(failing.status, LoadStatus.error);
      expect(failing.error, 'Something went wrong. Please try again.');
      expect(failing.records, isEmpty);
    });
  });
}
