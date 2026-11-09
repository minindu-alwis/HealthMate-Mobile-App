import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/records/model/health_record.dart';
import 'package:healthmate/features/settings/data/goals_repository.dart';
import 'package:healthmate/features/settings/model/goals.dart';
import 'package:healthmate/features/settings/viewmodel/goals_view_model.dart';

import '../../helpers/test_database.dart';

Map<MetricKey, String> goalValues(String steps, String calories, String water) => {
  MetricKey.steps: steps,
  MetricKey.calories: calories,
  MetricKey.water: water,
};

void main() {
  setUpAll(initTestDatabaseFactory);

  group('validateGoals', () {
    test('accepts whole numbers within the limits, including separators', () {
      final result = validateGoals(goalValues('12,000', '600', '3000'));
      expect(result.isValid, isTrue);
      expect(result.data, const DailyGoals(steps: 12000, calories: 600, water: 3000));
    });

    test('rejects zero, blanks, decimals and values over the limit with the same message', () {
      final result = validateGoals(goalValues('0', '', '10001'));
      expect(result.errors, {
        MetricKey.steps: 'Enter a whole number from 1 to 100,000',
        MetricKey.calories: 'Enter a whole number from 1 to 10,000',
        MetricKey.water: 'Enter a whole number from 1 to 10,000',
      });
      expect(validateGoals(goalValues('1.5', '500', '2500')).errors.keys, [MetricKey.steps]);
    });
  });

  group('GoalsRepository', () {
    test('returns the defaults and saves new goals in one transaction', () async {
      final db = await openTestDatabase();
      final repo = GoalsRepository(db);
      expect(await repo.getGoals(), DailyGoals.defaults);

      const updated = DailyGoals(steps: 8000, calories: 450, water: 3000);
      await repo.saveGoals(updated);
      expect(await repo.getGoals(), updated);
      await db.close();
    });

    test('GoalsViewModel notifies listeners after saving', () async {
      final db = await openTestDatabase();
      final vm = GoalsViewModel(GoalsRepository(db));
      await vm.load();
      var notified = 0;
      vm.addListener(() => notified++);

      await vm.save(const DailyGoals(steps: 5000, calories: 300, water: 2000));
      expect(vm.goals.steps, 5000);
      expect(notified, 1);
      await db.close();
    });
  });
}
