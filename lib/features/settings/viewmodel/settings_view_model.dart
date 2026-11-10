import '../../../core/utils/date_utils.dart';
import '../../../core/utils/errors.dart';
import '../../../core/viewmodel/safe_change_notifier.dart';
import '../../records/model/health_record.dart';
import '../../records/viewmodel/records_view_model.dart';
import '../model/goals.dart';
import 'goals_view_model.dart';

/// The two destructive actions on the DATA card. Both are confirmed first.
enum DataAction { deleteAll, reloadSamples }

/// Form state for the Settings screen.
class SettingsViewModel extends SafeChangeNotifier {
  SettingsViewModel(this._goals, this._records, {this._today = todayIso})
    : _values = {for (final key in MetricKey.values) key: '${_goals.goals.of(key)}'};

  final GoalsViewModel _goals;
  final RecordsViewModel _records;
  final String Function() _today;

  final Map<MetricKey, String> _values;
  Map<MetricKey, String> _errors = const {};
  bool _busy = false;

  String valueOf(MetricKey key) => _values[key] ?? '';
  String? errorFor(MetricKey key) => _errors[key];
  bool get busy => _busy;

  void setGoal(MetricKey key, String text) {
    _values[key] = text;
    notifyListeners();
  }

  /// Validates and saves the goals. Returns the SnackBar text, or null when the
  /// form has errors (they are shown inline instead).
  Future<String?> save() async {
    final result = validateGoals(_values);
    if (!result.isValid) {
      _errors = result.errors;
      notifyListeners();
      return null;
    }
    _errors = const {};
    return _run(() async {
      await _goals.save(result.data!);
      return 'Daily goals saved';
    });
  }

  /// Runs a confirmed DATA action. Returns the SnackBar text.
  Future<String> perform(DataAction action) async {
    final message = await _run(() async {
      switch (action) {
        case DataAction.deleteAll:
          await _records.removeAll();
          return 'All records deleted';
        case DataAction.reloadSamples:
          await _records.replaceWithSampleData(_today());
          return 'Sample data reloaded (14 days)';
      }
    });
    return message;
  }

  Future<String> _run(Future<String> Function() task) async {
    _busy = true;
    notifyListeners();
    try {
      return await task();
    } catch (e) {
      return errorMessage(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
