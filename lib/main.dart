import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/viewmodel/settings_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the status and navigation bars; each screen sets its own icon colour.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(darkStatusBar);
  runApp(const HealthMateRoot());
}

/// Opens the database first, then provides the view-models to the whole app.
class HealthMateRoot extends StatefulWidget {
  const HealthMateRoot({super.key});

  @override
  State<HealthMateRoot> createState() => _HealthMateRootState();
}

class _HealthMateRootState extends State<HealthMateRoot> {
  Future<AppServices> _startup = AppServices.start();

  void _retry() => setState(() => _startup = AppServices.start());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppServices>(
      future: _startup,
      builder: (context, snapshot) {
        final services = snapshot.data;
        if (services == null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            locale: appLocale,
            supportedLocales: const [appLocale],
            localizationsDelegates: appLocalizationsDelegates,
            home: StartupScreen(error: snapshot.error, onRetry: _retry),
          );
        }
        return MultiProvider(
          providers: [
            // Shared, app-lifetime view-models created by the bootstrap.
            ChangeNotifierProvider.value(value: services.records),
            ChangeNotifierProvider.value(value: services.goals),
            ChangeNotifierProvider.value(value: services.dashboard),
            // Settings form state, created the first time the tab is opened.
            ChangeNotifierProvider(create: (_) => SettingsViewModel(services.goals, services.records)),
          ],
          child: const HealthMateApp(),
        );
      },
    );
  }
}
