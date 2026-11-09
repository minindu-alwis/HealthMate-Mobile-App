import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/date_utils.dart';
import 'package:healthmate/core/utils/number_utils.dart';

void main() {
  group('date utils', () {
    test('uses the local calendar day, not UTC (no off-by-one just after midnight)', () {
      // 00:15 local time on 8 Nov. In Sri Lanka (UTC+5:30) this is still 7 Nov in UTC,
      // so a UTC-based conversion would return the previous day.
      final justAfterMidnight = DateTime(2026, 11, 8, 0, 15);
      expect(toIsoDate(justAfterMidnight), '2026-11-08');
      expect(toIsoDate(DateTime(2026, 11, 7, 23, 59)), '2026-11-07');
      expect(todayIso(), toIsoDate(DateTime.now()));
    });

    test('rejects impossible calendar dates and accepts leap days', () {
      expect(isValidIsoDate('2026-11-07'), isTrue);
      expect(isValidIsoDate('2028-02-29'), isTrue);
      expect(isValidIsoDate('2026-02-29'), isFalse);
      expect(isValidIsoDate('2026-13-01'), isFalse);
      expect(isValidIsoDate('7/11/2026'), isFalse);
      expect(isValidIsoDate(''), isFalse);
      expect(() => parseIsoDate('2026-02-30'), throwsFormatException);
    });

    test('adds days across month and year boundaries', () {
      expect(addDays('2026-10-31', 1), '2026-11-01');
      expect(addDays('2026-12-31', 1), '2027-01-01');
      expect(addDays('2026-03-01', -1), '2026-02-28');
      expect(addDays('2026-11-07', -6), '2026-11-01');
    });

    test('builds an inclusive day range', () {
      expect(dateRange('2026-10-30', '2026-11-02'), ['2026-10-30', '2026-10-31', '2026-11-01', '2026-11-02']);
      expect(dateRange('2026-11-07', '2026-11-07'), ['2026-11-07']);
    });

    test('formats dates like the brief example', () {
      expect(formatLongDate('2026-11-07'), 'Saturday, 7 November 2026');
      expect(formatShortDate('2026-11-07'), 'Sat, 7 Nov 2026');
      expect(formatWeekday('2026-11-09'), 'Mon');
      expect(formatMonthAbbr('2026-08-18'), 'AUG');
    });
  });

  group('number utils', () {
    test('formats thousands with commas', () {
      expect(formatNumber(7850), '7,850');
      expect(formatNumber(100000), '100,000');
      expect(formatNumber(420), '420');
      expect(formatNumber(7381.4), '7,381');
    });

    test('percentOf rounds and clamps to 0..100', () {
      expect(percentOf(7850, 10000), 79);
      expect(percentOf(3000, 2500), 100);
      expect(percentOf(0, 500), 0);
      expect(percentOf(10, 0), 0);
    });
  });
}
