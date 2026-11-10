import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

/// British English: day-first dates and Monday-first calendars in the date pickers.
const Locale appLocale = Locale('en', 'GB');
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = GlobalMaterialLocalizations.delegates;

/// The ready app: theme and routes. Providers are set up above it in `main.dart`.
class HealthMateApp extends StatelessWidget {
  const HealthMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthMate',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: appLocale,
      supportedLocales: const [appLocale],
      localizationsDelegates: appLocalizationsDelegates,
      initialRoute: AppRoutes.home,
      onGenerateRoute: onGenerateRoute,
    );
  }
}

/// Shown while the database opens, or with a retry button if it fails.
class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key, this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: error == null
                  ? [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      const Text('Opening your health records…', textAlign: TextAlign.center),
                    ]
                  : [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(
                        'HealthMate could not open its database',
                        style: text.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text('$error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: onRetry, child: const Text('Try again')),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
