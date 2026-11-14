import '../../features/records/model/health_record.dart';
import '../utils/date_utils.dart';

/// Hand-picked dummy values for the 13 days before today, oldest first:
/// (steps, calories, water). Fixed numbers (not random) so screenshots and test
/// evidence are reproducible.
const List<(int, int, int)> _pastDays = [
  (6120, 310, 1750),
  (9480, 515, 2400),
  (4300, 240, 1500),
  (11250, 630, 2750),
  (8020, 455, 2200),
  (3150, 180, 1250),
  (12400, 690, 3000),
  (7600, 410, 2100),
  (5480, 300, 1800),
  (10120, 560, 2600),
  (6890, 380, 1900),
  (9010, 500, 2300),
  (4720, 260, 1600),
];

/// 14 days of dummy records ending on [today]. Today's values match the example
/// in the coursework brief (7,850 steps, 420 kcal, 2,000 ml).
List<HealthRecordInput> buildSampleRecords(String today) {
  final records = <HealthRecordInput>[
    for (var i = 0; i < _pastDays.length; i++)
      HealthRecordInput(
        date: addDays(today, i - _pastDays.length),
        steps: _pastDays[i].$1,
        calories: _pastDays[i].$2,
        water: _pastDays[i].$3,
      ),
  ];
  records.add(HealthRecordInput(date: today, steps: 7850, calories: 420, water: 2000));
  return records;
}
