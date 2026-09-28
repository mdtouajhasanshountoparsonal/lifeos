import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lifeos/theme/app_theme.dart';

/// Ocean background (P7) — তরঙ্গ + মাছ + বুদবুদ animation, glass card-এর পেছনে।
/// AppBackground-এর গ্র্যাডিয়েন্ট + orb রেখে উপরে জলজ স্তর আঁকে।
class OceanBackground extends StatefulWidget {
  final Widget child;

  /// তীব্রতা — ছোট = subtle, বড় = বেশি মাছ/বুদবুদ।
  final double intensity;

  const OceanBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
  });

  @override
  State<OceanBackground> createState() => _OceanBackgroundState();
}

class _OceanBackgroundState extends State<OceanBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Stack(
      children: [
        // গ্র্যাডিয়েন্ট + orb — AppBackground-এর সাথে consistent
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
        // জলজ স্তর
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) => CustomPaint(
                painter: _OceanPainter(
                  anim: _anim.value,
                  tint: c.primary,
                  tint2: c.secondary,
                  glow: c.glow,
                  light: c.isLight,
                  intensity: widget.intensity,
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _OceanPainter extends CustomPainter {
  final double anim;
  final Color tint;
  final Color tint2;
  final Color glow;
  final bool light;
  final double intensity;

  _OceanPainter({
    required this.anim,
    required this.tint,
    required this.tint2,
    required this.glow,
    required this.light,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final waveColor = light
        ? tint.withValues(alpha: 0.10)
        : tint.withValues(alpha: 0.14);
    final waveColor2 = light
        ? tint2.withValues(alpha: 0.08)
        : tint2.withValues(alpha: 0.12);
    final fishColor = light
        ? glow.withValues(alpha: 0.35)
        : glow.withValues(alpha: 0.30);

    _paintWave(canvas, size, anim, waveColor,
        baseHeight: size.height * 0.30, amp: 10, freq: 1.6, phase: 0.0);
    _paintWave(canvas, size, anim, waveColor2,
        baseHeight: size.height * 0.38, amp: 14, freq: 2.4, phase: 0.5);

    // fish
    final count = light ? 2 : 4;
    final speed = _speed * (light ? 0.8 : 1.0);
    for (var i = 0; i < count; i++) {
      final seed = i + 1;
      _paintFish(
        canvas,
        size,
        seed: seed,
        anim: anim,
        color: fishColor,
        speed: speed * (0.8 + (seed % 3) * 0.2),
        reach: size.width * (0.20 + (seed % 4) * 0.04),
      );
    }

    // bubbles
    final n = light ? 6 : 10;
    for (var i = 0; i < n; i++) {
      _paintBubble(canvas, size, seed: i + 7,
          anim: anim, color: waveColor2, speed: _speed * 0.5);
    }
  }

  static const double _speed = 0.05; // fraction of full width per tick

  void _paintWave(
      Canvas canvas, Size size, double anim, Color color,
      {required double baseHeight,
      required double amp,
      required double freq,
      required double phase}) {
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 4) {
      final y = baseHeight +
          math.sin(x / size.width * math.pi * freq + anim * math.pi * 2 + phase) *
              amp;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _paintFish(Canvas canvas, Size size,
      {required int seed,
      required double anim,
      required Color color,
      required double speed,
      required double reach}) {
    final centerX = size.width * (0.16 + (seed % 5) * 0.16);
    final centerY = size.height * (0.10 + (seed % 6) * 0.09) +
        math.sin(anim * math.pi * 2 * (0.7 + (seed % 3) * 0.2)) * 8;
    final a = anim * math.pi * 2 * seed * 0.33;
    final x = centerX + math.sin(a) * reach;
    final heading = math.cos(a) * speed;
    final scale = 0.7 + (seed % 3) * 0.18;

    canvas.save();
    canvas.translate(x, centerY);
    if (heading < 0) {
      canvas.scale(-1, 1);
    }
    canvas.scale(scale * intensity, scale * intensity);
    final body = Paint()..color = color;
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(0, 0), width: 24, height: 12),
        body);
    final tail = Path()
      ..moveTo(-10, 0)
      ..lineTo(-17, -6)
      ..lineTo(-17, 6)
      ..close();
    canvas.drawPath(tail, body);
    canvas.drawCircle(
        const Offset(6, -2.5),
        1.6,
        Paint()
          ..color =
              (light ? Colors.white : const Color(0xFF061018))
                  .withValues(alpha: 0.9));
    canvas.restore();
  }

  void _paintBubble(Canvas canvas, Size size,
      {required int seed, required double anim, required Color color, required double speed}) {
    final x = size.width * ((seed * 0.13) % 1.0 + 0.03);
    final loop = (anim * speed + seed * 0.37) % 1.0;
    final y = size.height * (0.04 + (1 - loop) * 0.9);
    final r = 1.5 + (seed % 3) * 1.2;
    canvas.drawCircle(Offset(x, y), r, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_OceanPainter old) {
    return old.anim != anim ||
        old.tint != tint ||
        old.tint2 != tint2 ||
        old.glow != glow ||
        old.light != light ||
        old.intensity != intensity;
  }
}