import 'package:flutter/foundation.dart';

/// A [ChangeNotifier] that ignores [notifyListeners] after [dispose].
///
/// View-models await database calls; if the user leaves the screen while one
/// is running, the late notify would otherwise throw.
class SafeChangeNotifier extends ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
