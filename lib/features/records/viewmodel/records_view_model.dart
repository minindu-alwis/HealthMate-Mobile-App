import '../../../core/utils/date_utils.dart';
import '../../../core/utils/errors.dart';
import '../../../core/viewmodel/safe_change_notifier.dart';
import '../data/health_record_repository.dart';
import '../model/health_record.dart';

enum LoadStatus { idle, loading, ready, error }

/// Which filter chip is selected on the Records screen.
enum FilterPreset { all, today, week, day, range }

/// App-wide state for health records (the list, its filter and sort) and the
/// single entry point for every record write.
///
/// [revision] goes up after each successful write; the dashboard listens to it
/// to know when its totals are stale.
class RecordsViewModel extends SafeChangeNotifier {
  RecordsViewModel(this._repository, {this._today = todayIso});

  final HealthRecordRepository _repository;
  final String Function() _today;

  List<HealthRecord> _records = const [];
  DateFilter _filter = const AllDates();
  SortOrder _sort = SortOrder.newest;
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  int _revision = 0;
  HealthRecord? _lastDeleted;

  List<HealthRecord> get records => _records;
  DateFilter get filter => _filter;
  SortOrder get sort => _sort;
  LoadStatus get status => _status;
  bool get loading => _status == LoadStatus.loading;
  String? get error => _error;
  int get revision => _revision;
  String get today => _today();

  // ---- Reading -------------------------------------------------------------

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _records = await _repository.findAll(filter: _filter, sort: _sort);
      _status = LoadStatus.ready;
    } catch (e) {
      _status = LoadStatus.error;
      _error = errorMessage(e);
    }
    notifyListeners();
  }

  Future<void> setFilter(DateFilter filter) async {
    _filter = filter;
    await load();
  }

  Future<void> setSort(SortOrder sort) async {
    _sort = sort;
    await load();
  }

  Future<HealthRecord?> getById(int id) => _repository.findById(id);

  // ---- Writing -------------------------------------------------------------

  /// Runs a write, then bumps the revision and reloads the list.
  /// Errors propagate to the caller, which shows them to the user.
  Future<T> _write<T>(Future<T> Function(HealthRecordRepository repo) operation) async {
    final result = await operation(_repository);
    _revision++;
    await load();
    return result;
  }

  Future<HealthRecord> create(HealthRecordInput input) => _write((r) => r.create(input));

  Future<HealthRecord> update(int id, HealthRecordInput input) => _write((r) => r.update(id, input));

  Future<void> remove(HealthRecord record) => _write((r) => r.remove(record.id));

  Future<void> restore(HealthRecord record) => _write((r) => r.restore(record));

  Future<HealthRecord> addWater(String date, int ml) => _write((r) => r.addWater(date, ml));

  Future<void> removeAll() => _write((r) => r.removeAll());

  Future<void> replaceWithSampleData(String today) => _write((r) => r.replaceWithSampleData(today));

  // ---- Records screen helpers ---------------------------------------------

  FilterPreset get activePreset {
    final today = _today();
    return switch (_filter) {
      AllDates() => FilterPreset.all,
      SingleDay(:final date) => date == today ? FilterPreset.today : FilterPreset.day,
      DateSpan(:final from, :final to) =>
        from == addDays(today, -6) && to == today ? FilterPreset.week : FilterPreset.range,
    };
  }

  /// Human description of the active filter, e.g. "Showing Sun, 1 Nov 2026 – Sat, 7 Nov 2026".
  String get filterLabel => switch (_filter) {
    AllDates() => 'Showing all records',
    SingleDay(:final date) => 'Showing ${formatShortDate(date)}',
    DateSpan(:final from, :final to) => 'Showing ${formatShortDate(from)} – ${formatShortDate(to)}',
  };

  bool get isFiltered => _filter is! AllDates;

  Future<void> showAll() => setFilter(const AllDates());
  Future<void> showToday() => setFilter(SingleDay(_today()));
  Future<void> showLastWeek() {
    final today = _today();
    return setFilter(DateSpan(addDays(today, -6), today));
  }

  Future<void> showDay(String date) => setFilter(SingleDay(date));
  Future<void> showRange(String from, String to) => setFilter(DateSpan(from, to));
  Future<void> toggleSort() => setSort(_sort == SortOrder.newest ? SortOrder.oldest : SortOrder.newest);

  // ---- Delete with undo ---------------------------------------------------

  bool get canUndo => _lastDeleted != null;

  /// Deletes [record] and remembers it for [undoDelete]. Returns the SnackBar text.
  Future<String> deleteWithUndo(HealthRecord record) async {
    try {
      await remove(record);
      _lastDeleted = record;
      return 'Record for ${formatShortDate(record.date)} deleted';
    } catch (e) {
      _lastDeleted = null;
      return errorMessage(e);
    }
  }

  /// Puts the last deleted record back with its original id.
  /// Returns an error message, or null on success.
  Future<String?> undoDelete() async {
    final record = _lastDeleted;
    _lastDeleted = null;
    if (record == null) return null;
    try {
      await restore(record);
      return null;
    } catch (e) {
      return errorMessage(e);
    }
  }

  void clearUndo() => _lastDeleted = null;
}
