/// Dates are stored as ISO `YYYY-MM-DD` text in the user's local time zone.
///
/// `DateTime.toUtc()` / `toIso8601String()` on a UTC value are deliberately
/// avoided because converting to UTC shifts the day for users east of
/// Greenwich (e.g. Sri Lanka, UTC+5:30) between midnight and 05:30.
library;

final RegExp _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

const List<String> _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _two(int value) => value.toString().padLeft(2, '0');

/// Local calendar day of [date] as `YYYY-MM-DD`.
String toIsoDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${_two(date.month)}-${_two(date.day)}';

/// Today's local date as `YYYY-MM-DD`.
String todayIso() => toIsoDate(DateTime.now());

/// True only for real calendar dates in `YYYY-MM-DD` form (rejects 2026-02-30).
bool isValidIsoDate(String value) {
  final match = _isoDate.firstMatch(value);
  if (match == null) return false;
  final y = int.parse(match.group(1)!);
  final m = int.parse(match.group(2)!);
  final d = int.parse(match.group(3)!);
  final date = DateTime(y, m, d);
  return date.year == y && date.month == m && date.day == d;
}

/// Parses `YYYY-MM-DD` as local midnight. Throws [FormatException] on invalid input.
DateTime parseIsoDate(String value) {
  if (!isValidIsoDate(value)) {
    throw FormatException('Invalid date: $value');
  }
  final parts = value.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

/// Adds whole calendar days. Uses the DateTime constructor (not Duration) so a
/// daylight-saving change can never skip or repeat a day.
String addDays(String isoDate, int days) {
  final date = parseIsoDate(isoDate);
  return toIsoDate(DateTime(date.year, date.month, date.day + days));
}

/// "Saturday, 7 November 2026"
String formatLongDate(String isoDate) {
  final date = parseIsoDate(isoDate);
  return '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year}';
}

/// "Sat, 7 Nov 2026"
String formatShortDate(String isoDate) {
  final date = parseIsoDate(isoDate);
  return '${_weekdays[date.weekday - 1].substring(0, 3)}, ${date.day} '
      '${_months[date.month - 1].substring(0, 3)} ${date.year}';
}

/// "Sat"
String formatWeekday(String isoDate) => _weekdays[parseIsoDate(isoDate).weekday - 1].substring(0, 3);

/// "NOV"
String formatMonthAbbr(String isoDate) => _months[parseIsoDate(isoDate).month - 1].substring(0, 3).toUpperCase();

/// Inclusive list of ISO dates from [from] to [to].
List<String> dateRange(String from, String to) {
  final days = <String>[];
  for (var day = from; day.compareTo(to) <= 0; day = addDays(day, 1)) {
    days.add(day);
  }
  return days;
}
