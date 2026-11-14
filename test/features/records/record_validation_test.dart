import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/records/model/health_record.dart';
import 'package:healthmate/features/records/model/record_validation.dart';

const today = '2026-11-07';

RecordValidationResult validate({String date = today, String steps = '', String calories = '', String water = ''}) =>
    validateRecordForm(RecordFormValues(date: date, steps: steps, calories: calories, water: water), today);

void main() {
  group('validateRecordForm', () {
    test('accepts a complete record and converts text to integers', () {
      final result = validate(steps: '7850', calories: '420', water: '2000');
      expect(result.isValid, isTrue);
      expect(result.data, const HealthRecordInput(date: today, steps: 7850, calories: 420, water: 2000));
    });

    test('treats empty fields as 0 and accepts thousands separators', () {
      final result = validate(steps: ' 7,850 ', water: '');
      expect(result.isValid, isTrue);
      expect(result.data, const HealthRecordInput(date: today, steps: 7850));
    });

    test('rejects a record where every value is empty or zero', () {
      for (final values in [validate(), validate(steps: '0', calories: '0', water: '0')]) {
        expect(values.isValid, isFalse);
        expect(values.errors, {RecordFormField.form: 'Enter at least one value: steps, calories or water'});
      }
    });

    test('requires a date', () {
      expect(validate(date: '  ', steps: '1').errors[RecordFormField.date], 'Date is required');
    });

    test('rejects a malformed or impossible date', () {
      const message = 'Date must be a valid date (YYYY-MM-DD)';
      expect(validate(date: '07/11/2026', steps: '1').errors[RecordFormField.date], message);
      expect(validate(date: '2026-02-30', steps: '1').errors[RecordFormField.date], message);
    });

    test('rejects a date in the future but accepts today and the past', () {
      expect(validate(date: '2026-11-08', steps: '1').errors[RecordFormField.date], 'Date cannot be in the future');
      expect(validate(date: today, steps: '1').isValid, isTrue);
      expect(validate(date: '2025-01-01', steps: '1').isValid, isTrue);
    });

    test('rejects negative numbers', () {
      expect(validate(steps: '-5').errors[RecordFormField.steps], 'Steps cannot be negative');
    });

    test('rejects decimals and text', () {
      expect(validate(calories: '12.5').errors[RecordFormField.calories], 'Calories must be a whole number');
      expect(validate(water: 'abc').errors[RecordFormField.water], 'Water intake must be a whole number');
    });

    test('rejects values above the limits with the formatted maximum', () {
      expect(validate(steps: '100001').errors[RecordFormField.steps], 'Steps must be between 0 and 100,000');
      expect(validate(calories: '10001').errors[RecordFormField.calories], 'Calories must be between 0 and 10,000');
      expect(validate(water: '20000').errors[RecordFormField.water], 'Water intake must be between 0 and 10,000');
    });

    test('accepts values exactly at the upper limits', () {
      final result = validate(steps: '100000', calories: '10000', water: '10,000');
      expect(result.isValid, isTrue);
      expect(result.data, const HealthRecordInput(date: today, steps: 100000, calories: 10000, water: 10000));
    });

    test('reports every invalid field at once, not just the first', () {
      final result = validate(date: '2026-12-01', steps: '-5', calories: '12.5', water: '20000');
      expect(
        result.errors.keys,
        containsAll([RecordFormField.date, RecordFormField.steps, RecordFormField.calories, RecordFormField.water]),
      );
      // The "at least one value" message is only added when the numbers themselves are valid.
      expect(result.errors.containsKey(RecordFormField.form), isFalse);
    });
  });
}
