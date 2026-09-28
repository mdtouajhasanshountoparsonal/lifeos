import 'package:flutter/material.dart';

/// Staggered entrance — fades + slides up. Use [order] to stagger list items.
class EntranceItem extends StatelessWidget {
  final int order;
  final Widget child;
  final Duration base;

  const EntranceItem({
    super.key,
    required this.order,
    required this.child,
    this.base = const Duration(milliseconds: 420),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: base + Duration(milliseconds: order * 70),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

/// PageRouteBuilder that fades + slides up — fluid screen changes.
class FadeRoute<T> extends PageRouteBuilder<T> {
  FadeRoute(this.page)
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (context, animation, secondary) => page,
          transitionsBuilder: (context, animation, secondary, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.02), end: Offset.zero)
                    .animate(curved),
                child: child,
              ),
            );
          },
        );

  final Widget page;
}