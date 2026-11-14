import '../../../core/viewmodel/safe_change_notifier.dart';
import '../data/goals_repository.dart';
import '../model/goals.dart';

/// App-wide daily goals, read by the dashboard and edited on Settings.
class GoalsViewModel extends SafeChangeNotifier {
  GoalsViewModel(this._repository);

  final GoalsRepository _repository;

  DailyGoals _goals = DailyGoals.defaults;

  DailyGoals get goals => _goals;

  Future<void> load() async {
    _goals = await _repository.getGoals();
    notifyListeners();
  }

  Future<void> save(DailyGoals goals) async {
    await _repository.saveGoals(goals);
    _goals = goals;
    notifyListeners();
  }
}
