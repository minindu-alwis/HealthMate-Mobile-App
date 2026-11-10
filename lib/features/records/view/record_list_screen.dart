import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/large_header.dart';
import '../model/health_record.dart';
import '../viewmodel/records_view_model.dart';
import 'widgets/date_filter_bar.dart';
import 'widgets/record_card.dart';

class RecordListScreen extends StatelessWidget {
  const RecordListScreen({super.key});

  Future<void> _delete(BuildContext context, RecordsViewModel vm, HealthRecord record) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete this record?',
      message: 'The record for ${formatShortDate(record.date)} will be removed. You can undo straight after.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final message = await vm.deleteWithUndo(record);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: vm.canUndo
            ? SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  final error = await vm.undoDelete();
                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                  }
                },
              )
            : null,
      ),
    );
    controller.closed.then((reason) {
      if (reason != SnackBarClosedReason.action) vm.clearUndo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecordsViewModel>();
    final count = vm.records.length;
    final today = vm.today;

    // Dark status-bar icons. Without this region the light icons set by the
    // dashboard would stay active after switching tabs.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: darkStatusBar,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LargeHeader(
                title: 'Records',
                subtitle:
                    '$count ${count == 1 ? 'entry' : 'entries'} · '
                    '${vm.sort == SortOrder.newest ? 'newest first' : 'oldest first'}',
              ),
              DateFilterBar(vm: vm),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: ErrorBanner(message: vm.error!, onRetry: vm.load),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: vm.load,
                  child: vm.records.isEmpty
                      ? ListView(
                          // Keeps pull-to-refresh working on an empty list.
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [if (vm.status == LoadStatus.ready) _EmptyRecords(vm: vm)],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, bottom: 104),
                          itemCount: count,
                          itemBuilder: (context, index) {
                            final record = vm.records[index];
                            return RecordCard(
                              key: ValueKey(record.id),
                              record: record,
                              isToday: record.date == today,
                              onEdit: () => openRecordForm(context, recordId: record.id),
                              onDelete: () => _delete(context, vm, record),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'records-fab',
          tooltip: 'Add new record',
          onPressed: () => openRecordForm(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords({required this.vm});

  final RecordsViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.isFiltered) {
      return EmptyState(
        icon: Icons.event_busy,
        title: 'No records for this date',
        description: 'Try another date or clear the filter to see every record.',
        action: TextButton(onPressed: vm.showAll, child: const Text('Show all records')),
      );
    }
    return EmptyState(
      icon: Icons.assignment_outlined,
      title: 'No health records yet',
      description: 'Add your steps, calories and water for today to get started.',
      action: FilledButton(onPressed: () => openRecordForm(context), child: const Text('Add first record')),
    );
  }
}
