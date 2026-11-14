import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Looks like an outlined text field but is one button that opens the date
/// picker, so users can only pick a real, non-future date, never type a malformed one.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.label, required this.value, required this.onTap, this.errorText});

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value. Double tap to change',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: errorText,
            prefixIcon: const Icon(Icons.calendar_today, color: AppColors.onSurfaceVariant),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.onSurfaceVariant),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.onSurfaceVariant),
            ),
          ),
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );
  }
}
