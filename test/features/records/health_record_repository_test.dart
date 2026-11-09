import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/records/data/health_record_repository.dart';
import 'package:healthmate/features/records/model/health_record.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_database.dart';

void main() {
  setUpAll(initTestDatabaseFactory);

  late Database db;
  late HealthRecordRepository repo;

  setUp(() async {
    db = await openTestDatabase(seeded: false);
    repo = HealthRecordRepository(db);
  });

  tearDown(() => db.close());

  group('HealthRecordRepository', () {
    test('creates a record and reads it back by id', () async {
      final created = await repo.create(
        const HealthRecordInput(date: '2026-11-07', steps: 7850, calories: 420, water: 2000),
      );
      expect(created.id, greaterThan(0));
      expect(await repo.findById(created.id), created);
      expect(await repo.findById(9999), isNull);
    });

    test('updates every field of an existing record', () async {
      final created = await repo.create(const HealthRecordInput(date: '2026-11-06', steps: 100));
      const changed = HealthRecordInput(date: '2026-11-05', steps: 5000, calories: 250, water: 1500);
      final updated = await repo.update(created.id, changed);
      expect(updated, HealthRecord.fromInput(created.id, changed));
      expect(await repo.findById(created.id), updated);
    });

    test('throws RecordNotFoundException when updating or deleting a missing id', () async {
      expect(
        () => repo.update(404, const HealthRecordInput(date: '2026-11-07', steps: 1)),
        throwsA(isA<RecordNotFoundException>()),
      );
      expect(() => repo.remove(404), throwsA(isA<RecordNotFoundException>()));
    });

    test('deletes a record and restores it with the same id (undo)', () async {
      final record = await repo.create(const HealthRecordInput(date: '2026-11-07', water: 750));
      await repo.remove(record.id);
      expect(await repo.findById(record.id), isNull);

      await repo.restore(record);
      expect(await repo.findById(record.id), record);
    });

    test('filters by a single date', () async {
      await repo.create(const HealthRecordInput(date: '2026-11-05', steps: 1));
      await repo.create(const HealthRecordInput(date: '2026-11-06', steps: 2));
      await repo.create(const HealthRecordInput(date: '2026-11-06', steps: 3));

      final day = await repo.findAll(filter: const SingleDay('2026-11-06'));
      expect(day.map((r) => r.steps), [3, 2]);
      expect(await repo.findAll(filter: const SingleDay('2026-01-01')), isEmpty);
    });

    test('filters by an inclusive date range', () async {
      for (final date in ['2026-10-31', '2026-11-01', '2026-11-04', '2026-11-07', '2026-11-08']) {
        await repo.create(HealthRecordInput(date: date, steps: 1));
      }
      final range = await repo.findAll(filter: const DateSpan('2026-11-01', '2026-11-07'));
      expect(range.map((r) => r.date), ['2026-11-07', '2026-11-04', '2026-11-01']);
    });

    test('sorts newest-first by date, then by id for entries on the same day', () async {
      final a = await repo.create(const HealthRecordInput(date: '2026-11-06', steps: 1));
      final b = await repo.create(const HealthRecordInput(date: '2026-11-07', steps: 2));
      final c = await repo.create(const HealthRecordInput(date: '2026-11-06', steps: 3));

      expect((await repo.findAll()).map((r) => r.id), [b.id, c.id, a.id]);
      expect((await repo.findAll(sort: SortOrder.oldest)).map((r) => r.id), [a.id, c.id, b.id]);
    });

    test('quick-add water increments the latest entry of the day', () async {
      await repo.create(const HealthRecordInput(date: '2026-11-07', steps: 100, water: 500));
      final latest = await repo.create(const HealthRecordInput(date: '2026-11-07', steps: 200, water: 1000));

      final updated = await repo.addWater('2026-11-07', 250);
      expect(updated.id, latest.id);
      expect(updated.water, 1250);
      expect(updated.steps, 200);
      expect(await repo.findAll(), hasLength(2));
    });

    test('quick-add water creates an entry when the day has none', () async {
      final created = await repo.addWater('2026-11-07', 500);
      expect(created, HealthRecord(id: created.id, date: '2026-11-07', water: 500));
      expect(await repo.findAll(), hasLength(1));
    });

    test('rejects negative values at the database level (CHECK constraint)', () async {
      await expectLater(
        db.rawInsert('INSERT INTO health_records (date, steps, calories, water) VALUES (?, ?, ?, ?)', [
          '2026-11-07',
          -1,
          0,
          0,
        ]),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        repo.create(const HealthRecordInput(date: '2026-11-07', water: -250)),
        throwsA(isA<DatabaseException>()),
      );
      expect(await repo.findAll(), isEmpty);
    });

    test('removes everything, then replaces it with the 14-day sample set', () async {
      await repo.create(const HealthRecordInput(date: '2026-11-07', steps: 1));
      await repo.removeAll();
      expect(await repo.findAll(), isEmpty);

      await repo.replaceWithSampleData('2026-11-07');
      final all = await repo.findAll();
      expect(all, hasLength(14));
      expect(all.first.date, '2026-11-07');
      expect(all.first.steps, 7850);
      expect(all.last.date, '2026-10-25');
    });
  });
}
