import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Friendly placeholder for empty lists and missing records.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.description, this.action});

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            description,
            style: text.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
