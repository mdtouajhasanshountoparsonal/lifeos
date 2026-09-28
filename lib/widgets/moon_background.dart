import 'package:flutter/material.dart';
import 'package:lifeos/theme/app_theme.dart';

/// Static, subtle চাঁদ-আলো background — DEEN screen-এর পেছনে।
/// কোনো animation নেই (smoothness অক্ষুণ্ণ)।
class MoonBackground extends StatelessWidget {
  const MoonBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _MoonPainter(glow: c.glow, light: c.isLight),
          ),
        ),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  final Color glow;
  final bool light;

  _MoonPainter({required this.glow, required this.light});

  @override
  void paint(Canvas canvas, Size size) {
    // নরম আলো — উপরের ডানে
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [
          glow.withValues(alpha: light ? 0.10 : 0.16),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.82, size.height * 0.16),
        radius: size.width * 0.5,
      ));
    canvas.drawRect(Offset.zero & size, halo);

    // চাঁদ (শুধু আলোকরশ্মি প্রতিফলন — সরল বৃত্ত)
    final center = Offset(size.width * 0.82, size.height * 0.16);
    final r = size.width * 0.055;
    canvas.drawCircle(
      center,
      r * 2.1,
      Paint()
        ..color = glow.withValues(alpha: light ? 0.05 : 0.09),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = glow.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      center,
      r * 0.78,
      Paint()..color = Color.lerp(glow, Colors.white, 0.6)!.withValues(alpha: light ? 0.75 : 0.9),
    );

    // কয়েকটা স্থির তারা (fixed seed, কোনো randomness প্রতি build-এ নেই)
    const stars = <List<double>>[
      // [xRatio, yRatio, r, alpha]
      [0.10, 0.14, 1.4, 0.16],
      [0.22, 0.30, 1.0, 0.11],
      [0.34, 0.10, 1.2, 0.13],
      [0.55, 0.22, 1.1, 0.10],
      [0.07, 0.42, 1.0, 0.09],
      [0.42, 0.48, 1.3, 0.12],
      [0.68, 0.38, 1.0, 0.09],
      [0.16, 0.58, 1.1, 0.08],
      [0.50, 0.65, 1.0, 0.07],
      [0.85, 0.55, 1.2, 0.09],
      [0.30, 0.72, 1.0, 0.07],
      [0.62, 0.80, 1.1, 0.06],
      [0.05, 0.78, 1.0, 0.06],
    ];
    final star = Paint()..color = Colors.white;
    for (final s in stars) {
      star.color = Colors.white.withValues(alpha: s[3]);
      canvas.drawCircle(
        Offset(size.width * s[0], size.height * s[1]),
        s[2],
        star,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MoonPainter old) =>
      old.glow != glow || old.light != light;
}