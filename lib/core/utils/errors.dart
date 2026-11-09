import 'package:sqflite/sqflite.dart';

/// User-facing text for any thrown value. Used by every view-model's catch block.
String errorMessage(Object error) {
  if (error is DatabaseException) {
    return 'The database could not complete that action. Please try again.';
  }
  if (error is AppException) return error.message;
  return 'Something went wrong. Please try again.';
}

/// Base class for errors whose message is safe to show to the user.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
