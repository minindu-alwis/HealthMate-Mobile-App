import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/records/model/health_record.dart';

/// Brand palette (Material 3, teal primary).
abstract final class AppColors {
  static const primary = Color(0xFF00796B);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFB2DFDB);
  static const onPrimaryContainer = Color(0xFF00201C);
  static const secondary = Color(0xFF4A635F);
  static const secondaryContainer = Color(0xFFCCE8E2);
  static const background = Color(0xFFF4F7F6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFE0F2F1);
  static const onSurface = Color(0xFF1B1F1E);
  static const onSurfaceVariant = Color(0xFF5F6B68);
  static const outline = Color(0xFFC9D4D1);
  static const outlineVariant = Color(0xFFE3EAE8);
  static const error = Color(0xFFB3261E);
  static const errorContainer = Color(0xFFFDECEA);
  static const shadow = Color(0xFF0B3B36);

  /// Dashboard hero gradient (dark → light teal).
  static const heroGradient = [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)];
}

/// Shared card look: white, 20 radius, soft shadow instead of borders.
const double cardRadius = 20;

const List<BoxShadow> softShadow = [BoxShadow(color: Color(0x140B3B36), blurRadius: 12, offset: Offset(0, 4))];

BoxDecoration cardDecoration({Color color = AppColors.surface}) =>
    BoxDecoration(color: color, borderRadius: BorderRadius.circular(cardRadius), boxShadow: softShadow);

/// Colour coding is consistent on every screen so users learn it once:
/// steps = green (movement), calories = red (energy/heat), water = blue.
class MetricStyle {
  const MetricStyle({
    required this.label,
    required this.shortLabel,
    required this.unit,
    required this.icon,
    required this.color,
    required this.container,
  });

  final String label;
  final String shortLabel;
  final String unit;
  final IconData icon;
  final Color color;
  final Color container;
}

const Map<MetricKey, MetricStyle> metricStyles = {
  MetricKey.steps: MetricStyle(
    label: 'Steps',
    shortLabel: 'Steps',
    unit: 'steps',
    icon: Icons.directions_walk,
    color: Color(0xFF2E7D32),
    container: Color(0xFFE8F5E9),
  ),
  MetricKey.calories: MetricStyle(
    label: 'Calories burned',
    shortLabel: 'Calories',
    unit: 'kcal',
    icon: Icons.local_fire_department,
    color: Color(0xFFD32F2F),
    container: Color(0xFFFDECEA),
  ),
  MetricKey.water: MetricStyle(
    label: 'Water intake',
    shortLabel: 'Water',
    unit: 'ml',
    icon: Icons.water_drop,
    color: Color(0xFF1976D2),
    container: Color(0xFFE3F2FD),
  ),
};

/// Status-bar styles: dark icons on light screens, light icons over the teal hero.
const SystemUiOverlayStyle darkStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: AppColors.surface,
  systemNavigationBarIconBrightness: Brightness.dark,
);

const SystemUiOverlayStyle lightStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: AppColors.surface,
  systemNavigationBarIconBrightness: Brightness.dark,
);

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: Color(0xFF06201C),
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: Color(0xFF410E0B),
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    surfaceContainerHigh: Color(0xFFF0F7F5),
    surfaceContainer: Color(0xFFF4F9F8),
    surfaceContainerLow: AppColors.surface,
    surfaceContainerLowest: AppColors.surface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    inversePrimary: Color(0xFF80CBC4),
    shadow: AppColors.shadow,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final text = base.textTheme.apply(bodyColor: AppColors.onSurface, displayColor: AppColors.onSurface);

  final outlined = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.outline),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: darkStatusBar,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: outlined,
      enabledBorder: outlined,
      focusedBorder: outlined.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: outlined.copyWith(borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: outlined.copyWith(borderSide: const BorderSide(color: AppColors.error, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(64, 48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(64, 48))),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primaryContainer,
      elevation: 12,
      shadowColor: AppColors.shadow,
      height: 74,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      side: const BorderSide(color: AppColors.outline),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primaryContainer,
      checkmarkColor: AppColors.onPrimaryContainer,
      labelStyle: text.labelLarge?.copyWith(color: AppColors.onSurface),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface, surfaceTintColor: Colors.transparent),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerTheme: const DividerThemeData(color: AppColors.outlineVariant, space: 1, thickness: 1),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
