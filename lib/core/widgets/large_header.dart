import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Material 3 "large top app bar" style header used by the tab screens.
class LargeHeader extends StatelessWidget {
  const LargeHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          Text(subtitle, style: text.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
