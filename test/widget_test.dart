import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/records/data/health_record_repository.dart';
import 'package:healthmate/features/records/view/record_form_screen.dart';
import 'package:healthmate/features/records/view/record_list_screen.dart';
import 'package:healthmate/features/records/viewmodel/record_form_view_model.dart';
import 'package:healthmate/features/records/viewmodel/records_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_database.dart';

void main() {
  setUpAll(initTestDatabaseFactory);

  /// Real database work must run outside the widget test's fake-async zone.
  Future<(Database, RecordsViewModel)> openRecords(WidgetTester tester) async {
    final result = await tester.runAsync(() async {
      final db = await openTestDatabase();
      final vm = RecordsViewModel(HealthRecordRepository(db), today: () => testToday);
      await vm.load();
      return (db, vm);
    });
    return result!;
  }

  testWidgets('Add Record shows the inline error when the form is submitted empty', (tester) async {
    final (db, records) = await openRecords(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ChangeNotifierProvider(
          create: (_) => RecordFormViewModel(records, today: () => testToday),
          child: const RecordFormScreen(),
        ),
      ),
    );

    expect(find.text('Add Record'), findsOneWidget);
    expect(find.text('Saturday, 7 November 2026'), findsOneWidget);

    await tester.tap(find.text('Save record'));
    await tester.pump();
    expect(find.text('Enter at least one value: steps, calories or water'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('field-steps')), '-5');
    await tester.enterText(find.byKey(const ValueKey('field-calories')), '12.5');
    await tester.pump();
    expect(find.text('Steps cannot be negative'), findsOneWidget);
    expect(find.text('Calories must be a whole number'), findsOneWidget);
    expect(find.text('Enter at least one value: steps, calories or water'), findsNothing);
    expect(records.revision, 0, reason: 'nothing may be saved while the form is invalid');

    await tester.runAsync(db.close);
  });

  testWidgets('Records list shows the seeded entries with a TODAY badge and asks before deleting', (tester) async {
    final (db, records) = await openRecords(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ChangeNotifierProvider.value(value: records, child: const RecordListScreen()),
      ),
    );

    expect(find.text('Records'), findsOneWidget);
    expect(find.text('14 entries · newest first'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('7,850'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete record for Sat, 7 Nov 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this record?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this record?'), findsNothing);
    expect(records.records, hasLength(14));

    await tester.runAsync(db.close);
  });
}
