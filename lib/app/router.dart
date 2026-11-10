import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/records/view/record_form_screen.dart';
import '../features/records/viewmodel/record_form_view_model.dart';
import '../features/records/viewmodel/records_view_model.dart';
import 'home_shell.dart';

/// Named routes. The tabs live inside [HomeShell]; the form is pushed on top.
abstract final class AppRoutes {
  static const home = '/';
  static const newRecord = '/record/new';

  /// Expects the record id (int) as the route argument.
  static const editRecord = '/record/edit';
}

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.newRecord:
      return MaterialPageRoute<String>(settings: settings, fullscreenDialog: true, builder: (_) => _formRoute(null));
    case AppRoutes.editRecord:
      // A malformed argument (e.g. from a deep link) shows "Record not found" via id -1.
      final args = settings.arguments;
      final id = args is int && args > 0 ? args : -1;
      return MaterialPageRoute<String>(settings: settings, builder: (_) => _formRoute(id));
    case AppRoutes.home:
    default:
      return MaterialPageRoute<void>(settings: settings, builder: (_) => const HomeShell());
  }
}

/// Opens the add form (no [recordId]) or the edit form, and shows the form's
/// result ("Record added" / "Changes saved") in the caller's own SnackBar area,
/// so it is laid out by that tab's Scaffold and does not cover its FAB.
Future<void> openRecordForm(BuildContext context, {int? recordId}) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = recordId == null
      ? await Navigator.of(context).pushNamed<String>(AppRoutes.newRecord)
      : await Navigator.of(context).pushNamed<String>(AppRoutes.editRecord, arguments: recordId);
  if (message != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(milliseconds: 2500)));
  }
}

/// Each form gets its own short-lived view-model, disposed when the route pops.
Widget _formRoute(int? recordId) => ChangeNotifierProvider(
  create: (context) => RecordFormViewModel(context.read<RecordsViewModel>(), recordId: recordId)..init(),
  child: const RecordFormScreen(),
);
