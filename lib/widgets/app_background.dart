import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lifeos/theme/app_theme.dart';

/// Animated gradient background behind every screen.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    // ফিশ অ্যানিমেশন ব্যয়বহুল (পুরো screen প্রতি ফ্রেম repaint) — smoothness-এর
    // জন্য default বন্ধ; Settings-এ 'show_fish' true করলে ফের চালু হয়।
    final showFish =
        Hive.box('settings').get('show_fish', defaultValue: false) as bool;
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.gradientTop, c.gradientBottom],
            ),
          ),
        ),
        // Soft glow orb top-right, adds depth without heavy perf cost.
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  c.glow.withValues(alpha: 0.18),
                  c.glow.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Swimming fish layer — off by default; every page-এর পেছনে constant
        // repaint এড়াতে বন্ধ রাখা হয়।
        if (showFish)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: FishLayer(color: c.glow),
              ),
            ),
          ),
        // Soft vignette so edges feel deep like under-water.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.4,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: c.isLight ? 0.04 : 0.10),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Material ancestor so pushed screens (which build only on
        // AppBackground) work with InkWell/buttons (no Scaffold of their own).
        Material(
          type: MaterialType.transparency,
          child: child,
        ),
      ],
    );
  }
}

/// Lightweight animated swarm of fish swimming slowly across the background.
class FishLayer extends StatefulWidget {
  final Color color;
  const FishLayer({super.key, required this.color});

  @override
  State<FishLayer> createState() => _FishLayerState();
}

class _FishLayerState extends State<FishLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 70),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _FishPainter(
          progress: _ctrl.value,
          color: widget.color,
        ),
      ),
    );
  }
}

class _FishPainter extends CustomPainter {
  final double progress;
  final Color color;

  _FishPainter({required this.progress, required this.color});

  static const _fishDefs = <List<double>>[
    // [speed, laneY(0..1), sizeFactor(0..1), bobAmp, wrapOffset(0..1), right]
    [0.35, 0.16, 0.70, 18, 0.10, 1],
    [0.55, 0.24, 0.50, 12, 0.55, 0],
    [0.28, 0.42, 0.95, 22, 0.30, 1],
    [0.70, 0.55, 0.55, 14, 0.80, 0],
    [0.42, 0.68, 0.80, 20, 0.20, 1],
    [0.24, 0.82, 0.45, 10, 0.65, 0],
    [0.60, 0.90, 0.62, 16, 0.40, 1],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 20 || size.height <= 20) return;
    final base = size.width * 0.028;
    for (final d in _fishDefs) {
      final speed = d[0];
      final sf = d[2];
      final bob = d[3];
      final offset = d[4];
      final right = d[5] == 1;
      final len = base * (1.6 + sf * 1.6);
      final tPix = size.width + len * 2;
      final x = -len + tPix * _wrap(progress * speed + offset);
      final y = size.height * d[1] +
          math.sin((progress * speed + offset) * math.pi * 2 * 6) * bob;
      final alpha = 0.05 + 0.05 * math.sin((progress * 2 + offset * 9) * math.pi);
      _drawFish(canvas, x, y, base * (0.6 + sf * 0.9), right, alpha);
    }
  }

  double _wrap(double v) => v - v.floorToDouble();

  void _drawFish(Canvas canvas, double x, double y, double s, bool right, double alpha) {
    if (s <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: alpha.clamp(0.02, 0.14))
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(right ? 1 : -1, 1);
    // tail
    final tail = Path()
      ..moveTo(-s * 0.9, 0)
      ..lineTo(-s * 1.7, -s * 0.55)
      ..lineTo(-s * 1.7, s * 0.55)
      ..close();
    canvas.drawPath(tail, paint);
    // body
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 0), width: s * 2.1, height: s * 1.05),
      paint,
    );
    // eye
    canvas.drawCircle(
      Offset(s * 0.62, -s * 0.14),
      math.max(0.6, s * 0.10),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FishPainter old) =>
      old.progress != progress || old.color != color;
}