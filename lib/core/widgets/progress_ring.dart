import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Circular progress (activity-ring style) with optional centred content.
/// Drawn with [CustomPaint], so no chart package is needed.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.percent,
    required this.size,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
    this.child,
  });

  /// 0..100
  final num percent;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: (percent.clamp(0, 100)) / 100,
          strokeWidth: strokeWidth,
          color: color,
          trackColor: trackColor,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fraction, required this.strokeWidth, required this.color, required this.trackColor});

  final double fraction;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    if (fraction <= 0) return;
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    // Starts at 12 o'clock and runs clockwise.
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false, progress);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.trackColor != trackColor || old.strokeWidth != strokeWidth;
}
