import 'package:flutter/material.dart';

/// স্থিতিশীল প্রগতি-রিং (অ্যানিমেশন ছাড়া) — যিকির/তাসবিহ কাউন্টারের জন্য।
class CountRing extends StatelessWidget {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final Widget? child;

  const CountRing({
    super.key,
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 10,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CountRingPainter(
        progress: progress,
        color: color,
        trackColor: trackColor,
        strokeWidth: strokeWidth,
      ),
      child: child ?? const SizedBox.expand(),
    );
  }
}

class _CountRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _CountRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - strokeWidth / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);
    if (progress > 0) {
      final prog = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -1.5707963267948966,
        6.283185307179586 * progress.clamp(0, 1),
        false,
        prog,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CountRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}