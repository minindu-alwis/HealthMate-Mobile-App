import '../../../core/utils/date_utils.dart';
import '../../../core/utils/errors.dart';
import '../../../core/viewmodel/safe_change_notifier.dart';
import '../model/health_record.dart';
import '../model/record_validation.dart';
import 'records_view_model.dart';

enum FormLoadState { loading, ready, notFound }

/// Drives both "Add Record" ([recordId] == null) and "Edit Record".
///
/// Errors appear after the first submit attempt and are then re-validated on
/// every keystroke, so the user sees a message disappear as soon as it is fixed.
class RecordFormViewModel extends SafeChangeNotifier {
  RecordFormViewModel(this._records, {this.recordId, String Function() today = todayIso})
    : _today = today,
      _values = RecordFormValues(date: today()),
      _loadState = recordId == null ? FormLoadState.ready : FormLoadState.loading;

  final RecordsViewModel _records;
  final String Function() _today;

  /// Null for a new record. A malformed id from a route is passed as -1.
  final int? recordId;

  RecordFormValues _values;
  FormLoadState _loadState;
  RecordFormErrors _errors = const {};
  bool _submitted = false;
  bool _saving = false;

  bool get isEdit => recordId != null;
  FormLoadState get loadState => _loadState;
  RecordFormValues get values => _values;
  RecordFormErrors get errors => _errors;
  bool get saving => _saving;
  String get today => _today();

  String? errorFor(RecordFormField field) => _errors[field];

  /// Loads the record being edited. Does nothing for a new record.
  Future<void> init() async {
    final id = recordId;
    if (id == null) return;
    try {
      final record = id > 0 ? await _records.getById(id) : null;
      if (record == null) {
        _loadState = FormLoadState.notFound;
      } else {
        _values = RecordFormValues.fromRecord(record);
        _loadState = FormLoadState.ready;
      }
    } catch (e) {
      _errors = {RecordFormField.form: errorMessage(e)};
      _loadState = FormLoadState.ready;
    }
    notifyListeners();
  }

  void setDate(String isoDate) => _setValues(_values.copyWith(date: isoDate));

  void setMetric(MetricKey key, String text) => _setValues(_values.withMetric(key, text));

  void _setValues(RecordFormValues next) {
    _values = next;
    if (_submitted) {
      _errors = validateRecordForm(next, _today()).errors;
    }
    notifyListeners();
  }

  /// Validates and saves. Returns true when the record was written.
  Future<bool> submit() async {
    if (_saving) return false;
    _submitted = true;
    final result = validateRecordForm(_values, _today());
    if (!result.isValid) {
      _errors = result.errors;
      notifyListeners();
      return false;
    }
    _errors = const {};
    _saving = true;
    notifyListeners();
    try {
      final id = recordId;
      if (id == null) {
        await _records.create(result.data!);
      } else {
        await _records.update(id, result.data!);
      }
      return true;
    } catch (e) {
      _errors = {RecordFormField.form: errorMessage(e)};
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
