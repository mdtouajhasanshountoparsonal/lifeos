import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lifeos/theme/app_theme.dart';

/// Glassmorphism card with soft blur + translucent fill + subtle border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final double blur;
  final Color? accent;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.onTap,
    this.blur = 0,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final fillColor = c.isLight
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.055);
    final borderColor =
        accent ?? (c.isLight ? Colors.white : c.textSecondary.withValues(alpha: 0.25));

    final fill = Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            fillColor,
            c.isLight
                ? Colors.white.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.025),
          ],
        ),
        border: Border.all(color: borderColor.withValues(alpha: 0.28)),
      ),
      padding: padding,
      child: child,
    );

    // blur <= 0 → BackdropFilter-ই বাদ (GPU-তে blur সবচেয়ে ব্যয়বহুল)।
    final card = ClipRRect(
      borderRadius: borderRadius,
      child: blur > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: fill,
            )
          : fill,
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}