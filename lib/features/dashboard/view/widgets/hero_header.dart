import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/progress_ring.dart';

/// Gradient header: greeting, today's date and an overall "daily score" ring.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.greeting,
    required this.dateLabel,
    required this.score,
    required this.goalsMet,
    required this.goalCount,
  });

  final String greeting;
  final String dateLabel;
  final int score;
  final int goalsMet;
  final int goalCount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;
    const faded = Color(0xD9FFFFFF);

    return Container(
      padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 64),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: AppColors.heroGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: text.titleSmall?.copyWith(color: faded)),
                Semantics(
                  header: true,
                  child: Text(
                    'Today',
                    style: text.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 2),
                Text(dateLabel, style: text.bodyMedium?.copyWith(color: const Color(0xCCFFFFFF))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0x2EFFFFFF), borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    '$goalsMet of $goalCount goals reached',
                    style: text.labelLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Semantics(
            label: 'Daily score $score percent',
            excludeSemantics: true,
            child: ProgressRing(
              percent: score,
              size: 112,
              strokeWidth: 10,
              color: Colors.white,
              trackColor: const Color(0x40FFFFFF),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score%',
                    style: text.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  Text('daily score', style: text.labelSmall?.copyWith(color: faded)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
