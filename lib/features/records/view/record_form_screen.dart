import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/icon_circle.dart';
import '../model/health_record.dart';
import '../model/record_validation.dart';
import '../viewmodel/record_form_view_model.dart';
import 'widgets/date_field.dart';

const Map<MetricKey, String> _placeholders = {
  MetricKey.steps: 'e.g. 7850',
  MetricKey.calories: 'e.g. 420',
  MetricKey.water: 'e.g. 2000',
};

/// Add Record (no id) and Edit Record screen. Expects a [RecordFormViewModel] above it.
class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({super.key});

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final Map<MetricKey, TextEditingController> _controllers = {
    for (final key in MetricKey.values) key: TextEditingController(),
  };
  bool _filled = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Copies the loaded record into the text fields once (edit mode).
  void _fillOnce(RecordFormViewModel vm) {
    if (_filled || vm.loadState != FormLoadState.ready) return;
    _filled = true;
    for (final key in MetricKey.values) {
      _controllers[key]!.text = vm.values.metric(key);
    }
  }

  Future<void> _pickDate(RecordFormViewModel vm) async {
    final today = parseIsoDate(vm.today);
    final current = isValidIsoDate(vm.values.date) ? parseIsoDate(vm.values.date) : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isAfter(today) ? today : current,
      firstDate: DateTime(2000),
      lastDate: today,
      helpText: 'Record date',
    );
    if (picked != null) vm.setDate(toIsoDate(picked));
  }

  Future<void> _submit(RecordFormViewModel vm) async {
    FocusScope.of(context).unfocus();
    final saved = await vm.submit();
    if (!saved || !mounted) return;
    // The opening screen shows this text in its own SnackBar (see openRecordForm).
    Navigator.of(context).pop(vm.isEdit ? 'Changes saved' : 'Record added');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RecordFormViewModel>();
    final text = Theme.of(context).textTheme;
    _fillOnce(vm);

    final appBar = AppBar(
      title: Text(vm.isEdit ? 'Edit Record' : 'Add Record'),
      leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
    );

    if (vm.loadState == FormLoadState.loading) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.loadState == FormLoadState.notFound) {
      return Scaffold(
        appBar: appBar,
        body: EmptyState(
          icon: Icons.help_outline,
          title: 'Record not found',
          description: 'It may have been deleted. Go back to the list to see your current records.',
          action: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to records')),
        ),
      );
    }

    final date = vm.values.date;
    final formError = vm.errorFor(RecordFormField.form);

    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                vm.isEdit
                    ? 'Update the values below and save your changes.'
                    : 'Log what you did today. Leave a field empty if you did not track it.',
                style: text.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              decoration: cardDecoration(),
              child: Column(
                children: [
                  DateField(
                    label: 'Date',
                    value: isValidIsoDate(date) ? formatLongDate(date) : date,
                    errorText: vm.errorFor(RecordFormField.date),
                    onTap: () => _pickDate(vm),
                  ),
                  const SizedBox(height: 16),
                  for (final key in MetricKey.values)
                    _MetricField(
                      metric: key,
                      controller: _controllers[key]!,
                      errorText: vm.errorFor(fieldOf(key)),
                      onChanged: (value) => vm.setMetric(key, value),
                    ),
                ],
              ),
            ),
            if (formError != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 20, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(formError, style: text.bodyMedium?.copyWith(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: vm.saving ? null : () => _submit(vm),
                icon: vm.saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(vm.isEdit ? 'Save changes' : 'Save record'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: vm.saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }
}

class _MetricField extends StatelessWidget {
  const _MetricField({required this.metric, required this.controller, required this.onChanged, this.errorText});

  final MetricKey metric;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final style = metricStyles[metric]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: IconCircle(icon: style.icon, color: style.color, background: style.container),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: ValueKey('field-${metric.name}'),
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              textInputAction: metric == MetricKey.water ? TextInputAction.done : TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(7)],
              decoration: InputDecoration(
                labelText: style.label,
                hintText: _placeholders[metric],
                suffixText: style.unit,
                errorText: errorText,
                errorMaxLines: 2,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: style.color, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
