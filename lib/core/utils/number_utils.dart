import 'package:intl/intl.dart';

final NumberFormat _grouped = NumberFormat('#,##0', 'en_US');

/// Formats an integer with thousands separators: 7850 -> "7,850".
String formatNumber(num value) => _grouped.format(value.round());

/// Percentage of [value] against [goal], rounded and clamped to 0..100.
int percentOf(num value, num goal) {
  if (goal <= 0) return 0;
  return ((value / goal) * 100).round().clamp(0, 100);
}
